#!/usr/bin/env python3
"""維護合併資料庫 merge.xlsx，並輸出 merge.json 供網頁快速載入。

設計（增量合併）:
- merge.xlsx 是長期累積的「資料庫」，本機留存。
- 每週下載新檔後，只把「該週」資料 append 進 merge.xlsx，不重算全部。
- 同一週重跑會先移除舊的該週資料再加入，確保不重複（冪等）。
- append 完成後，當週下載檔可由 download.py 刪除以省空間。
- merge.json 是 merge.xlsx 的 JSON 版本，給網頁免解 Excel、快速載入。

主要函式:
    append_week(new_file, week_label, source_url)  # 增量：日常每週用
    rebuild_from_files(files, source_url)           # 整批：第一次或重建用
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
CONFIG_PATH = ROOT / "config.json"
WEEK_RE = re.compile(r"(\d{4}-W\d{2})")


def load_config() -> dict:
    with CONFIG_PATH.open(encoding="utf-8") as f:
        return json.load(f)


def out_dir() -> Path:
    d = ROOT / load_config().get("outputDir", "web/data")
    d.mkdir(parents=True, exist_ok=True)
    return d


def merge_xlsx_path() -> Path:
    return out_dir() / "merge.xlsx"


def read_table(path: Path) -> pd.DataFrame:
    """讀單一檔案為 DataFrame（不含 week 欄）。"""
    suffix = path.suffix.lower()
    if suffix in (".xlsx", ".xls"):
        return pd.read_excel(path)
    if suffix == ".tsv":
        return pd.read_csv(path, sep="\t")
    return pd.read_csv(path)


def week_from_name(path: Path) -> str:
    m = WEEK_RE.search(path.name)
    return m.group(1) if m else path.stem


def _col(df: pd.DataFrame, name: str):
    """不分大小寫找欄位，回傳實際欄名或 None。"""
    for c in df.columns:
        if str(c).upper() == name.upper():
            return c
    return None


def derive_week(df: pd.DataFrame, fallback: str) -> pd.Series:
    """week 欄優先用資料自身的 YEAR/WEEK，否則用檔名推得的 fallback。"""
    yc, wc = _col(df, "YEAR"), _col(df, "WEEK")
    if yc is not None and wc is not None:
        year = pd.to_numeric(df[yc], errors="coerce")
        week = pd.to_numeric(df[wc], errors="coerce")
        return year.astype("Int64").astype(str) + "-W" + week.astype("Int64").astype(str).str.zfill(2)
    return pd.Series([fallback] * len(df), index=df.index)


def add_derived_columns(df: pd.DataFrame) -> pd.DataFrame:
    """若有 ALARM_COUNT 與 TOTAL_POINT_COUNT，補一個 ALARM_RATE_PCT 方便分析。"""
    if not load_config().get("computeAlarmRate", True):
        return df
    ac, tc = _col(df, "ALARM_COUNT"), _col(df, "TOTAL_POINT_COUNT")
    if ac is not None and tc is not None:
        total = pd.to_numeric(df[tc], errors="coerce")
        alarm = pd.to_numeric(df[ac], errors="coerce")
        df = df.copy()
        df["ALARM_RATE_PCT"] = (alarm / total * 100).where(total > 0).round(4)
    return df


def filter_rows(df: pd.DataFrame) -> pd.DataFrame:
    """merge 前的列篩選：依 config.areaFilter 篩 AREA（預設 TF2）。"""
    area_filter = load_config().get("areaFilter", "TF2")
    if not area_filter:
        return df
    ac = _col(df, "AREA")
    if ac is None:
        print(f"⚠️ 找不到 AREA 欄，跳過 {area_filter} 篩選")
        return df
    before = len(df)
    kept = df[df[ac].astype(str).str.strip() == str(area_filter)]
    print(f"AREA={area_filter} 篩選：{before} → {len(kept)} 列")
    return kept.reset_index(drop=True)


def load_merge() -> pd.DataFrame:
    """讀現有 merge.xlsx；不存在則回傳空 DataFrame。"""
    path = merge_xlsx_path()
    if path.exists():
        return pd.read_excel(path)
    return pd.DataFrame()


def append_week(new_file: Path, week_label: str | None = None,
                source_url: str | None = None) -> dict:
    """把單一週的新檔增量併入 merge.xlsx。"""
    new_file = Path(new_file)
    week_label = week_label or week_from_name(new_file)

    new_df = read_table(new_file)
    new_df = filter_rows(new_df)                       # 先篩 AREA=TF2
    new_df.insert(0, "week", derive_week(new_df, week_label))
    weeks_in_new = set(new_df["week"].astype(str))

    base = load_merge()
    if not base.empty and "week" in base.columns:
        # 移除新檔涵蓋週次的既有資料，確保重跑冪等
        kept = base[~base["week"].astype(str).isin(weeks_in_new)]
        removed = len(base) - len(kept)
        if removed:
            print(f"移除既有 {sorted(weeks_in_new)} 共 {removed} 列，改用新資料")
        base = kept

    combined = pd.concat([base, new_df], ignore_index=True)
    combined = combined.drop_duplicates().reset_index(drop=True)
    print(f"併入 {sorted(weeks_in_new)}（新增 {len(new_df)} 列），merge 現有 {len(combined)} 列")
    return _write_outputs(combined, source_url)


def rebuild_from_files(files: list[Path], source_url: str | None = None) -> dict:
    """從多個檔案整批重建 merge.xlsx（第一次或需要重算時用）。"""
    frames = []
    for p in sorted(files):
        try:
            df = read_table(p)
            df = filter_rows(df)                       # 先篩 AREA=TF2
            df.insert(0, "week", derive_week(df, week_from_name(p)))
            frames.append(df)
        except Exception as exc:
            print(f"略過無法讀取的檔案 {p.name}: {exc}")
    if not frames:
        raise SystemExit("沒有可合併的檔案")
    combined = pd.concat(frames, ignore_index=True).drop_duplicates().reset_index(drop=True)
    print(f"整批重建：{len(frames)} 個檔案，共 {len(combined)} 列")
    return _write_outputs(combined, source_url)


def _write_outputs(merged: pd.DataFrame, source_url: str | None) -> dict:
    """輸出 merge.xlsx / merge.json / manifest.json。"""
    d = out_dir()
    merged = add_derived_columns(merged)               # 補 ALARM_RATE_PCT
    if "week" in merged.columns:
        merged = merged.sort_values("week", kind="stable").reset_index(drop=True)

    # 1) merge.xlsx 本機留存（長期資料庫）
    merged.to_excel(d / "merge.xlsx", index=False)

    # 2) merge.json 給網頁
    now = datetime.now(timezone.utc)
    weeks = (
        sorted(merged["week"].dropna().astype(str).unique().tolist())
        if "week" in merged.columns else []
    )
    payload = {
        "generatedAt": now.isoformat(),
        "sourceUrl": source_url or load_config().get("fileUrl", ""),
        "weeks": weeks,
        "rowCount": int(len(merged)),
        "columns": [str(c) for c in merged.columns],
        "rows": json.loads(merged.to_json(orient="records", date_format="iso")),
    }
    (d / "merge.json").write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")

    # 3) manifest 指向 merge.json
    manifest = {
        "latest": "merge.json",
        "type": "json",
        "weeks": weeks,
        "rowCount": int(len(merged)),
        "sourceUrl": payload["sourceUrl"],
        "downloadedAt": now.isoformat(),
    }
    (d / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"已輸出 merge.xlsx / merge.json / manifest.json（{len(weeks)} 週、{len(merged)} 列）")
    return manifest


if __name__ == "__main__":
    # 直接執行：把 outputDir/rebuild/ 內的檔案整批重建（手動重建用）
    rebuild_dir = out_dir() / "rebuild"
    if rebuild_dir.exists():
        files = [p for p in rebuild_dir.glob("*") if p.suffix.lower() in (".xlsx", ".xls", ".csv", ".tsv")]
        rebuild_from_files(files)
    else:
        print(f"請把要整批重建的週報放進 {rebuild_dir} 後再執行，或改用 download.py 的增量流程。")
    print("完成。")
