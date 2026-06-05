#!/usr/bin/env python3
"""產生範例 CSV，讓網頁在尚未接上真實資料時也能展示。"""
import csv
import math
import random
from datetime import date, timedelta
from pathlib import Path

random.seed(42)
ROOT = Path(__file__).resolve().parent.parent
out = ROOT / "web" / "data" / "latest.csv"

rows = []
start = date(2026, 1, 1)
for i in range(120):
    rows.append({
        "date": (start + timedelta(days=i)).isoformat(),
        "lot": f"LOT{1000 + i}",
        "measurement": round(10 + math.sin(i / 6) * 0.8 + random.gauss(0, 0.5), 3),
        "thickness": round(2.5 + random.gauss(0, 0.08), 3),
        "yield": round(min(100, 95 + random.gauss(0, 2.5)), 2),
    })

with out.open("w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
    writer.writeheader()
    writer.writerows(rows)

print(f"wrote {len(rows)} rows -> {out}")
