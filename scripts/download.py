#!/usr/bin/env python3
"""每週下載檔案腳本。

讀取專案根目錄的 config.json，從設定的網址下載檔案，
存到歷史資料夾並更新給網頁讀取的最新檔案與 manifest.json。

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
import re
import sys
import urllib.request
from datetime import date, datetime, timedelta, timezone
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


def prune_history(history_dir: Path, keep: int) -> None:
    if keep <= 0:
        return
    files = sorted(history_dir.glob("*"), key=lambda p: p.name, reverse=True)
    for old in files[keep:]:
        old.unlink()
        print(f"清除舊檔: {old.name}")


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
    history_dir = out_dir / "history"
    out_dir.mkdir(parents=True, exist_ok=True)
    history_dir.mkdir(parents=True, exist_ok=True)

    ext = guess_ext(url)
    now = datetime.now(timezone.utc)
    base = cfg.get("fileName", "data")
    # 用週數命名歷史檔，重跑同一週會覆蓋而非堆積
    safe_week = re.sub(r"[^0-9A-Za-z\-]", "_", week_label)
    history_file = history_dir / f"{base}-{safe_week}.{ext}"
    print(f"目標週: {week_label}")
    download(url, history_file)

    # 更新給網頁讀取的最新檔
    latest_file = out_dir / f"latest.{ext}"
    latest_file.write_bytes(history_file.read_bytes())

    # 清除過期歷史
    prune_history(history_dir, int(cfg.get("keepHistory", 26)))

    # 產生 manifest 供網頁辨識最新檔案
    history_list = sorted(
        (p.name for p in history_dir.glob("*")), reverse=True
    )
    manifest = {
        "latest": latest_file.name,
        "type": ext,
        "week": week_label,
        "sourceUrl": url,
        "downloadedAt": now.isoformat(),
        "history": history_list,
    }
    (out_dir / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"已更新 manifest.json，最新檔案: {latest_file.name}")
    print("完成。")


if __name__ == "__main__":
    main()
