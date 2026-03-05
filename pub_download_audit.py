#!/usr/bin/env python3
import argparse
import csv
import gzip
import json
import math
import random
import re
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from html import unescape
from pathlib import Path
from typing import Dict, List, Optional
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen

BASE = "https://pub.dev"
UA = "pub-dev-download-audit/1.0 (+research task; contact: local-script)"
MAX_RETRIES = 5
TIMEOUT = 15


def read_robots() -> str:
    req = Request(f"{BASE}/robots.txt", headers={"User-Agent": UA, "Accept-Encoding": "gzip"})
    with urlopen(req, timeout=TIMEOUT) as resp:
        data = resp.read()
        if resp.headers.get("Content-Encoding") == "gzip":
            data = gzip.decompress(data)
        return data.decode("utf-8", errors="replace")


def fetch_json(url: str, retries: int = MAX_RETRIES) -> Dict:
    backoff = 1.0
    for attempt in range(1, retries + 1):
        try:
            req = Request(url, headers={"User-Agent": UA, "Accept": "application/json", "Accept-Encoding": "gzip"})
            with urlopen(req, timeout=TIMEOUT) as resp:
                data = resp.read()
                if resp.headers.get("Content-Encoding") == "gzip":
                    data = gzip.decompress(data)
                return json.loads(data.decode("utf-8"))
        except HTTPError as e:
            code = e.code
            if code in (429, 500, 502, 503, 504):
                if attempt == retries:
                    raise
                retry_after = e.headers.get("Retry-After")
                sleep_for = float(retry_after) if retry_after and retry_after.isdigit() else backoff
                time.sleep(sleep_for)
                backoff *= 2
                continue
            raise
        except (URLError, TimeoutError, OSError):
            if attempt == retries:
                raise
            time.sleep(backoff)
            backoff *= 2
    raise RuntimeError("fetch_json retries exhausted")


def fetch_text(url: str, retries: int = MAX_RETRIES) -> str:
    backoff = 1.0
    for attempt in range(1, retries + 1):
        try:
            req = Request(url, headers={"User-Agent": UA, "Accept-Encoding": "gzip"})
            with urlopen(req, timeout=TIMEOUT) as resp:
                data = resp.read()
                if resp.headers.get("Content-Encoding") == "gzip":
                    data = gzip.decompress(data)
                return data.decode("utf-8", errors="replace")
        except HTTPError as e:
            code = e.code
            if code in (429, 500, 502, 503, 504):
                if attempt == retries:
                    raise
                retry_after = e.headers.get("Retry-After")
                sleep_for = float(retry_after) if retry_after and retry_after.isdigit() else backoff
                time.sleep(sleep_for)
                backoff *= 2
                continue
            raise
        except (URLError, TimeoutError, OSError):
            if attempt == retries:
                raise
            time.sleep(backoff)
            backoff *= 2
    raise RuntimeError("fetch_text retries exhausted")


def normalize_count(raw) -> int:
    if raw is None:
        return 0
    if isinstance(raw, int):
        return raw
    s = str(raw).strip().replace(",", "")
    match = re.fullmatch(r"([0-9]*\.?[0-9]+)([kKmMbB]?)", s)
    if not match:
        raise ValueError(f"Unknown number format: {raw}")
    number = float(match.group(1))
    suffix = match.group(2).lower()
    factor = 1
    if suffix == "k":
        factor = 1_000
    elif suffix == "m":
        factor = 1_000_000
    elif suffix == "b":
        factor = 1_000_000_000
    return int(number * factor)


def category(value: int) -> str:
    if value < 1_000:
        return "<1000"
    if value < 1_000_000:
        return "1000–999999"
    return ">=1000000"


