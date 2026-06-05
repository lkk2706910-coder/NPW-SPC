#!/usr/bin/env python3
"""每週下載檔案腳本。

讀取專案根目錄的 config.json，從設定的網址下載檔案，
存到歷史資料夾並更新給網頁讀取的最新檔案與 manifest.json。

用法:
    python scripts/download.py              # 使用 config.json 的網址
    python scripts/download.py <url>        # 臨時指定網址（覆蓋設定）

排程（每週一早上 8 點，Linux/macOS crontab）:
    0 8 * * 1 cd /path/to/NPW-SPC && /usr/bin/python3 scripts/download.py >> download.log 2>&1
"""
from __future__ import annotations

import json
import sys
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONFIG_PATH = ROOT / "config.json"


def load_config() -> dict:
    if not CONFIG_PATH.exists():
        raise SystemExit(f"找不到設定檔: {CONFIG_PATH}")
    with CONFIG_PATH.open(encoding="utf-8") as f:
        return json.load(f)


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
    url = sys.argv[1] if len(sys.argv) > 1 else cfg.get("fileUrl", "")
    if not url or "example.com" in url:
        raise SystemExit(
            "請先在 config.json 設定真實的 fileUrl，或用參數傳入網址：\n"
            "    python scripts/download.py <網址>"
        )

    out_dir = ROOT / cfg.get("outputDir", "web/data")
    history_dir = out_dir / "history"
    out_dir.mkdir(parents=True, exist_ok=True)
    history_dir.mkdir(parents=True, exist_ok=True)

    ext = guess_ext(url)
    now = datetime.now(timezone.utc)
    stamp = now.strftime("%Y-%m-%d")
    base = cfg.get("fileName", "data")

    history_file = history_dir / f"{base}-{stamp}.{ext}"
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
