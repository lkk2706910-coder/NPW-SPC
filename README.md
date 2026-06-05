# NPW-SPC 資料分析儀表板

每週自動從指定網址下載 Alarm Rate 週報（Excel），**增量合併**成一份長期資料庫
（`merge.xlsx`），並輸出 `merge.json` 給純前端網頁做統計摘要與圖表分析。

## 流程

```
每週排程 ──► download.py
              1. 依當前 ISO 週代入網址，下載當週 .xlsx
              2. 篩出 AREA = TF2
              3. 增量併入 merge.xlsx（同週重跑會覆蓋，不重複）
              4. 補算 ALARM_RATE_PCT 欄
              5. 輸出 merge.json + manifest.json 給網頁
              6. 刪除當週下載檔（省空間）
                         │
                         ▼
              web/  靜態網頁讀 merge.json 快速載入
```

> 重點：**第一次合併後 `merge.xlsx` 就是長期資料庫**，之後每週只把新的一週
> append 進去，不重算全部；當週下載檔併入後即刪除。

## 結構

```
NPW-SPC/
├── config.json            # 設定：網址、週次偏移、AREA 篩選等
├── scripts/
│   ├── download.py        # 每週下載（標準函式庫）→ 呼叫 merge 增量合併
│   ├── merge.py           # 增量合併 / 重建，輸出 merge.xlsx + merge.json
│   ├── make_sample.py     # 產生符合真實表頭的範例資料（測試用）
│   └── requirements.txt   # pandas, openpyxl
└── web/                   # 靜態網頁，可部署到任何平台
    ├── index.html / style.css / app.js
    └── data/
        ├── merge.xlsx     # 長期資料庫（本機留存）
        ├── merge.json     # 網頁快速載入用
        └── manifest.json  # 指向 merge.json
```

## 安裝相依套件

合併需要 pandas / openpyxl：

```bash
pip install -r scripts/requirements.txt
```

## 設定 `config.json`

```json
{
  "fileUrl": "http://10.11.108.23/QA_SPC/zkau/view/z_ouf/dwnmed-2/9op/RP0017_NPW_MONI_Alarm_Rate_Weekly_Report_{isoweek}.xlsx",
  "fileName": "NPW_Alarm_Rate_Weekly",
  "outputDir": "web/data",
  "weekOffset": -1,
  "areaFilter": "TF2",
  "computeAlarmRate": true
}
```

- `fileUrl`：檔案網址，佔位符會依「現在日期 + `weekOffset`」自動代入
  - `{isoweek}` → `2026-W22`、`{year}` → `2026`、`{week}` → `22`
- `weekOffset`：抓哪一週。`-1` = 上一週（本報告為「上週資料、本週才產出」，故預設 -1）
- `areaFilter`：merge 前只保留此 `AREA` 的列（預設 `TF2`；設為空字串則不篩）
- `computeAlarmRate`：是否補算 `ALARM_RATE_PCT = ALARM_COUNT / TOTAL_POINT_COUNT × 100`

## 每週下載 + 合併

```bash
python3 scripts/download.py                 # 自動抓上一週（weekOffset=-1）
python3 scripts/download.py --week 2026-W22  # 補抓指定某一週
python3 scripts/download.py "http://.../file.xlsx"  # 臨時指定完整網址
```

> ⚠️ 此網址為內網位置（10.11.108.23），請在公司網路內執行。
> 網址中的 `zkau/.../dwnmed-2/9op/` 是 ZK 框架的下載路徑，部分系統會綁定
> 登入工作階段而非固定連結；若下載失敗（401/404/檔案損毀），代表該段路徑
> 會隨工作階段改變，需改用帶 cookie/認證的方式下載（可再回報，我協助調整）。

### 重建整份資料庫

若要從多個歷史 `.xlsx` 重新建一份 `merge.xlsx`：把檔案放進 `web/data/rebuild/`，執行：

```bash
python3 scripts/merge.py
```

### 排程（每週自動）

**Linux / macOS（crontab）** — 每週一早上 8 點：

```bash
crontab -e
0 8 * * 1 cd /path/to/NPW-SPC && /usr/bin/python3 scripts/download.py >> download.log 2>&1
```

**Windows（工作排程器）**：建立週觸發工作，動作 `python C:\path\to\NPW-SPC\scripts\download.py`。

## 看網頁

需透過 HTTP 開啟（`file://` 因瀏覽器限制無法讀 `data/`）：

```bash
cd web
python3 -m http.server 8000
# 瀏覽器開 http://localhost:8000
```

網頁功能：
- 自動讀 `merge.json`，顯示涵蓋週數區間
- 摘要卡片、趨勢圖（預設 X=週、Y=ALARM_RATE_PCT，附平均線）、直方圖
- 各數值欄位統計表、資料預覽
- 右上角可手動上傳 CSV / Excel 來臨時分析

## 部署到靜態平台

`web/` 整個資料夾即靜態網站（Vercel / Netlify：publish 目錄設 `web`）。
每週由本機（或 CI）跑 `download.py`，再把更新後的 `web/data/` 推上去即可。

> 提示：圖表函式庫（Chart.js、PapaParse、SheetJS）透過 CDN 載入，部署環境需能連外。
