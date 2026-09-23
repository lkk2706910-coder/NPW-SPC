# AGENTS.md — NPW-SPC

給 AI coding agent（Claude Code / Copilot / Cursor …）與新加入的人看的工作說明。
內容以 `test` 分支（目前主要開發線）為準；其他分支的差異見「分支地圖」。

---

## 0. 一句話

TF2 / T_EQ1 AMAT 機台的 **NPW alarm 日報 dashboard**：ASP.NET WebForms 單頁（`.aspx` + code-behind `.aspx.cs`），
讀 SQL Server（`GPTDB_USPC.dbo.TF2_NPW_CHART` 等），前端純 JS + Chart.js，附 EMST 填寫、Wafer Match（對角度）、AI 小幫手。

---

## 1. 分支地圖（每個分支是不同的交付物，**不要互相 merge**）

| 分支 | 內容 | 狀態 |
|---|---|---|
| `test` | **目前開發線**。`TF2/EQ_NPW_all_dashboard.aspx(.cs)`：日報版、Monitor type 欄、EMST 明細彈窗、伺服器端快取、Entity 篩選、排序、S1/S2 trend | 活躍 |
| `NPW_Alarm_control_system` | 舊的 TF2 週報版 `TF2/NPW_Alarm.aspx`：週區間、ADDER/NON-ADDER 計數表、down chart 作業區（測機排程 + 勾選） | 停在 2026-08 |
| `NPW_Alarm_TF2_AllTool` | 更早的 TF2 全機台版 | 封存 |
| `Tool-ABC` | `TF2_Dashboard.aspx` 另一個 dashboard 原型 | 封存 |
| `claude/weekly-file-download-analysis-VaQWH`（remote HEAD） | **完全不同的專案**：Python 每週下載 Alarm Rate 週報 Excel → `merge.xlsx/json` → `web/` 靜態網頁 | 獨立 |

規則：
- 使用者會直接說要推到哪個分支（多半是 `test`）；**沒說就問，不要猜**，也不要 push 到別的分支。
- 若使用者要「把 A 分支的功能搬到 B」，用 cherry-pick 或手動移植，不要整支 merge（檔名、版面都不同）。
- 每個分支各自獨立部署到 IIS，沒有 CI。

---

## 2. `test` 分支檔案結構

```
TF2/
  EQ_NPW_all_dashboard.aspx      主頁 + 明細彈窗 + 全部前端 JS/CSS（~180 KB，單檔）
  EQ_NPW_all_dashboard.aspx.cs   code-behind：所有 ?op= JSON 端點、快取、EMST 檔案、SPC 抓圖
  WaferMatch.html                對角度工具（canvas），以 iframe 內嵌 / 彈窗開啟，支援 ?embed=1
  web.config                     連線字串、AI gateway 設定、hiddenSegments（emst_data / cache）
  OCAP/                          使用者上傳的 OCAP 明細站（參考來源；明細彈窗是照它「照抄」進主頁的）
    OCAP.aspx(.cs), WaferMatch.html, Web.config, TF2api/*.ashx
TF1/
  NPW_Alarm_TF1.aspx(.cs)        TF1 版（較舊，未同步 test 的新功能）
refer.html                       最早的純前端原型，僅供參考
```

伺服器上另有（不在 repo）：`TF2/TF2api/`（SPC 代理 .ashx，現已多半改由 `.aspx.cs` 內建端點取代）、
`TF2/emst_data/`、`TF2/cache/`（執行期自動建立）。

---

## 3. 後端端點（全部走 `EQ_NPW_all_dashboard.aspx?op=…`，Page_Load 依 `op` 分派後 `Response.End()`）

| op | 用途 | 備註 |
|---|---|---|
| `alarm&date=` | 當天所有 C-C / XBAR 列（NISACVD% / SACVD%） | 前端自己做篩選與彙總（`buildStats`） |
| `port&date=` | LOT → `[MESI_DB].[dbo].[ews_lothist]` PORTID 對應 | **快取**；`&nocache=1` 強制重查 |
| `chartdata&cids=&end=&days=` | 趨勢圖序列（60 天） | 主頁縮圖一次批次查 |
| `chartid&name=` | CHART_NAME → CHART_ID（S1/S2 對應 chart 用） | |
| `mapinfo` | SPC PRE/ADDER map 網址 + MeasurePU（抓 `10.10.101.170` 頁面解析） | **快取** 30 天 / 沒抓到 10 分 |
| `profileimg` | SPC profile RAW 圖網址 | **快取** 同上 |
| `ocapdetail` | OCAP 紀錄 + chart 列（無 OCAP 也回 `ocapFound=false`） | |
| `wafercount&tool=&scope=` | PM 後累計片數 vs SPEC | 移植自 OCAP |
| `emst` GET/POST `&uchart_id=&chart_seq=&date=` | EMST 填寫內容 | 每天一檔 `emst_data/yyyy-MM-dd EMST.json`，key = `uid_seq` |
| `chat` POST | AI 小幫手 → 內部 LLM gateway | 401/407 一律轉 502（避免 IIS 跳 Windows 驗證） |
| `getchecks` / `savecheck` | 測機排程勾選（`sched_checks.json`） | 控制分支的作業區用，test 分支已無 UI |
| `data` | 通用查詢（除錯用） | |

