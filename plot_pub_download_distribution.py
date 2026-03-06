#!/usr/bin/env python3
import argparse
import csv
import json
from pathlib import Path

import matplotlib.pyplot as plt


BINS = [
    (0, 10, '<10'),
    (10, 50, '10–49'),
    (50, 100, '50–99'),
    (100, 300, '100–299'),
    (300, 500, '300–499'),
    (500, 1_000, '500–999'),
    (1_000, 5_000, '1k–4.9k'),
    (5_000, 10_000, '5k–9.9k'),
    (10_000, 50_000, '10k–49.9k'),
    (50_000, 100_000, '50k–99.9k'),
    (100_000, 250_000, '100k–249.9k'),
    (250_000, 500_000, '250k–499.9k'),
    (500_000, 1_000_000, '500k–999.9k'),
    (1_000_000, None, '>=1M'),
]


def read_downloads(csv_path: Path):
    values = []
    with csv_path.open('r', encoding='utf-8', newline='') as f:
        r = csv.DictReader(f)
        for row in r:
            values.append(int(row['total_downloads']))
    return values


def bucketize(values):
    counts = {label: 0 for _, _, label in BINS}
    for v in values:
        for low, high, label in BINS:
            if high is None:
                if v >= low:
                    counts[label] += 1
                    break
            elif low <= v < high:
                counts[label] += 1
                break
    return counts


def make_plot(values, out_dir: Path):
    out_dir.mkdir(parents=True, exist_ok=True)
    counts = bucketize(values)

    labels = [label for _, _, label in BINS]
    ys = [counts[label] for label in labels]

    fig, ax = plt.subplots(figsize=(14, 6))
    bars = ax.bar(labels, ys, color='#42a5f5')
    ax.set_title('Распределение пакетов pub.dev по месячным скачиваниям (детальные диапазоны)')
    ax.set_xlabel('Диапазон скачиваний в месяц')
    ax.set_ylabel('Количество пакетов')
    ax.tick_params(axis='x', labelrotation=35)

    for b in bars:
        h = int(b.get_height())
        ax.annotate(
            f'{h:,}'.replace(',', ' '),
            (b.get_x() + b.get_width() / 2, h),
            ha='center',
            va='bottom',
            fontsize=8,
            xytext=(0, 2),
            textcoords='offset points',
        )

    fig.tight_layout()
    fig.savefig(out_dir / 'downloads_category_distribution.png', dpi=170)
    plt.close(fig)

    return counts


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--csv', default='pub_audit_output/package_downloads.csv')
    ap.add_argument('--out-dir', default='pub_audit_output')
    args = ap.parse_args()

    csv_path = Path(args.csv)
    out_dir = Path(args.out_dir)

    values = read_downloads(csv_path)
    counts = make_plot(values, out_dir)

    summary = {
        'total_packages': len(values),
        'min_downloads_per_month': min(values) if values else 0,
        'max_downloads_per_month': max(values) if values else 0,
        'bins': [{
            'label': label,
            'count': counts[label],
        } for _, _, label in BINS],
        'output_files': [
            str(out_dir / 'downloads_category_distribution.png'),
        ],
    }
    (out_dir / 'visualization_summary.json').write_text(
        json.dumps(summary, ensure_ascii=False, indent=2),
        encoding='utf-8',
    )
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
