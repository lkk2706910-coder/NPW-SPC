# NPW_inspection_tool

TF2 / T_EQ1 NPW **檢定工具**：以 NPW alarm control 網頁的架構（ASP.NET WebForms 單頁 + `?op=` JSON 端點，
資料來源 `GPTDB_USPC.dbo.TF2_NPW_CHART`）實作的 PCRB 檢定頁面，取代原本靠 Excel 的 `檢定機器人.html`。

## 檔案

```
TF2/
  NPW_inspection_tool.aspx      頁面：搜尋條件、搜尋結果、檢定表（PCRB）
  NPW_inspection_tool.aspx.cs   code-behind：?op=search / ?op=values（純 ASCII）
  web.config                    連線字串（EMST）與 UTF-8 設定
檢定機器人.html                  原始參考（Excel 版），公式與版面沿用
```

## 功能

1. **條件式搜尋**：Chart_ID（精確）、Chart_name / 機台 PROCESSUNIT（不含 `%` 時為「包含」比對；可自行用 `%` 當萬用字元，如 `SACVD-B1%`、`%5.5K%PA%`；`_` 視為一般字元）、**PROD Type**（內控 = 所有 MONITOR_TYPE；OCAP = MONITOR_TYPE 為 NORMAL 或 PM）、時間區間（依 **UPDATE_TIME**，開始／結束都可選到幾點幾分，結束時間含該分鐘；最長 400 天；有近 7 / 30 / 90 天快捷鍵）。
2. **搜尋結果**顯示在搜尋區下方，每張 chart **只一列**：N（筆數）、AVG（MEAN_VALUE 平均）、STDEVA（樣本標準差，= Excel STDEV.S / STDEVA；區間內所有 MEAN_VALUE 都納入）、Min / Max、首筆 / 末筆時間；「明細」可展開區間內每一筆 MEAN_VALUE，**每一點可「刪除」（排除）**，前端立即重算 N / AVG / STDEVA 並回寫到該列（標示原筆數與排除點數，可「還原」或「全部還原」）；重新搜尋會清掉排除狀態。
   - **看 chart**：在該列下方展開 Chart.js 趨勢圖（MEAN_VALUE + UCL / LCL / XBAR），被排除的點以灰色空心顯示並即時同步。
   - **＋matching**：把該 chart（本次搜尋區間、含目前排除狀態的快照）加入下方「Matching chart」卡片；已加入的按鈕變綠色「已加入（再按移除）」，再按一次即移除；搜尋結果右上角「全部加入 matching」可一鍵加入全部結果。多條序列像 SPC 多 chart 檢視一樣**左右分開依序排列**在同一張圖，序列之間有垂直分隔線，每段上方標示 chamber（含 S1/S2）；**Spec（UCL / CL / LCL）預設取第一條加入的 chart**（找不到 UCL/LCL 時自動往後找），可用「Spec 來源」下拉改選；也可切成「時間」軸疊圖；下方附每條序列的 N / AVG / STDEVA / Min / Max；「清空 matching」清除全部。
   - **檢定區間**（Matching chart 卡片右上角開關）：開啟後每條序列可「＋BSL 區間」（綠色透明方框）與「＋檢定區間」（紅色透明方框），直接在圖上**拖拉方框左右邊界**調整範圍或**拖拉方框中間**平移；方框上與下方表格即時顯示該區間的點數、N / AVG / STDEVA 與起迄時間；選好組別按「帶入」，BSL 區間寫進該組奇數列（X1、σ1）、檢定區間寫進偶數列（X2、σ2），可選「＋新增一組」。只在「依序排列」模式可操作。
3. **加入檢定表**：每筆搜尋結果右側有「加入檢定」按鈕與**列編號下拉**；選好列編號按下去，就把該 chart 在**本次搜尋區間**的 N / AVG / STDEVA（若明細內有排除點，則用排除後的重算值，註記會標示排除點數）寫進那一列（X、σ、N），下拉自動跳到下一列；要用另一個區間（如 BSL 與 wafer extend 各一段）就改上方日期重新搜尋再加入。PU 由使用者自行填寫，格內註記 CHART_ID、機台與區間。
4. **檢定表（PCRB）**：最前面多一欄「編號」，**每列一個編號**：奇數列 BSL（X1、σ1）、偶數列 wafer extend（X2、σ2），1-2、3-4… 相鄰兩列一組做檢定；每列有獨立「刪除」（清空該列內容，編號與配對不變）；可新增一組、全部清除；X / σ 仍可手動修改（來源 CHART_ID 與區間放在 PU 欄的滑鼠提示）。
5. **檢定結果**：沿用檢定機器人公式 `/X2-X1//σ1`（≦1 → Y）、`σ2^2/σ1^2`（<2 → Y），兩者皆 Y 顯示 **PASS**，否則 **FAIL**；上方有 PASS / FAIL 統計；「複製檢定表」輸出 TSV 可直接貼進 Excel。內容自動保存在瀏覽器（localStorage）。

## 端點

| op | 參數 | 回傳 |
|---|---|---|
| `search` | `start`, `end`（`yyyy-MM-ddTHH:mm`）, `prod`(ctrl/ocap), `cid`, `cname`, `pu` | `rows[]`：CHART_ID, CHART_NAME, PROCESSUNIT, CHART_TYPE, N, AVG, STDEV, MIN, MAX, FIRST_TIME, LAST_TIME；`truncated` |
| `values` | `cid`, `start`, `end`, `prod` | `rows[]`：d, seq, mean, lot, wafer, pu, ucl, lcl, xbar |

趨勢圖 / Matching chart 使用 Chart.js（CDN `cdn.jsdelivr.net`，與 alarm dashboard 相同）。

## 部署

與 NPW alarm 頁**同一個 IIS 站台**：只把 `TF2/NPW_inspection_tool.aspx` 與 `TF2/NPW_inspection_tool.aspx.cs` 放進站台的 `TF2/` 即可，
**不要覆蓋站台既有的 `web.config`**（alarm 頁的 AI 設定在裡面；這個 repo 的 `TF2/web.config` 只是單獨部署時用的最小版本，僅含 `EMST` 連線字串）。
`.aspx.cs` 必須維持純 ASCII（伺服器以 Big5 編譯）。

UPDATE_TIME 為 NULL 的列不會被納入（不計 N / AVG / STDEVA）。
