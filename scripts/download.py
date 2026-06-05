#!/usr/bin/env python3
"""每週下載檔案腳本。

讀取專案根目錄的 config.json，從設定的網址下載當週檔案，
增量併入 merge.xlsx / merge.json，併入後刪除當週下載檔以省空間。

網址可使用佔位符，會依「現在日期 + weekOffset」自動代入:
    {isoweek}  -> 例 2026-W22 （ISO 年-週）
    {year}     -> 例 2026     （ISO 年）
    {week}     -> 例 22       （ISO 週，補零兩位）

用法:
    python scripts/download.py              # 使用 config.json，自動代入當前週
    python scripts/download.py <url>        # 臨時指定完整網址（覆蓋設定）
    python scripts/download.py --week 2026-W22   # 指定某一週

排程（每週一早上 8 點，Linux/macOS crontab）:
    0 8 * * 1 cd /path/to/NPW-SPC && /usr/bin/python3 scripts/download.py >> download.log 2>&1
"""
from __future__ import annotations

import json
import sys
import urllib.request
from datetime import date, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONFIG_PATH = ROOT / "config.json"


def load_config() -> dict:
    if not CONFIG_PATH.exists():
        raise SystemExit(f"找不到設定檔: {CONFIG_PATH}")
    with CONFIG_PATH.open(encoding="utf-8") as f:
        return json.load(f)


def iso_week_label(d: date) -> str:
    """回傳像 2026-W22 的 ISO 年-週字串。"""
    iso = d.isocalendar()
    return f"{iso.year}-W{iso.week:02d}"


def resolve_url(template: str, week_label: str) -> str:
    """把網址裡的 {isoweek}/{year}/{week} 佔位符代入實際週數。"""
    year, week = week_label.split("-W")
    return (
        template.replace("{isoweek}", week_label)
        .replace("{year}", year)
        .replace("{week}", week)
    )


def parse_args(argv: list[str]) -> tuple[str | None, str | None]:
    """回傳 (override_url, week_label)。"""
    override_url = None
    week_label = None
    i = 0
    while i < len(argv):
        arg = argv[i]
        if arg == "--week" and i + 1 < len(argv):
            week_label = argv[i + 1]
            i += 2
        elif arg.startswith("http"):
            override_url = arg
            i += 1
        else:
            i += 1
    return override_url, week_label


def guess_ext(url: str) -> str:
    """從網址或內容推測副檔名，預設 csv。"""
    lower = url.lower().split("?")[0]
    for ext in (".csv", ".xlsx", ".xls", ".tsv", ".json"):
        if lower.endswith(ext):
            return ext.lstrip(".")
    return "csv"


def download(url: str, dest: Path) -> None:
    print(f"下載中: {url}")
    req = urllib.request.Request(url, headers={"User-Agent": "NPW-SPC-downloader/1.0"})
    with urllib.request.urlopen(req, timeout=120) as resp:
        data = resp.read()
    dest.write_bytes(data)
    print(f"已存檔: {dest} ({len(data):,} bytes)")


def main() -> None:
    cfg = load_config()
    override_url, week_label = parse_args(sys.argv[1:])

    # 決定要抓哪一週：--week 指定 > 現在日期 + weekOffset
    if week_label is None:
        offset = int(cfg.get("weekOffset", 0))
        target_day = date.today() + timedelta(weeks=offset)
        week_label = iso_week_label(target_day)

    template = cfg.get("fileUrl", "")
    if override_url:
        url = override_url
    elif not template or "example.com" in template:
        raise SystemExit(
            "請先在 config.json 設定真實的 fileUrl，或用參數傳入網址：\n"
            "    python scripts/download.py <網址>"
        )
    else:
        url = resolve_url(template, week_label)

    out_dir = ROOT / cfg.get("outputDir", "web/data")
    out_dir.mkdir(parents=True, exist_ok=True)

    ext = guess_ext(url)
    # 固定檔名，每週覆蓋（併入 merge 後即刪除，不留每週新檔）
    base = cfg.get("fileName", "data")
    weekly_file = out_dir / f"{base}.{ext}"
    print(f"目標週: {week_label}")
    download(url, weekly_file)

    # 增量併入 merge.xlsx（本機留存）+ merge.json（網頁載入）
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    try:
        from merge import append_week
    except ImportError as exc:
        print(
            f"\n⚠️ 無法合併（{exc}）。已保留當週下載檔 {weekly_file.name}，"
            "但未併入 merge。\n   請先安裝相依套件：pip install -r scripts/requirements.txt"
        )
        return

    append_week(weekly_file, week_label=week_label, source_url=url)

    # 併入成功 -> 刪除當週下載檔以省空間
    weekly_file.unlink()
    print(f"已刪除當週下載檔: {weekly_file.name}")
    print("完成。")


if __name__ == "__main__":
    main()
