#!/usr/bin/env python3
"""產生符合真實表頭的範例週報，並示範「增量合併」流程。

模擬每週下載 → append_week（內含 AREA=TF2 篩選、YEAR/WEEK 取週、補 ALARM_RATE_PCT）
→ 刪除當週檔，最終得到 merge.xlsx / merge.json / manifest.json。
"""
import random
import sys
from pathlib import Path

import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))
from merge import append_week, merge_xlsx_path, out_dir  # noqa: E402

random.seed(42)

# 真實表頭
META = ["YEAR", "WEEK", "DATA_PERIOD", "PROCESS", "PRODUCT", "AREA",
        "UCHART_ID", "CHART_NAME", "PARAMETER", "PROCESSUNIT"]
MAIN = ["ALARM_COUNT", "LAST_ALARM_COUNT_1", "ALARM_COUNT_1", "TOTAL_POINT_COUNT"]
RULE = ["GUMC63_COUNT", "GUMC64_COUNT", "G63+64", "GUMC65_COUNT", "GUMC66_COUNT", "G65+66",
        "GUMC67_COUNT", "GUMC68_COUNT", "G67+68", "GUMC69_COUNT", "GUMC70_COUNT", "G69+70",
        "GWE1_COUNT", "GWE5_COUNT", "G1+5", "GWE2_COUNT", "GWE3_COUNT", "GWE4_COUNT",
        "GWE6_COUNT", "GWE7_COUNT", "GWE8_COUNT", "GWE9_COUNT", "GWE10_COUNT"]
RULE += [f"GUMC{n:02d}_COUNT" for n in range(1, 16)]
RULE += [f"GUMC{n}_COUNT" for n in (40, 41, 42, 43, 60, 61, 62)]
RULE += [f"GUMC{n}_COUNT" for n in range(71, 81)]
TRAILING = ["CHART_TYPE", "CHART_MODE", "CHART_CATEGORY", "PHASE",
            "AREA_SOURCE", "TOOL_TYPE", "SPEC_TYPE"]
COLUMNS = META + MAIN + RULE + TRAILING

AREAS = ["TF1", "TF2", "TF3"]
PROCESSES = ["CVD", "ETCH", "PHOTO"]
PARAMS = ["Thickness", "Uniformity", "Defect", "Particle"]


def make_row(year, week, area, process, param, idx):
    rule_vals = {c: 0 for c in RULE}
    # 隨機讓幾個規則觸發
    for c in random.sample(RULE, k=random.randint(0, 3)):
        if not c.startswith("G") or "+" not in c:
            rule_vals[c] = random.randint(1, 4)
    # G*+* 為相鄰兩欄之和
    for pair, a, b in [("G63+64", "GUMC63_COUNT", "GUMC64_COUNT"),
                       ("G65+66", "GUMC65_COUNT", "GUMC66_COUNT"),
                       ("G67+68", "GUMC67_COUNT", "GUMC68_COUNT"),
                       ("G69+70", "GUMC69_COUNT", "GUMC70_COUNT"),
                       ("G1+5", "GWE1_COUNT", "GWE5_COUNT")]:
        rule_vals[pair] = rule_vals[a] + rule_vals[b]
    alarm = sum(v for c, v in rule_vals.items() if "+" not in c)
    total = random.randint(120, 400)
    row = {
        "YEAR": year, "WEEK": week, "DATA_PERIOD": f"{year}W{week:02d}",
        "PROCESS": process, "PRODUCT": f"PRD{random.randint(1,3)}", "AREA": area,
        "UCHART_ID": f"UC{idx:04d}", "CHART_NAME": f"{process}_{param}_{idx}",
        "PARAMETER": param, "PROCESSUNIT": f"{process}-{random.randint(1,6):02d}",
        "ALARM_COUNT": alarm, "LAST_ALARM_COUNT_1": max(0, alarm + random.randint(-2, 2)),
        "ALARM_COUNT_1": alarm, "TOTAL_POINT_COUNT": total,
        "CHART_TYPE": "Xbar-R", "CHART_MODE": "AUTO", "CHART_CATEGORY": "SPC",
        "PHASE": "MP", "AREA_SOURCE": area, "TOOL_TYPE": "ETCHER", "SPEC_TYPE": "TWO_SIDE",
    }
    row.update(rule_vals)
    return row


d = out_dir()
for name in ("merge.xlsx", "merge.json", "manifest.json", "latest.csv"):
    p = d / name
    if p.exists():
        p.unlink()

# 模擬 2026 年 W20 ~ W23 四週，逐週下載→併入→刪除
for week in range(20, 24):
    rows, idx = [], 0
    for area in AREAS:                  # 含 TF1/TF2/TF3，驗證 TF2 篩選
        for process in PROCESSES:
            for param in PARAMS:
                idx += 1
                rows.append(make_row(2026, week, area, process, param, idx))
    df = pd.DataFrame(rows, columns=COLUMNS)
    # 固定檔名每週覆蓋，與 download.py 行為一致
    weekly_file = d / "NPW_Alarm_Rate_Weekly.xlsx"
    df.to_excel(weekly_file, index=False)
    print(f"[下載] 2026-W{week:02d} -> {weekly_file.name}（{len(df)} 列，含全部 AREA）")

    append_week(weekly_file, week_label=f"2026-W{week:02d}",
                source_url="範例資料（執行 download.py 後會被真實資料覆蓋）")
    weekly_file.unlink()
    print(f"[刪除] {weekly_file.name}\n")

print(f"完成。長期資料庫: {merge_xlsx_path().name}")