**快取機制**（`CachedJson`）：記憶體 `HttpRuntime.Cache` + 檔案 `cache/<kind>/<key>.json`；同 key 加鎖避免同時多人打 DB；
過期時先回舊資料、背景只發一次重查（stale-while-revalidate）；回應帶 `cached / cachedAt / stale`。
**沒有排程預熱**，使用者明確不要。

---

## 4. 硬性規則（違反會直接壞掉）

1. **`.aspx.cs` 必須是純 ASCII**。伺服器以 Big5/CP950 編譯，非 ASCII 字元會吃掉換行導致編譯失敗。
   註解一律英文；中文只能放在 `.aspx`（頁面已宣告 UTF-8 且 web.config 有 `globalization fileEncoding="utf-8"`）。
   檢查：`LC_ALL=C grep -nP '[^\x00-\x7F]' TF2/EQ_NPW_all_dashboard.aspx.cs` 必須無輸出。
2. **這裡沒有 C# 編譯器**（無 mono/dotnet）。改 `.cs` 後至少做：ASCII 檢查、大括號/小括號配對、逐行重讀。
   告訴使用者「部署後請開頁確認」，不要宣稱已編譯通過。
3. SQL 一律用參數 `@p0, @p1…` 透過 `QueryRows(sql, args...)`；跨庫用三段式名稱（同一台 `UMCESIDB02`）；
   查詢加 `WITH (NOLOCK)`；日期條件寫成可用索引的 `>= @p0 AND < @p1`。
4. `EnableSessionState="false"` 不能拿掉（否則 ASP.NET session 鎖會把同一使用者的請求串行化，頁面變慢）。
5. `web.config` 內含 DB 密碼與 AI API key（使用者自己提交的）。不要把它們貼到聊天以外的地方、不要寫進 commit message。
6. Commit message / 程式碼 / PR **不要出現模型名稱或版本**（Claude、GPT 等）。
7. 不要自作主張建 PR、不要 force push、不要 rebase 掉別人的 commit。remote 的 `test` 可能有使用者直接上傳的 commit，push 被拒就 `git pull --rebase origin test` 再推。
8. Wafer Match 的 map 對位：**維持 180°**、用幾何對齊（頂端貼齊、滿版圓盤），不要再改回用 canvas 讀取跨域圖片。

---

## 5. 領域規則（業務邏輯，改之前先確認）

- **Entity**：`PROCESSUNIT` 在第一個 `-` 之前（只顯示 NISACVD / SACVD）。Tool_name 欄 = 完整 `PROCESSUNIT`。
- **ADDER** = `CHART_TYPE='C-C'`；**NON-ADDER** = `'XBAR'`。NON-ADDER 只列 CHART_NAME 含 `U%` 或 `RANGE` 的 chart。
- 列的條件：`ALARM_COUNT >= 1` **或** `MONITOR_TYPE='DOWN'`（DOWN 的 ALARM_COUNT 多為 0 仍要列）。`CHART_DESC='Engineering'` **不排除**（2026-09 起）。
- 主表每列 = 一筆 alarm（key `CHART_ID||CHART_NAME||CHART_SEQ`）；「Alarm 次數」顯示該 chart 當天合計。
- **Monitor type** 欄：PM / NORMAL 藍 `#1976d2`，DOWN 及其他黑 `#111`。
- **Port 對應**（`op=port`）：`LOTID = LOT` 去掉尾綴 `_ADD`；取 EWS `JPTIME` 與 NPW `LASTDATATMST` **最接近的一筆**；
  ADDER 只接受 `JPTIME <= LASTDATATMST` 且 7 天內並須 `RECIPE LIKE PPID+'%'`；NON-ADDER 不比 RECIPE、允許 ±7 天。多個 port 就全部顯示。
- **Trend Y 軸**：ADDER 下限固定 0、上限 UCL×1.10；NON-ADDER 上限 UCL×1.01、下限 LCL×0.99。超界點裁到邊界並標紅。
- **S1/S2**：ADDER 看 CHART_NAME 的 `W1`/`W2`；NON-ADDER 看形如 `AC2`/`BC2`/`B2` 的段落尾數。明細同時畫本筆 chart 與另一面（`dSiblingName`）。
- **Wafer Match 參數**（`wmDeriveParams` / `wmDeriveProfileParams`）：
  - mode 由機台 B 號決定：FI5.X = NISACVD B01–05/B09–14、SACVD B01–05/B07；FI6.4 = NISACVD B06–08、SACVD B06/B08–12/B81。
  - station 由 Tool_name 尾碼字母：A/B/C → CHA/CHB/CHC，多字母（CB、CA…）→ `CHC+CHB`，無字母 → LL。
  - CASS 由 Port 1–4 → A–D；side 由 W1/W2（NON-ADDER 由段落尾數）；offset：ADDER 0；NON-ADDER 含 `HTN430D4` → 300、符合 `HTN%D1` → 0、其他 180。