def load_progress(progress_path: Path) -> Dict[str, Dict]:
    data: Dict[str, Dict] = {}
    if progress_path.exists():
        with progress_path.open("r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                row = json.loads(line)
                data[row["package_name"]] = row
    return data


def append_progress(progress_path: Path, row: Dict, lock: threading.Lock):
    with lock:
        with progress_path.open("a", encoding="utf-8") as f:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")


def parse_download_from_html(html: str) -> Optional[str]:
    m = re.search(r'packages-score-downloads"[^>]*>.*?packages-score-value-number">([^<]+)<', html)
    if not m:
        return None
    return unescape(m.group(1)).strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--workers", type=int, default=15)
    ap.add_argument("--out-dir", default="pub_audit_output")
    args = ap.parse_args()

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    progress_path = out_dir / "progress.jsonl"
    csv_path = out_dir / "package_downloads.csv"
    result_path = out_dir / "result.json"
    errors_path = out_dir / "errors.jsonl"
    validation_path = out_dir / "validation_sample.json"

    started = time.time()

    robots = read_robots()
    if "Disallow: /api" in robots:
        raise RuntimeError("robots.txt disallows /api, aborting")

    names_data = fetch_json(f"{BASE}/api/package-names")
    packages: List[str] = names_data.get("packages", [])
    total = len(packages)

    done = load_progress(progress_path)
    remaining = [p for p in packages if p not in done]

    lock = threading.Lock()
    err_lock = threading.Lock()
    completed = len(done)
    next_progress_bucket = int((completed / total) * 10) + 1

    def worker(pkg: str):
        url = f"{BASE}/api/packages/{quote(pkg)}/metrics"
        data = fetch_json(url)
        value = normalize_count(data["score"]["downloadCount30Days"])
        return {
            "package_name": pkg,
            "total_downloads": value,
            "category": category(value),
        }

    if remaining:
        with ThreadPoolExecutor(max_workers=args.workers) as ex:
            futs = {ex.submit(worker, pkg): pkg for pkg in remaining}
            for fut in as_completed(futs):
                pkg = futs[fut]
                try:
                    row = fut.result()
                    done[pkg] = row
                    append_progress(progress_path, row, lock)
                except Exception as e:
                    with err_lock:
                        with errors_path.open("a", encoding="utf-8") as ef:
                            ef.write(json.dumps({"package_name": pkg, "error": str(e)}, ensure_ascii=False) + "\n")
                completed += 1
                bucket = int((completed / total) * 10)
                if bucket >= next_progress_bucket:
                    print(f"Progress: {bucket * 10}% ({completed}/{total})")
                    next_progress_bucket = bucket + 1

    rows = [done[p] for p in packages if p in done]
    with csv_path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["package_name", "total_downloads", "category"])
        for r in rows:
            w.writerow([r["package_name"], r["total_downloads"], r["category"]])

    total_packages = len(rows)
    c1 = sum(1 for r in rows if r["category"] == "<1000")
    c2 = sum(1 for r in rows if r["category"] == "1000–999999")
    c3 = sum(1 for r in rows if r["category"] == ">=1000000")

    def pct(x: int) -> float:
        return round((x / total_packages * 100.0) if total_packages else 0.0, 6)

    result = {
        "total_packages": total_packages,
        "below_1000": {"count": c1, "percent": pct(c1)},
        "1000_to_1M_minus1": {"count": c2, "percent": pct(c2)},
        "at_least_1M": {"count": c3, "percent": pct(c3)},
        "note": "pub.dev public API exposes downloadCount30Days; used as total_downloads proxy because all-time total is not available via public endpoint.",
        "errors_logged": sum(1 for _ in errors_path.open("r", encoding="utf-8")) if errors_path.exists() else 0,
        "duration_seconds": round(time.time() - started, 2),
    }
    result_path.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")

    sample_size = min(100, len(rows))
    sample = random.sample(rows, sample_size)
    validation = []
    for row in sample:
        pkg = row["package_name"]
        html = fetch_text(f"{BASE}/packages/{quote(pkg)}")
        page_value = parse_download_from_html(html)
        validation.append(
            {
                "package_name": pkg,
                "api_downloads_30d": row["total_downloads"],
                "page_downloads_display": page_value,
            }
        )
    validation_path.write_text(json.dumps(validation, ensure_ascii=False, indent=2), encoding="utf-8")

    print(json.dumps(result, ensure_ascii=False, indent=2))
    print(f"CSV: {csv_path}")
    print(f"Validation sample: {validation_path}")


if __name__ == "__main__":
    main()
