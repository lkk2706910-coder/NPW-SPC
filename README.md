# NPW-SPC 資料分析儀表板

每週自動從指定網址下載資料檔（CSV / Excel），並用一個純前端網頁做統計摘要與圖表分析。

## 結構

```
NPW-SPC/
├── config.json            # 設定：檔案網址、輸出位置、保留週數
├── scripts/
│   ├── download.py        # 每週下載腳本（只用 Python 標準函式庫）
│   └── make_sample.py     # 產生範例資料（測試用）
└── web/                   # 靜態網頁，可直接部署到任何平台
    ├── index.html
    ├── style.css
    ├── app.js
    └── data/              # 下載的資料會放這裡
        ├── manifest.json  # 記錄最新檔案資訊
        ├── latest.csv     # 網頁讀取的最新資料
        └── history/       # 歷史下載存檔
```

## 設定

`config.json` 範例（已預設為 NPW Alarm Rate 週報）：

```json
{
  "fileUrl": "http://10.11.108.23/QA_SPC/zkau/view/z_ouf/dwnmed-2/9op/RP0017_NPW_MONI_Alarm_Rate_Weekly_Report_{isoweek}.xlsx",
  "fileName": "NPW_Alarm_Rate_Weekly",
  "outputDir": "web/data",
  "keepHistory": 26,
  "weekOffset": 0
}
```

- `fileUrl`：檔案網址，可用佔位符自動代入週數
  - `{isoweek}` → `2026-W22`（ISO 年-週）
  - `{year}` → `2026`、`{week}` → `22`
- `fileName`：歷史檔的檔名前綴
- `outputDir`：下載輸出資料夾（預設給網頁讀取）
- `keepHistory`：保留幾份歷史檔（26 約等於半年）
- `weekOffset`：抓哪一週。`0` = 本週；若週報是「上週資料、本週才產出」，設 `-1` 抓上一週

支援副檔名：`.csv` `.tsv` `.xlsx` `.xls`（會依網址自動判斷）。

## 每週下載

手動執行一次：

```bash
python3 scripts/download.py                 # 自動抓現在這一週
python3 scripts/download.py --week 2026-W22  # 指定某一週（補抓歷史）
python3 scripts/download.py "http://.../file.xlsx"  # 臨時指定完整網址
```

> ⚠️ 此網址為內網位置（10.11.108.23），請在公司網路內執行。
> 網址中的 `zkau/.../dwnmed-2/9op/` 是 ZK 框架的下載路徑，部分系統會綁定
> 登入工作階段而非固定連結；若下載失敗（401/404/檔案損毀），代表該段路徑
> 會隨工作階段改變，需改用帶 cookie/認證的方式下載（可再回報，我協助調整）。

執行後會：
1. 下載檔案到 `web/data/history/data-YYYY-MM-DD.<ext>`
2. 更新 `web/data/latest.<ext>`
3. 更新 `web/data/manifest.json`
4. 清除超過 `keepHistory` 的舊檔

### 排程（每週自動）

**Linux / macOS（crontab）** — 每週一早上 8 點：

```bash
crontab -e
# 加入下面這行（請改成你的實際路徑）
0 8 * * 1 cd /path/to/NPW-SPC && /usr/bin/python3 scripts/download.py >> download.log 2>&1
```

**Windows（工作排程器 Task Scheduler）**：建立週觸發的工作，動作設為
`python C:\path\to\NPW-SPC\scripts\download.py`。

## 看網頁

網頁需要透過 HTTP 開啟（直接用 `file://` 開會因瀏覽器限制無法讀取 `data/` 檔）。

本機預覽：

```bash
cd web
python3 -m http.server 8000
# 瀏覽器開 http://localhost:8000
```

網頁功能：
- 自動讀取最新下載的資料
- 摘要卡片（列數 / 欄位數 / 數值欄位數）
- 趨勢圖（可選 X 軸與數值欄位，附平均參考線）
- 分佈直方圖
- 各數值欄位統計表（平均、標準差、最小、中位數、最大）
- 資料預覽表
- 右上角可手動上傳任意 CSV / Excel 來分析

## 部署到靜態平台

`web/` 整個資料夾就是靜態網站，可直接丟到 Vercel / Netlify / GitHub Pages 等：

- **Vercel / Netlify**：設定 publish 目錄為 `web`
- 部署後，每週由你本機（或 CI）跑 `download.py`，再把更新後的 `web/data/`
  推上去，網頁就會顯示最新資料

> 提示：圖表函式庫（Chart.js、PapaParse、SheetJS）皆透過 CDN 載入，
> 部署環境需要能連外。
