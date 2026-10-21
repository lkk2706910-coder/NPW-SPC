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

1. **條件式搜尋**：Chart_ID（精確）、Chart_name（包含）、機台 PROCESSUNIT（包含）、時間區間（依 **DataDate** 文字欄位，格式 `yyyy-mm-dd`，以 `TRY_CONVERT(datetime, DataDate, 120)` 轉換後比較；結束日含當天，最長 400 天；有近 7 / 30 / 90 天快捷鍵）。
2. **搜尋結果**顯示在搜尋區下方，每張 chart **只一列**：N（筆數）、AVG（MEAN_VALUE 平均）、STDEVA（樣本標準差，= Excel STDEV.S / STDEVA；區間內所有 MEAN_VALUE 都納入）、Min / Max、首筆 / 末筆時間；「明細」可展開區間內每一筆 MEAN_VALUE 並由前端重算 AVG / STDEVA 對照。
3. **加入檢定表**：按結果列的「加入檢定」，對**同一張 chart** 指定 **BSL 區間** 與 **wafer extend 區間**，選擇編號後「填入」：兩個區間各自算 N / AVG / STDEVA，分別寫進該編號的 BSL（X1、σ1）與 wafer extend（X2、σ2）列；PU 由使用者自行填寫，格內註記 CHART_ID、機台與區間。
4. **檢定表（PCRB）**：最前面多一欄「編號」，每個編號兩列（BSL / wafer extend）；可新增編號、刪除、全部清除；X / σ 仍可手動修改。
5. **檢定結果**：沿用檢定機器人公式 `/X2-X1//σ1`（≦1 → Y）、`σ2^2/σ1^2`（<2 → Y），兩者皆 Y 顯示 **PASS**，否則 **FAIL**；上方有 PASS / FAIL 統計；「複製檢定表」輸出 TSV 可直接貼進 Excel。內容自動保存在瀏覽器（localStorage）。

## 端點

| op | 參數 | 回傳 |
|---|---|---|
| `search` | `start`, `end`, `cid`, `cname`, `pu` | `rows[]`：CHART_ID, CHART_NAME, PROCESSUNIT, CHART_TYPE, N, AVG, STDEV, MIN, MAX, FIRST_TIME, LAST_TIME；`truncated` |
| `values` | `cid`, `start`, `end` | `rows[]`：d, seq, mean, lot, wafer, pu |

## 部署

把 `TF2/` 三個檔放到 IIS 站台（可與 NPW alarm 頁同站台）；`web.config` 若該站台已有則只需確認 `EMST` 連線字串存在。
`.aspx.cs` 必須維持純 ASCII（伺服器以 Big5 編譯）。