- **EMST 公版**：1. Tool、2. Wafer count、3. Item（自由填寫）、4. Action（預填 `4-1.`，Enter 自動 `4-2.`…）、5. Follow up（`5-1.`…）。
  複製時 4/5 的標題自成一列、編號列在下方。NISACVD 的 wafer count 只帶 B-PM。舊存檔的 `3-x./4-x.` 載入時自動改為 `4-x./5-x.`。
- **明細彈窗**：ADDER 沒有 Profile 窗格；NON-ADDER 沒有 PRE/ADDER map。內容是 OCAP.aspx 的明細「照抄」，改動時盡量與 OCAP 行為一致。

---

## 6. 前端結構重點（`EQ_NPW_all_dashboard.aspx`）

- 三段 `<script>`：主 IIFE（資料、表格、明細、EMST、快取、排序/篩選/浮動捲軸）、Wafer Match 彈窗與參數推導、AI 小幫手。
- `PAGE` = 目前檔名（`location.pathname` 取尾），所有 fetch 都用 `PAGE + '?op=…'`，改檔名不用改程式。
- 關鍵函式：`loadFromDb` → `buildStats`（彙總 + 各 `chart*` 對照表）→ `buildInlineChartDetailHtml` → `hydratePreviews`（Chart.js 縮圖）→ `setupLazyMaps`（IntersectionObserver 懶載入 map/profile）→ `applyEntityFilter` / `applySort` / `hscrollUpdate`。
- Port 在主表渲染**之後**背景載入（`loadPorts` → `applyPorts` 就地填格），不重繪表格。
- `fetchProxy` / `fetchProfile`：頁內 promise 快取 + 限流 3；明細彈窗也走同一份（`front=true` 插隊）。
- `_emstRows[mkey]` 登錄每列資料，EMST 按鈕 `emstOpen(btn)` 由此開 `openDetail(row)`。
- 篩選 / 排序 / 浮動橫向捲軸都是純 DOM 操作（`data-entity / data-tool / data-ts / data-order`），不重抓資料。
- 使用者偏好存 localStorage：`npwEntFilter`、`npwSortKey`、`npwSortDesc`。

---

## 7. 驗證方式（每次改完都做）

```bash
# 1) 抽出三段內嵌 script 做語法檢查
S=/tmp/npw && mkdir -p $S && node -e '
const fs=require("fs");const src=fs.readFileSync("TF2/EQ_NPW_all_dashboard.aspx","utf8");
const re=/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/gi;let m,i=0;
while((m=re.exec(src))){fs.writeFileSync(process.argv[1]+"/s"+(i++)+".js",m[1]);}' $S && for f in $S/s?.js; do node --check "$f"; done

# 2) code-behind 純 ASCII + 括號配對
LC_ALL=C grep -nP '[^\x00-\x7F]' TF2/EQ_NPW_all_dashboard.aspx.cs   # 必須無輸出
```

行為驗證用 Playwright（`/opt/node22/lib/node_modules/playwright`，Chromium 已預裝）：起一個本機 http server，
把 `.aspx` 去掉 `<%@ … %>` 當 HTML 提供，並用假 JSON 回應各 `?op=`，再操作頁面檢查 DOM。
Chart.js 走 CDN，沙盒無外網時圖會是空白，屬正常。

---

## 8. 部署（使用者自己做，回覆時要提醒）

- 覆蓋 `TF2/EQ_NPW_all_dashboard.aspx`、`.aspx.cs`，動到設定才覆蓋 `web.config`。
- 應用程式集區帳號需可寫 `TF2/emst_data/`、`TF2/cache/`（會自動建立）。
- `hiddenSegments` 已擋 `emst_data`、`cache`，不可直接下載。
- 改了檔名時提醒舊網址會 404；`WaferMatch.html`、`TF2api/` 不需搬動。
- 若 `.cs` 有改：提醒「這裡沒有編譯器，部署後請開頁確認」。

---

## 9. 溝通慣例

- 使用者用**繁體中文**，回覆也用繁體中文；技術名詞（CHART_SEQ、UCL、Port…）保留英文。
- 每次改動：說明原因、改了什麼、怎麼驗證、要部署哪些檔；commit 後 `git push -u origin <branch>`（失敗以 2/4/8/16 秒退避重試）。
- 使用者常給截圖或 DB 畫面；看不清楚就放大切片再判讀，判斷有不確定時明講並附可自行驗證的 SQL。
- 「先討論先不做」= 只給方案與取捨，不動程式；確認後再做。
