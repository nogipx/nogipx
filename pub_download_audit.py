#!/usr/bin/env python3
import argparse
import csv
import gzip
import json
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
UA = "pub-dev-download-audit/1.1 (+research task; contact: local-script)"
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
            if e.code in (429, 500, 502, 503, 504):
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
            if e.code in (429, 500, 502, 503, 504):
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
    ap.add_argument("--limit", type=int, default=0, help="Optional limit for development/testing runs")
    ap.add_argument(
        "--collect-latest",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Collect full latest version metadata from /api/packages/<name>",
    )
    ap.add_argument(
        "--collect-score-tags",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Collect score tags from /api/packages/<name>/score and include them in latest metadata",
    )
    args = ap.parse_args()

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    progress_path = out_dir / "progress.jsonl"
    latest_versions_path = out_dir / "latest_versions.jsonl"
    csv_path = out_dir / "package_downloads.csv"
    full_csv_path = out_dir / "package_full_data.csv"
    result_path = out_dir / "result.json"
    errors_path = out_dir / "errors.jsonl"
    validation_path = out_dir / "validation_sample.json"

    started = time.time()

    robots = read_robots()
    if "Disallow: /api" in robots:
        raise RuntimeError("robots.txt disallows /api, aborting")

    names_data = fetch_json(f"{BASE}/api/package-names")
    packages: List[str] = names_data.get("packages", [])
    if args.limit > 0:
        packages = packages[: args.limit]
    total = len(packages)

    done = load_progress(progress_path)
    latest_done = load_progress(latest_versions_path) if args.collect_latest else {}

    def needs_update(pkg: str) -> bool:
        if pkg not in done:
            return True
        if args.collect_latest and pkg not in latest_done:
            return True
        return False

    remaining = [p for p in packages if needs_update(p)]

    lock = threading.Lock()
    latest_lock = threading.Lock()
    err_lock = threading.Lock()
    completed = total - len(remaining)
    next_progress_bucket = int((completed / total) * 10) + 1 if total else 11

    def worker(pkg: str):
        metric_row = None
        latest_row = None

        if pkg not in done:
            metrics_url = f"{BASE}/api/packages/{quote(pkg)}/metrics"
            metrics_data = fetch_json(metrics_url)
            value = normalize_count(metrics_data["score"].get("downloadCount30Days"))
            metric_row = {
                "package_name": pkg,
                "total_downloads": value,
                "category": category(value),
            }

        if args.collect_latest and pkg not in latest_done:
            package_url = f"{BASE}/api/packages/{quote(pkg)}"
            package_data = fetch_json(package_url)
            latest = package_data.get("latest", {})
            pubspec = latest.get("pubspec", {})

            score_data = {}
            if args.collect_score_tags:
                score_url = f"{BASE}/api/packages/{quote(pkg)}/score"
                score_data = fetch_json(score_url)

            repository_url = pubspec.get("repository") or pubspec.get("homepage")
            pub_dev_url = f"{BASE}/packages/{quote(pkg)}"

            latest_row = {
                "package_name": pkg,
                "fetched_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                "latest_version": latest.get("version"),
                "latest_published": latest.get("published"),
                "description": pubspec.get("description"),
                "tags": score_data.get("tags", pubspec.get("topics", [])),
                "topics": pubspec.get("topics", []),
                "repository_url": repository_url,
                "homepage_url": pubspec.get("homepage"),
                "issue_tracker_url": pubspec.get("issue_tracker"),
                "pub_dev_url": pub_dev_url,
                "score": {
                    "like_count": score_data.get("likeCount") if score_data else None,
                    "granted_points": score_data.get("grantedPoints") if score_data else None,
                    "max_points": score_data.get("maxPoints") if score_data else None,
                    "download_count_30_days": score_data.get("downloadCount30Days") if score_data else None,
                },
                "score_raw": score_data if score_data else None,
                "package_api_raw": package_data,
                "latest": latest,
            }

        return metric_row, latest_row

    if remaining:
        with ThreadPoolExecutor(max_workers=args.workers) as ex:
            futs = {ex.submit(worker, pkg): pkg for pkg in remaining}
            for fut in as_completed(futs):
                pkg = futs[fut]
                try:
                    metric_row, latest_row = fut.result()
                    if metric_row is not None:
                        done[pkg] = metric_row
                        append_progress(progress_path, metric_row, lock)
                    if latest_row is not None:
                        latest_done[pkg] = latest_row
                        append_progress(latest_versions_path, latest_row, latest_lock)
                except Exception as e:
                    with err_lock:
                        with errors_path.open("a", encoding="utf-8") as ef:
                            ef.write(
                                json.dumps(
                                    {
                                        "package_name": pkg,
                                        "error": str(e),
                                        "stage": "worker",
                                        "collect_latest": args.collect_latest,
                                    },
                                    ensure_ascii=False,
                                )
                                + "\n"
                            )
                completed += 1
                bucket = int((completed / total) * 10) if total else 10
                if bucket >= next_progress_bucket:
                    print(f"Progress: {bucket * 10}% ({completed}/{total})")
                    next_progress_bucket = bucket + 1

    rows = [done[p] for p in packages if p in done]
    with csv_path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["package_name", "total_downloads", "category"])
        for r in rows:
            w.writerow([r["package_name"], r["total_downloads"], r["category"]])

    # Full package data in CSV (text format, including JSON columns for complete payloads)
    if args.collect_latest:
        full_header = [
            "package_name",
            "total_downloads",
            "category",
            "latest_version",
            "latest_published",
            "description",
            "tags_json",
            "topics_json",
            "repository_url",
            "homepage_url",
            "issue_tracker_url",
            "pub_dev_url",
            "score_like_count",
            "score_granted_points",
            "score_max_points",
            "score_download_count_30_days",
            "score_raw_json",
            "latest_json",
            "package_api_raw_json",
        ]
        with full_csv_path.open("w", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            w.writerow(full_header)
            for pkg in packages:
                metric = done.get(pkg, {})
                latest_row = latest_done.get(pkg, {})
                score = latest_row.get("score") or {}
                w.writerow([
                    pkg,
                    metric.get("total_downloads"),
                    metric.get("category"),
                    latest_row.get("latest_version"),
                    latest_row.get("latest_published"),
                    latest_row.get("description"),
                    json.dumps(latest_row.get("tags", []), ensure_ascii=False),
                    json.dumps(latest_row.get("topics", []), ensure_ascii=False),
                    latest_row.get("repository_url"),
                    latest_row.get("homepage_url"),
                    latest_row.get("issue_tracker_url"),
                    latest_row.get("pub_dev_url"),
                    score.get("like_count"),
                    score.get("granted_points"),
                    score.get("max_points"),
                    score.get("download_count_30_days"),
                    json.dumps(latest_row.get("score_raw"), ensure_ascii=False),
                    json.dumps(latest_row.get("latest"), ensure_ascii=False),
                    json.dumps(latest_row.get("package_api_raw"), ensure_ascii=False),
                ])

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
        "collect_latest": args.collect_latest,
        "latest_versions_collected": len([p for p in packages if p in latest_done]) if args.collect_latest else 0,
        "collect_score_tags": args.collect_score_tags,
        "latest_versions_path": str(latest_versions_path) if args.collect_latest else None,
        "full_csv_path": str(full_csv_path) if args.collect_latest else None,
        "errors_logged": sum(1 for _ in errors_path.open("r", encoding="utf-8")) if errors_path.exists() else 0,
        "duration_seconds": round(time.time() - started, 2),
    }
    result_path.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")

    sample_size = min(100, len(rows))
    sample = random.sample(rows, sample_size) if sample_size else []
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
    if args.collect_latest:
        print(f"Full CSV: {full_csv_path}")
    if args.collect_latest:
        print(f"Latest versions JSONL: {latest_versions_path}")
    print(f"Validation sample: {validation_path}")


if __name__ == "__main__":
    main()
