#!/usr/bin/env python3
import argparse
import csv
import json
import math
from collections import Counter
from pathlib import Path

import matplotlib.pyplot as plt


def category(v: int) -> str:
    if v < 1_000:
        return '<1000'
    if v < 1_000_000:
        return '1000–999999'
    return '>=1000000'


def read_downloads(csv_path: Path):
    values = []
    with csv_path.open('r', encoding='utf-8', newline='') as f:
        r = csv.DictReader(f)
        for row in r:
            values.append(int(row['total_downloads']))
    return values


def make_plots(values, out_dir: Path):
    out_dir.mkdir(parents=True, exist_ok=True)

    # Plot 1: categories requested in original task
    counts = Counter(category(v) for v in values)
    ordered = ['<1000', '1000–999999', '>=1000000']
    xs = ordered
    ys = [counts[x] for x in ordered]

    fig, ax = plt.subplots(figsize=(8, 5))
    bars = ax.bar(xs, ys, color=['#90caf9', '#64b5f6', '#1976d2'])
    ax.set_title('Распределение пакетов pub.dev по месячным скачиваниям')
    ax.set_xlabel('Диапазон скачиваний в месяц')
    ax.set_ylabel('Количество пакетов')
    for b in bars:
        h = int(b.get_height())
        ax.annotate(f'{h:,}'.replace(',', ' '), (b.get_x() + b.get_width() / 2, h),
                    ha='center', va='bottom', fontsize=10, xytext=(0, 3), textcoords='offset points')
    fig.tight_layout()
    fig.savefig(out_dir / 'downloads_category_distribution.png', dpi=160)
    plt.close(fig)

    # Plot 2: histogram on log10 scale for more detail
    log_values = [math.log10(v + 1) for v in values]
    fig, ax = plt.subplots(figsize=(10, 5))
    ax.hist(log_values, bins=40, color='#42a5f5', edgecolor='white')
    ax.set_title('Гистограмма пакетов по месячным скачиваниям (логарифмическая шкала)')
    ax.set_xlabel('log10(downloads_per_month + 1)')
    ax.set_ylabel('Количество пакетов')
    fig.tight_layout()
    fig.savefig(out_dir / 'downloads_histogram_log10.png', dpi=160)
    plt.close(fig)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--csv', default='pub_audit_output/package_downloads.csv')
    ap.add_argument('--out-dir', default='pub_audit_output')
    args = ap.parse_args()

    csv_path = Path(args.csv)
    out_dir = Path(args.out_dir)

    values = read_downloads(csv_path)
    make_plots(values, out_dir)

    summary = {
        'total_packages': len(values),
        'min_downloads_per_month': min(values) if values else 0,
        'max_downloads_per_month': max(values) if values else 0,
        'output_files': [
            str(out_dir / 'downloads_category_distribution.png'),
            str(out_dir / 'downloads_histogram_log10.png'),
        ],
    }
    (out_dir / 'visualization_summary.json').write_text(
        json.dumps(summary, ensure_ascii=False, indent=2),
        encoding='utf-8',
    )
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
