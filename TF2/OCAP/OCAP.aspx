<%@ Page Language="C#" AutoEventWireup="true" CodeFile="OCAP.aspx.cs" Inherits="OCAP" EnableSessionState="false" %>
<!DOCTYPE html>
<html lang="zh-Hant">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>OCAP</title>
<!-- Trend chart 用 Chart.js（與 NPW 網站相同版本） -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.3.0/dist/chart.umd.min.js"></script>
<style>
/* ===== 基礎 ===== */
* { box-sizing: border-box; }
/* 有 hidden 屬性的元素一律不顯示：下面有些容器設了 display:flex，會蓋掉瀏覽器對 [hidden] 的預設 */
[hidden] { display: none !important; }
body {
  margin: 0;
  font-family: "Microsoft JhengHei", "Segoe UI", Arial, sans-serif;
  background: #f3f5f9;
  color: #26303d;
  font-size: 14px;
  line-height: 1.6;
}

/* ===== 頁首 ===== */
header {
  background: linear-gradient(135deg, #1e88e5, #1565c0);
  color: #fff;
  padding: 16px 28px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 8px;
  box-shadow: 0 8px 24px rgba(2, 6, 23, .16);
}
header h1 { margin: 0; font-size: 20px; letter-spacing: 1px; font-weight: 600; }
header .meta { font-size: 12px; opacity: .9; }

/* ===== 版面 ===== */
.page { max-width: 1400px; margin: 20px auto 40px; padding: 0 18px; }
.panel {
  background: #fff;
  border: 1px solid #e3e8ef;
  border-radius: 10px;
  padding: 18px;
  margin-bottom: 18px;
  box-shadow: 0 2px 8px rgba(2, 6, 23, .04);
}
.panel h2 {
  margin: 0 0 14px;
  font-size: 15px;
  font-weight: 600;
  padding-bottom: 10px;
  border-bottom: 1px solid #eef1f6;
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

/* ===== 工具列 ===== */
.toolbar { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
.toolbar label { font-size: 13px; color: #5a6675; }
input[type="date"] {
  font: inherit;
  padding: 6px 10px;
  border: 1px solid #cfd7e3;
  border-radius: 6px;
}
input[type="date"]:focus { outline: none; border-color: #1e88e5; box-shadow: 0 0 0 3px rgba(30, 136, 229, .12); }
button {
  font: inherit;
  padding: 7px 18px;
  border: 0;
  border-radius: 6px;
  background: #1e88e5;
  color: #fff;
  cursor: pointer;
}
button:hover { background: #1669c1; }
button:disabled { background: #a9bed4; cursor: not-allowed; }
button.ghost {
  background: #fff;
  color: #1e88e5;
  border: 1px solid #cfd7e3;
  padding: 6px 12px;
}
button.ghost:hover { background: #f0f6fd; }

/* ===== 狀態訊息 ===== */
.status { font-size: 13px; color: #6b7684; }
.status.error { color: #c62828; }
.status.ok { color: #2e7d32; }
.status.warn { color: #b26a00; }

/* ===== 摘要 ===== */
.summary { display: flex; gap: 24px; flex-wrap: wrap; margin-top: 12px; font-size: 13px; color: #5a6675; }
.summary b { color: #26303d; font-size: 16px; margin-right: 4px; }

/* ===== Section ===== */
.section h2 .dept { font-family: Consolas, "Courier New", monospace; font-size: 14px; color: #1565c0; }
.badge {
  font-size: 12px;
  font-weight: 500;
  color: #45505f;
  background: #eef3fa;
  border-radius: 999px;
  padding: 2px 10px;
}
.badge.hint { background: #fff4d6; color: #8a5a00; }

/* ===== 表格 ===== */
.table-wrap { overflow-x: auto; }
table { border-collapse: collapse; width: 100%; font-size: 13px; }
th, td {
  border-bottom: 1px solid #eef1f6;
  padding: 8px 12px;
  text-align: left;
  white-space: nowrap;
}
th { background: #f7f9fc; font-weight: 600; color: #45505f; position: sticky; top: 0; }
tbody tr:hover { background: #f7fbff; }
td.chart { font-weight: 600; color: #26303d; }
td.first-of-chart { border-top: 2px solid #e3e8ef; }
td.empty { text-align: center; color: #98a2b3; padding: 28px; white-space: normal; }
td.blank { height: 56px; }                 /* 沒資料的 section：留一段空白，版面不塌 */
.section.is-empty h2 .dept { color: #8a96a8; }
.section.is-empty .badge { color: #98a2b3; background: #f3f5f9; }

/* 可點擊的 CHART_NAME（目前只有 T_EQ1） */
a.chart-link { color: #1565c0; text-decoration: none; border-bottom: 1px dashed #9cc0ea; cursor: pointer; }
a.chart-link:hover { color: #0d47a1; border-bottom-style: solid; }

/* ===== 明細視窗 ===== */
.modal-backdrop {
  position: fixed; inset: 0; z-index: 1000;
  background: rgba(15, 23, 42, .55);
  display: flex; align-items: flex-start; justify-content: center;
  padding: 24px 16px; overflow: auto;
}
.modal {
  background: #fff; border-radius: 12px; width: 100%; max-width: 1400px;
  box-shadow: 0 24px 64px rgba(2, 6, 23, .35);
  overflow: hidden;
}
.modal-head {
  display: flex; align-items: center; justify-content: space-between; gap: 12px;
  padding: 12px 18px; background: linear-gradient(135deg, #1e88e5, #1565c0); color: #fff;
}
.modal-head h3 { margin: 0; font-size: 16px; font-weight: 600; word-break: break-all; }
.modal-head .sub { font-size: 12px; opacity: .9; }
.modal-head .block {
  display: inline-block; font-size: 11px; font-weight: 700; letter-spacing: .5px;
  padding: 1px 8px; border-radius: 999px; margin-right: 8px; vertical-align: middle;
  background: rgba(255,255,255,.22); color: #fff;
}
.modal-head .block.non-adder { background: #ffd54f; color: #4a3200; }
.modal-close {
  background: transparent; border: 0; color: #fff; font-size: 26px; line-height: 1;
  padding: 0 4px; cursor: pointer;
}
.modal-close:hover { background: rgba(255,255,255,.15); }
.modal-body { padding: 16px 18px 20px; }

.info-grid {
  display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 10px 18px; margin-bottom: 16px;
}
.info-grid .k { font-size: 11px; color: #6b7684; letter-spacing: .3px; }
.info-grid .v { font-size: 13px; color: #26303d; word-break: break-all; min-height: 20px; }
.info-grid .v.pending { color: #98a2b3; }
.info-grid .wide { grid-column: span 2; }
.wc-line { display: flex; gap: 8px; align-items: baseline; font-size: 12px; white-space: nowrap; }
.wc-line .wc-eq { font-family: Consolas, "Courier New", monospace; color: #45505f; min-width: 128px; }
.wc-line .wc-meter { color: #6b7684; min-width: 120px; }
.wc-line .wc-val { font-weight: 600; }
.wc-line .wc-spec { color: #6b7684; }
.wc-line.hit .wc-eq { color: #1565c0; font-weight: 600; }   /* 該筆 chart 經過的 chamber */
.wc-line.over .wc-val { color: #c62828; }                    /* 已達或超過 SPEC */
.wc-note { font-size: 11px; color: #98a2b3; margin-top: 4px; }

.detail-grid {
  display: grid; grid-template-columns: minmax(0, 1.5fr) minmax(0, 1fr) minmax(0, 1fr);
  gap: 14px;
}
.detail-grid.non-adder { grid-template-columns: minmax(0, 1.5fr) minmax(0, 1fr); }
/* 有對位置卡片時多一欄 */
.detail-grid.with-wm { grid-template-columns: minmax(0, 1.4fr) minmax(0, 1fr) minmax(0, 1fr) minmax(0, 1fr); }
.detail-grid.non-adder.with-wm { grid-template-columns: minmax(0, 1.4fr) minmax(0, 1fr) minmax(0, 1fr); }
@media (max-width: 1100px) { .detail-grid.with-wm, .detail-grid.non-adder.with-wm { grid-template-columns: 1fr 1fr; } }
@media (max-width: 960px) { .detail-grid, .detail-grid.non-adder, .detail-grid.with-wm, .detail-grid.non-adder.with-wm { grid-template-columns: 1fr; } }

/* 內嵌的對位置圖：WaferMatch.html?embed=1，畫面是 600x850 直式 */
.wm-inline { width: 100%; aspect-ratio: 600 / 850; border: 1px solid #e3e8ef; border-radius: 8px; background: #fafbfd; display: block; }
.wm-inline.blank { display: none; }
.card {
  border: 1px solid #e3e8ef; border-radius: 10px; padding: 12px; background: #fff;
  display: flex; flex-direction: column; min-width: 0;
}
.card h4 {
  margin: 0 0 8px; font-size: 13px; font-weight: 600; color: #45505f;
  display: flex; align-items: center; justify-content: space-between; gap: 8px;
}
.card h4 small { font-weight: 400; color: #98a2b3; font-size: 11px; }
.spark { position: relative; width: 100%; height: 320px; }
.spark canvas { display: block; width: 100% !important; height: 100% !important; }
.map-box {
  display: flex; align-items: center; justify-content: center;
  min-height: 320px; background: #fafbfd; border: 1px dashed #dfe5ee; border-radius: 8px;
  color: #98a2b3; font-size: 13px; text-align: center; padding: 8px;
}
.map-box img {
  max-width: 100%; max-height: 420px; display: block; border: 1px solid #cfd7e3; background: #fff;
}
.map-box a { display: block; }
.map-box a.zoom img { cursor: zoom-in; }
.map-box a.wm img { cursor: crosshair; }
.map-hint { font-size: 11px; color: #98a2b3; margin-top: 6px; text-align: center; }
/* EMST 填寫區塊 */
.emst { margin-top: 14px; }
.emst-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px 14px; }
@media (max-width: 960px) { .emst-grid { grid-template-columns: 1fr; } }
.emst-grid label { display: flex; flex-direction: column; gap: 4px; font-size: 12px; color: #6b7684; }
.emst-grid label.full { grid-column: 1 / -1; }
.emst-grid input, .emst-grid textarea {
  font: inherit; font-size: 13px; padding: 7px 10px;
  border: 1px solid #cfd7e3; border-radius: 6px; color: #26303d; background: #fff;
}
.emst-grid textarea { resize: vertical; min-height: 64px; }
.emst-grid input:focus, .emst-grid textarea:focus { outline: none; border-color: #1e88e5; box-shadow: 0 0 0 3px rgba(30,136,229,.12); }
.emst-actions { display: flex; align-items: center; gap: 10px; margin-top: 10px; flex-wrap: wrap; }
.emst-actions .status { margin-left: auto; }

/* ===== 對角度（Wafer Match）視窗：沿用 NPW 網站 ===== */
#wmatchModal {
  display: none; position: fixed; z-index: 1200; inset: 0; background: rgba(0,0,0,.6);
}
#wmatchModal .wm-box {
  position: absolute; left: 50%; top: 50%; transform: translate(-50%, -50%);
  width: 96vw; height: 92vh; background: #fff; border-radius: 10px;
  box-shadow: 0 20px 60px rgba(0,0,0,.4); overflow: hidden;
}
#wmatchModal .wm-head {
  display: flex; align-items: center; justify-content: space-between;
  padding: 8px 14px; background: #1976d2; color: #fff; font-weight: 700; font-size: 14px;
}
#wmatchModal .wm-head span:last-child { cursor: pointer; font-size: 24px; line-height: 1; }
#wmatchFrame { border: 0; width: 100%; height: calc(100% - 40px); }
</style>
</head>
<body>

<header>
  <h1>OCAP</h1>
  <div class="meta" id="page-meta">—</div>
</header>

<div class="page">

  <!-- 查詢條件：選日期，依 CREATE_TIME 抓當天資料 -->
  <section class="panel">
    <h2>OCAP 每日資料</h2>
    <div class="toolbar">
      <label for="date">日期（CREATE_TIME）</label>
      <button type="button" class="ghost" id="btn-prev" title="前一天">◀</button>
      <input type="date" id="date">
      <button type="button" class="ghost" id="btn-next" title="後一天">▶</button>
      <button type="button" id="btn-search">查詢</button>
      <span class="status" id="query-status"></span>
    </div>
    <div class="summary" id="summary" hidden>
      <span><b id="sum-rows">0</b>筆</span>
      <span><b id="sum-sections">0</b>個 section 有資料</span>
      <span><b id="sum-charts">0</b>個 CHART_NAME</span>
      <span id="sum-dept"></span>
    </div>
  </section>

  <!-- 固定的 T_EQ1/2/3 三個 section 由 JS 產生在這裡，沒資料也會保留空白區塊 -->
  <div id="sections"></div>

</div>

<!-- ============================================================
     明細視窗：點 T_EQ1 的 CHART_NAME 開啟
     Port / Trend chart / PRE_Map / ADDER_Map / Measure_Tool，沿用 NPW 網站的資料來源
     ============================================================ -->
<div class="modal-backdrop" id="detail-modal" hidden>
  <div class="modal" role="dialog" aria-modal="true" aria-labelledby="d-title">
    <div class="modal-head">
      <div>
        <h3><span class="block" id="d-block">ADDER</span><span id="d-title">—</span></h3>
        <div class="sub" id="d-subtitle"></div>
        <div class="sub" id="d-timing"></div>
      </div>
      <button type="button" class="modal-close" id="d-close" title="關閉" aria-label="關閉">&times;</button>
    </div>
    <div class="modal-body">

      <div class="info-grid">
        <div><div class="k">Tool_name</div><div class="v" id="d-tool">—</div></div>
        <div><div class="k">Port</div><div class="v pending" id="d-port">載入中…</div></div>
        <div><div class="k">Measure_Tool</div><div class="v pending" id="d-measure">載入中…</div></div>
        <div><div class="k">CHART_ID / SEQ</div><div class="v" id="d-ids">—</div></div>
        <div><div class="k">LOT</div><div class="v" id="d-lot">—</div></div>
        <div><div class="k">WAFER</div><div class="v pending" id="d-wafer">—</div></div>
        <div><div class="k">RECIPE</div><div class="v" id="d-recipe">—</div></div>
        <div><div class="k">PARAMETER</div><div class="v" id="d-parameter">—</div></div>
        <div><div class="k">STATUS</div><div class="v" id="d-status">—</div></div>
        <div><div class="k">CREATE_TIME</div><div class="v" id="d-create">—</div></div>
        <div><div class="k">MEAN_VALUE</div><div class="v pending" id="d-mean">—</div></div>
        <div><div class="k">CHART_OWNER</div><div class="v" id="d-owner">—</div></div>
        <div class="wide"><div class="k">Wafer count（PM 後累計 / SPEC；RECIPE 含 XFER 或 Tool_name 無 chamber 尾碼看 MF，否則看 chamber）</div><div class="v pending" id="d-wafercount">載入中…</div></div>
      </div>

      <!-- ADDER：Trend + PRE_Map + ADDER_Map；NON-ADDER（-U% / -RANGE）：Trend + Profile -->
      <div class="detail-grid" id="d-grid">
        <div class="card">
          <h4>Trend_Chart <small id="d-trend-range"></small></h4>
          <div class="spark"><canvas id="d-spark"></canvas></div>
          <div class="map-hint" id="d-trend-status"></div>
        </div>
        <div class="card" id="d-card-premap">
          <h4>PRE_Map</h4>
          <div class="map-box" id="d-premap">載入中…</div>
        </div>
        <div class="card" id="d-card-addermap">
          <h4>ADDER_Map <small class="wm-hint">點擊可對角度</small></h4>
          <div class="map-box" id="d-addermap">載入中…</div>
        </div>
        <div class="card" id="d-card-profile" hidden>
          <h4>Profile <small class="wm-hint">點擊可對角度</small></h4>
          <div class="map-box" id="d-profile">載入中…</div>
        </div>
        <!-- 對位置直接嵌在頁面裡（T_EQ1）；點圖或點 ADDER_Map / Profile 都會開完整視窗 -->
        <div class="card" id="d-card-wm" hidden>
          <h4>對位置 <small id="d-wm-title">點擊可放大</small></h4>
          <iframe class="wm-inline blank" id="d-wm-frame" title="Wafer Match（內嵌）" src="about:blank"></iframe>
          <div class="map-box" id="d-wm-placeholder">等待 Map 載入…</div>
        </div>
      </div>

      <!-- EMST 填寫：1/2 依規則預填，3/4 使用者手填；儲存到 TF2api/EmstNote.ashx（一筆 OCAP 一個 JSON） -->
      <div class="card emst">
        <h4>EMST 填寫 <small id="emst-meta"></small></h4>
        <div class="emst-grid">
          <label>1. Tool<input type="text" id="emst-tool" autocomplete="off"></label>
          <label>2. Wafer count<input type="text" id="emst-wc" autocomplete="off"></label>
          <label class="full">3. Action<textarea id="emst-action" rows="3" placeholder="使用者填寫"></textarea></label>
          <label class="full">4. Follow up<textarea id="emst-followup" rows="3" placeholder="使用者填寫"></textarea></label>
        </div>
        <div class="emst-actions">
          <button type="button" id="emst-save">儲存</button>
          <button type="button" class="ghost" id="emst-copy">複製公版文字</button>
          <span class="status" id="emst-status"></span>
        </div>
      </div>

    </div>
  </div>
</div>

<!-- 對角度（Wafer Match）：點 ADDER_Map 時彈窗，iframe 載入 WaferMatch.html -->
<div id="wmatchModal">
  <div class="wm-box">
    <div class="wm-head">
      <span id="wmatchTitle">對角度 · Wafer Match</span>
      <span id="wmatchClose" title="關閉">&times;</span>
    </div>
    <iframe id="wmatchFrame" title="Wafer Match Tool" src="about:blank"></iframe>
  </div>
</div>

<script>
// 資料 API 指回本頁自己：帶 ?action= 時 code-behind 回傳 JSON
var API_URL = location.pathname;

// 固定顯示的 section 與順序，由 code-behind 的 Sections 常數帶進來
var SECTIONS = <%= SectionsJson %>;

// 三個 section 都可以點 CHART_NAME 看明細
var DETAIL_SECTIONS = SECTIONS.slice();

// 對角度（Wafer Match）目前只開 T_EQ1；其他 section 的 ADDER_Map / Profile 只顯示圖、不能點
var WM_SECTIONS = SECTIONS.slice(0, 1);

// Wafer count 目前只抓 T_EQ1 / T_EQ2；T_EQ3 先顯示欄位不抓資料
var WAFER_COUNT_SECTIONS = SECTIONS.slice(0, 2);

// PRE/ADDER Map 與 MeasurePU 代理（沿用 NPW 網站的 handler，路徑相對於本頁）
var MAP_PROXY = 'TF2api/SpcMapInfoProxy.ashx';

// Trend chart 往前抓幾天
var TREND_DAYS = 60;

// EMST 填寫內容的儲存 handler（路徑相對於本頁）
var EMST_NOTE_URL = 'TF2api/EmstNote.ashx';

// WaferMatch.html 的版本號：加在網址上讓瀏覽器不會拿到舊快取。每次改 WaferMatch.html 就把數字加 1
var WM_VERSION = '2';

// 每個 section 底下要顯示的欄位（CHART_NAME 固定放第一欄）
var COLUMNS = [
  { key: 'CHART_NAME',     label: 'CHART_NAME' },
  { key: 'CREATE_TIME',    label: 'CREATE_TIME' },
  { key: 'STATUS',         label: 'STATUS' },
  { key: 'PARAMETER',      label: 'PARAMETER' },
  { key: 'PROCESSINGUNIT', label: 'PROCESSINGUNIT' },
  { key: 'RECIPE',         label: 'RECIPE' },
  { key: 'LOT',            label: 'LOT' },
  { key: 'CHART_OWNER',    label: 'CHART_OWNER' }
];

function $(id) { return document.getElementById(id); }

function setStatus(el, text, kind) {
  el.textContent = text;
  el.className = 'status' + (kind ? ' ' + kind : '');
}

function escapeHtml(s) {
  return String(s == null ? '' : s)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

function pad2(n) { return n < 10 ? '0' + n : '' + n; }

function fmtMs(ms) {
  if (ms == null || ms === '') return '—';
  ms = Number(ms);
  if (!isFinite(ms)) return '—';
  return ms >= 1000 ? (ms / 1000).toFixed(1) + ' s' : Math.round(ms) + ' ms';
}

// 本地日期 → yyyy-MM-dd（避免 toISOString 因時區跳到前一天）
function toDateString(d) {
  return d.getFullYear() + '-' + pad2(d.getMonth() + 1) + '-' + pad2(d.getDate());
}

function shiftDate(days) {
  var parts = $('date').value.split('-');
  if (parts.length !== 3) return;
  var d = new Date(+parts[0], +parts[1] - 1, +parts[2]);
  d.setDate(d.getDate() + days);
  $('date').value = toDateString(d);
  search();
}

// 呼叫本頁的 JSON API；後端錯誤會轉成例外丟出
function callApi(action, params) {
  var qs = 'action=' + encodeURIComponent(action);
  for (var key in (params || {})) {
    if (params[key] !== '' && params[key] != null) {
      qs += '&' + encodeURIComponent(key) + '=' + encodeURIComponent(params[key]);
    }
  }
  qs += '&_=' + Date.now();  // 避開瀏覽器快取

  return fetch(API_URL + '?' + qs, { method: 'GET' })
    .then(function (res) {
      return res.json().catch(function () {
        throw new Error('HTTP ' + res.status + '：回應不是 JSON');
      }).then(function (data) {
        if (!res.ok || data.error) throw new Error(data.error || ('HTTP ' + res.status));
        return data;
      });
    });
}

// ===== 每日清單 =====

// 把 rows 依 OWNERDEPT 放進固定的 section 清單；後端已照 OWNERDEPT、CHART_NAME、CREATE_TIME 排好序
function groupBySection(sectionNames, rows) {
  var byDept = {};
  var sections = sectionNames.map(function (dept) {
    byDept[dept] = { dept: dept, rows: [], charts: {} };
    return byDept[dept];
  });
  rows.forEach(function (row) {
    var section = byDept[row.OWNERDEPT];
    if (!section) return;  // 後端只回固定 section 的資料，這裡只是保險
    section.rows.push(row);
    section.charts[row.CHART_NAME || ''] = true;
  });
  return sections;
}

function renderSectionTable(section) {
  var detailEnabled = DETAIL_SECTIONS.indexOf(section.dept) >= 0;

  var table = document.createElement('table');
  var thead = document.createElement('thead');
  var headRow = document.createElement('tr');
  COLUMNS.forEach(function (col) {
    var th = document.createElement('th');
    th.textContent = col.label;
    headRow.appendChild(th);
  });
  thead.appendChild(headRow);
  table.appendChild(thead);

  var tbody = document.createElement('tbody');

  // 沒資料：保留表頭，下面留一段空白，版面固定不變
  if (section.rows.length === 0) {
    var blankRow = document.createElement('tr');
    var blankCell = document.createElement('td');
    blankCell.className = 'blank';
    blankCell.colSpan = COLUMNS.length;
    blankRow.appendChild(blankCell);
    tbody.appendChild(blankRow);
    table.appendChild(tbody);
    return table;
  }

  var prevChart = null;
  section.rows.forEach(function (row) {
    var tr = document.createElement('tr');
    var isNewChart = row.CHART_NAME !== prevChart;
    COLUMNS.forEach(function (col) {
      var td = document.createElement('td');
      var value = row[col.key];
      var text = value == null ? '' : String(value);

      if (col.key === 'CHART_NAME') {
        td.className = 'chart';
        // T_EQ1：CHART_NAME 可點擊開明細；其他 section 維持純文字
        if (detailEnabled && row.UCHART_ID != null && row.CHART_SEQ != null) {
          var a = document.createElement('a');
          a.className = 'chart-link';
          a.href = 'javascript:void(0)';
          a.textContent = text;
          a.title = '點擊查看 Port / Trend chart / PRE_Map / ADDER_Map';
          a.addEventListener('click', function () { openDetail(row); });
          td.appendChild(a);
        } else {
          td.textContent = text;
        }
      } else {
        td.textContent = text;
      }

      // 同一個 CHART_NAME 連續多筆時，只在第一筆上方畫分隔線，一眼看出分組
      if (isNewChart && prevChart !== null) td.className += ' first-of-chart';
      tr.appendChild(td);
    });
    tbody.appendChild(tr);
    prevChart = row.CHART_NAME;
  });
  table.appendChild(tbody);
  return table;
}

// 固定畫出所有 section，順序照 SECTIONS；沒資料的加上 is-empty 淡化標題
function renderSections(sections) {
  var host = $('sections');
  host.innerHTML = '';

  sections.forEach(function (section) {
    var isEmpty = section.rows.length === 0;

    var panel = document.createElement('section');
    panel.className = 'panel section' + (isEmpty ? ' is-empty' : '');

    var h2 = document.createElement('h2');
    var dept = document.createElement('span');
    dept.className = 'dept';
    dept.textContent = section.dept;
    h2.appendChild(dept);

    var badge = document.createElement('span');
    badge.className = 'badge';
    badge.textContent = isEmpty
      ? '無資料'
      : section.rows.length + ' 筆 · ' + Object.keys(section.charts).length + ' 個 CHART_NAME';
    h2.appendChild(badge);

    if (DETAIL_SECTIONS.indexOf(section.dept) >= 0) {
      var hint = document.createElement('span');
      hint.className = 'badge hint';
      hint.textContent = WM_SECTIONS.indexOf(section.dept) >= 0 ? '點 CHART_NAME 看明細（含對角度）' : '點 CHART_NAME 看明細';
      h2.appendChild(hint);
    }
    panel.appendChild(h2);

    var wrap = document.createElement('div');
    wrap.className = 'table-wrap';
    wrap.appendChild(renderSectionTable(section));
    panel.appendChild(wrap);

    host.appendChild(panel);
  });
}

function renderSummary(data, sections) {
  var chartSet = {};
  data.rows.forEach(function (r) { chartSet[r.CHART_NAME || ''] = true; });
  var filled = sections.filter(function (s) { return s.rows.length > 0; }).length;

  $('sum-rows').textContent = data.rows.length;
  $('sum-sections').textContent = filled + ' / ' + sections.length;
  $('sum-charts').textContent = Object.keys(chartSet).length;
  $('sum-dept').textContent = '日期：' + data.date;
  $('summary').hidden = false;
}

function search() {
  var date = $('date').value;
  if (!date) {
    setStatus($('query-status'), '請先選日期', 'error');
    return;
  }

  var button = $('btn-search');
  button.disabled = true;
  setStatus($('query-status'), '查詢中…');
  var t0 = Date.now();

  callApi('ocap', { date: date })
    .then(function (data) {
      var sections = groupBySection(data.sections || SECTIONS, data.rows);
      renderSections(sections);
      renderSummary(data, sections);
      // 伺服器耗時 vs 總耗時：差距大表示慢在網路或 IIS，差距小表示慢在 DB
      var timing = '（伺服器 ' + fmtMs(data.elapsedMs) + ' / 總計 ' + fmtMs(Date.now() - t0) + '）';
      if (data.truncated) {
        setStatus($('query-status'), '資料超過上限，只顯示前 ' + data.rows.length + ' 筆 ' + timing, 'warn');
      } else {
        setStatus($('query-status'), '共 ' + data.rows.length + ' 筆 ' + timing, 'ok');
      }
    })
    .catch(function (err) {
      setStatus($('query-status'), '查詢失敗：' + err.message, 'error');
    })
    .then(function () { button.disabled = false; });
}

function ping() {
  callApi('ping')
    .then(function (data) {
      $('page-meta').textContent = data.server + ' / ' + data.database + ' · ' + data.time;
    })
    .catch(function (err) {
      $('page-meta').textContent = '連線失敗：' + err.message;
    });
}

// ===== 明細視窗 =====

var _detailSeq = 0;        // 防止快速切換時舊回應蓋掉新資料
var _sparkInstance = null; // 目前的 Chart.js 實例
var _currentDetail = null; // 目前明細（含 NPW 對應欄位），對角度時要用

function setText(id, value, pendingWhenEmpty) {
  var el = $(id);
  var text = value == null || String(value).trim() === '' ? '' : String(value);
  el.textContent = text || (pendingWhenEmpty ? '—' : '—');
  el.classList.remove('pending');
}

// MEASUREPU 顯示用：取 ^SP5^ 後面那段（如 KLA-Tencor^SP5^CUSFSCAN-B05 → CUSFSCAN-B05）；沿用 NPW
function parseMeasurePu(s) {
  if (s == null) return '';
  var str = String(s);
  var m = str.match(/\^SP5\^([^\^\s<]+)/i);
  if (m) return m[1];
  var i = str.lastIndexOf('^');
  return i >= 0 ? str.substring(i + 1) : str;
}

// NPW 的 NON-ADDER：CHART_NAME 含 U% 或 RANGE（與 NPW 的判定相同；後面可能還接 -[Partition Eng] 之類的尾綴）
function isNonAdderName(chartName) {
  return /U%|RANGE/i.test(String(chartName || ''));
}

// EMST 的 Tool 名稱：
//   ADDER     → Tool_name 原樣
//   NON-ADDER → Tool_name + RECIPE 最後一個 '-' 之後的尾碼（限 1~3 個英文字母），例如 SACVD-B06 + STIUSG5.5K_6.0-A → SACVD-B06A
//               Tool_name 本身已有 chamber 尾碼時不再加
function emstToolName(tool, recipe, block) {
  tool = String(tool || '').trim().toUpperCase();
  if (block !== 'N' || !tool) return tool;
  if (/^[A-Z0-9]+-[A-Z]\d{1,2}[A-Z]+$/.test(tool)) return tool;
  var r = String(recipe || '').trim();
  var i = r.lastIndexOf('-');
  if (i < 0) return tool;
  var suffix = r.substring(i + 1).trim().toUpperCase();
  if (!/^[A-Z]{1,3}$/.test(suffix)) return tool;
  return tool + suffix;
}

// Tool_name 欄位：NON-ADDER 且 EMST Tool 不同時，一併標出
function setToolCell(baseTool, emstTool) {
  var el = $('d-tool');
  el.classList.remove('pending');
  el.textContent = baseTool || '—';
  if (emstTool && emstTool !== String(baseTool || '').toUpperCase()) {
    el.textContent += '（EMST / wafer count 用 ' + emstTool + '）';
  }
}

// 給 EMST 公版用的 wafer count 字串：一筆就只給數字，多筆用「EQPID: 數字」分號串起
function waferCountSummary(rows) {
  if (!rows || !rows.length) return '';
  if (rows.length === 1) return fmtNum(rows[0].DATA_VAL);
  return rows.map(function (r) { return r.DISP_EQPID + ': ' + fmtNum(r.DATA_VAL); }).join('; ');
}

// SPC 系統 site：OXSE-A 系列在 12AP14，其餘 12AP58（沿用 NPW）
function siteOf(processUnit) {
  return String(processUnit || '').trim().toUpperCase().indexOf('OXSE-A') === 0 ? '12AP14' : '12AP58';
}

function openDetail(row) {
  var seq = ++_detailSeq;
  var block = isNonAdderName(row.CHART_NAME) ? 'N' : 'A';
  var wmEnabled = WM_SECTIONS.indexOf(row.OWNERDEPT) >= 0;
  _currentDetail = { row: row, npw: null, ports: [], block: block, wm: wmEnabled };

  // 不開對角度的 section 把「點擊可對角度」提示藏起來
  var hints = document.querySelectorAll('#detail-modal .wm-hint');
  for (var h = 0; h < hints.length; h++) hints[h].hidden = !wmEnabled;

  // ADDER 顯示 PRE_Map + ADDER_Map；NON-ADDER 顯示 Profile
  $('d-block').textContent = block === 'N' ? 'NON-ADDER' : 'ADDER';
  $('d-block').className = 'block' + (block === 'N' ? ' non-adder' : '');
  $('d-grid').className = 'detail-grid' + (block === 'N' ? ' non-adder' : '') + (wmEnabled ? ' with-wm' : '');
  $('d-card-premap').hidden = block === 'N';
  $('d-card-addermap').hidden = block === 'N';
  $('d-card-profile').hidden = block !== 'N';
  $('d-card-wm').hidden = !wmEnabled;
  _currentDetail.wmImg = null;
  wmResetInline();

  // 先用清單已有的資料填，等 API 回來再補
  $('d-title').textContent = row.CHART_NAME || '(無 CHART_NAME)';
  $('d-subtitle').textContent = (row.OWNERDEPT || '') + ' · ' + (row.CREATE_TIME || '');
  setText('d-tool', row.PROCESSINGUNIT);
  setText('d-ids', row.UCHART_ID + ' / ' + row.CHART_SEQ);
  setText('d-lot', row.LOT);
  setText('d-recipe', row.RECIPE);
  setText('d-parameter', row.PARAMETER);
  setText('d-status', row.STATUS);
  setText('d-create', row.CREATE_TIME);
  setText('d-owner', row.CHART_OWNER);

  ['d-port', 'd-measure', 'd-wafer', 'd-mean', 'd-wafercount'].forEach(function (id) {
    $(id).textContent = '載入中…';
    $(id).className = 'v pending';
  });
  var wcEnabled = WAFER_COUNT_SECTIONS.indexOf(row.OWNERDEPT) >= 0;
  _currentDetail.wc = wcEnabled;
  if (!wcEnabled) { $('d-wafercount').textContent = '—（此 section 尚未啟用）'; }
  $('d-premap').innerHTML = '載入中…';
  $('d-addermap').innerHTML = '載入中…';
  $('d-profile').innerHTML = '載入中…';
  $('d-trend-status').textContent = '載入中…';
  $('d-trend-range').textContent = '';
  emstReset(row, block);

  if (_sparkInstance) { try { _sparkInstance.destroy(); } catch (e) {} _sparkInstance = null; }

  $('detail-modal').hidden = false;
  document.body.style.overflow = 'hidden';

  var ids = { uchart_id: row.UCHART_ID, chart_seq: row.CHART_SEQ };
  var endDate = String(row.CREATE_TIME || '').substring(0, 10);

  // 各來源耗時（伺服器端 / 含網路），用來判斷慢在哪一段
  _currentDetail.timing = {};
  _currentDetail.markTiming = null;
  $('d-timing').textContent = '';
  var tStart = Date.now();
  function markTiming(name, data) {
    if (seq !== _detailSeq) return;
    _currentDetail.timing[name] = { server: data && data.elapsedMs, total: Date.now() - tStart };
    $('d-timing').textContent = '耗時：' + Object.keys(_currentDetail.timing).map(function (k) {
      var t = _currentDetail.timing[k];
      return k + ' ' + fmtMs(t.server) + '/' + fmtMs(t.total);
    }).join(' · ') + '（伺服器/含等待）';
  }
  _currentDetail.markTiming = markTiming;

  // 明細（含 NPW 對應欄位）→ 之後才知道 PointValue/site，再叫 Map 代理
  callApi('detail', ids)
    .then(function (data) {
      if (seq !== _detailSeq) return;
      markTiming('明細', data);
      var d = data.row || {};
      _currentDetail.npw = d;

      // NPW 的 PROCESSUNIT 比 OCAP 的 PROCESSINGUNIT 完整（含 chamber 字母），有就用它
      setText('d-wafer', d.WAFER);
      setText('d-mean', d.MEAN_VALUE);

      // EMST 用的 Tool：ADDER 直接用 Tool_name；NON-ADDER 用 Tool_name + RECIPE 最後一段尾碼（SACVD-B06 + …-A → SACVD-B06A）
      var baseTool = d.PROCESSUNIT || d.PROCESSINGUNIT || row.PROCESSINGUNIT || '';
      var recipe = d.RECIPE || row.RECIPE || '';
      _currentDetail.emstTool = emstToolName(baseTool, recipe, block);
      setToolCell(baseTool, _currentDetail.emstTool);
      emstSetTool(_currentDetail.emstTool);

      // Measure_Tool：OCAP 的 MEAS_EQUIPMENT 優先，其次 NPW 的 MEASUREPU，最後等 Map 代理
      var meas = d.MEAS_EQUIPMENT || parseMeasurePu(d.MEASUREPU);
      if (meas) setText('d-measure', meas);

      loadMaps(seq, d);
      // wafer count 也用 EMST Tool 查（NON-ADDER 會查到 RECIPE 尾碼那個 chamber）
      if (wcEnabled) loadWaferCount(seq, _currentDetail.emstTool, recipe);
      emstLoadSaved(seq);
    })
    .catch(function (err) {
      if (seq !== _detailSeq) return;
      $('d-premap').textContent = '明細載入失敗：' + err.message;
      $('d-profile').textContent = '明細載入失敗：' + err.message;
      $('d-addermap').textContent = '—';
      ['d-measure', 'd-wafer', 'd-mean'].forEach(function (id) { setText(id, ''); });
      // 明細失敗時退回用清單上的 PROCESSINGUNIT / RECIPE
      _currentDetail.emstTool = emstToolName(row.PROCESSINGUNIT || '', row.RECIPE || '', block);
      setToolCell(row.PROCESSINGUNIT || '', _currentDetail.emstTool);
      emstSetTool(_currentDetail.emstTool);
      if (wcEnabled) loadWaferCount(seq, _currentDetail.emstTool, row.RECIPE);
      emstLoadSaved(seq);
    });

  // Port（跨庫查詢較慢）與 Trend chart 不依賴明細，平行載入
  callApi('port', ids)
    .then(function (data) {
      if (seq !== _detailSeq) return;
      markTiming('Port', data);
      _currentDetail.ports = data.ports || [];
      setText('d-port', _currentDetail.ports.join(', '));
      wmRefreshInline();
    })
    .catch(function () {
      if (seq !== _detailSeq) return;
      setText('d-port', '');
    });

  callApi('chartdata', { cid: row.UCHART_ID, end: endDate, days: TREND_DAYS })
    .then(function (data) {
      if (seq !== _detailSeq) return;
      markTiming('Trend', data);
      var pts = data.series || [];
      $('d-trend-range').textContent = data.start + ' ~ ' + data.end + '（' + pts.length + ' 點）';
      if (!pts.length) { $('d-trend-status').textContent = '此區間沒有趨勢資料'; return; }
      $('d-trend-status').textContent = '';
      _sparkInstance = drawSpark($('d-spark'), pts, {
        block: block,
        uclLclPct: block === 'A' ? 0.10 : 0.01,
        alarmSeq: String(row.CHART_SEQ),
        alarmDay: endDate
      });
    })
    .catch(function (err) {
      if (seq !== _detailSeq) return;
      $('d-trend-status').textContent = 'Trend chart 載入失敗：' + err.message;
    });
}

// ===== EMST 填寫區塊 =====
// 狀態：_emst.saved = 已有儲存過的內容（此時預填不覆蓋 Tool / Wafer count）；
//       _emst.touched = 使用者已動過的欄位（自動預填不覆蓋使用者手打的值）
var _emst = { saved: false, touched: {} };

function emstReset(row, block) {
  _emst = { saved: false, touched: {} };
  $('emst-tool').value = String(row.PROCESSINGUNIT || '').toUpperCase();
  $('emst-wc').value = '';
  $('emst-action').value = '';
  $('emst-followup').value = '';
  $('emst-meta').textContent = block === 'N' ? 'NON-ADDER：Tool 取 Tool_name + RECIPE 尾碼' : 'ADDER：Tool 取 Tool_name';
  setStatus($('emst-status'), '');
  $('emst-save').disabled = false;
}

function emstSetTool(tool) {
  if (_emst.saved || _emst.touched.tool) return;
  $('emst-tool').value = tool || '';
}

function emstSetWaferCount(text) {
  if (_emst.saved || _emst.touched.wc) return;
  $('emst-wc').value = text || '';
}

// 讀已儲存的內容；有的話四個欄位都用儲存值
function emstLoadSaved(seq) {
  var row = _currentDetail && _currentDetail.row;
  if (!row) return;
  var url = EMST_NOTE_URL + '?uchart_id=' + encodeURIComponent(row.UCHART_ID) + '&chart_seq=' + encodeURIComponent(row.CHART_SEQ) + '&_=' + Date.now();
  fetch(url, { method: 'GET' })
    .then(function (res) { return res.json(); })
    .then(function (data) {
      if (seq !== _detailSeq) return;
      if (!data || !data.ok) throw new Error((data && data.error) || 'HTTP 錯誤');
      if (!data.exists || !data.note) { setStatus($('emst-status'), '尚未儲存'); return; }
      var n = data.note;
      _emst.saved = true;
      $('emst-tool').value = n.tool || '';
      $('emst-wc').value = n.waferCount || '';
      $('emst-action').value = n.action || '';
      $('emst-followup').value = n.followUp || '';
      setStatus($('emst-status'), '上次儲存：' + (n.updatedAt || ''), 'ok');
    })
    .catch(function (err) {
      if (seq !== _detailSeq) return;
      setStatus($('emst-status'), '讀取儲存內容失敗：' + err.message, 'error');
    });
}

function emstSave() {
  var row = _currentDetail && _currentDetail.row;
  if (!row) return;
  var seq = _detailSeq;
  var payload = {
    chart_name: row.CHART_NAME || '',
    block: _currentDetail.block === 'N' ? 'NON-ADDER' : 'ADDER',
    tool: $('emst-tool').value.trim(),
    waferCount: $('emst-wc').value.trim(),
    action: $('emst-action').value.trim(),
    followUp: $('emst-followup').value.trim()
  };
  var url = EMST_NOTE_URL + '?uchart_id=' + encodeURIComponent(row.UCHART_ID) + '&chart_seq=' + encodeURIComponent(row.CHART_SEQ);
  $('emst-save').disabled = true;
  setStatus($('emst-status'), '儲存中…');
  fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json; charset=utf-8' }, body: JSON.stringify(payload) })
    .then(function (res) { return res.json().then(function (d) { if (!res.ok || !d.ok) throw new Error(d.error || ('HTTP ' + res.status)); return d; }); })
    .then(function (data) {
      if (seq !== _detailSeq) return;
      _emst.saved = true;
      setStatus($('emst-status'), '已儲存：' + (data.note && data.note.updatedAt || ''), 'ok');
    })
    .catch(function (err) {
      if (seq !== _detailSeq) return;
      setStatus($('emst-status'), '儲存失敗：' + err.message, 'error');
    })
    .then(function () { if (seq === _detailSeq) $('emst-save').disabled = false; });
}

// 組成公版文字並複製到剪貼簿
function emstTemplateText() {
  return '1.Tool: ' + $('emst-tool').value.trim()
    + '\n2.Wafer count: ' + $('emst-wc').value.trim()
    + '\n3.Action: ' + $('emst-action').value.trim()
    + '\n4.Follow up: ' + $('emst-followup').value.trim();
}

function emstCopy() {
  var text = emstTemplateText();
  var done = function () { setStatus($('emst-status'), '已複製公版文字', 'ok'); };
  var fail = function () { setStatus($('emst-status'), '複製失敗，請手動選取', 'error'); };
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(text).then(done, function () { legacyCopy(text) ? done() : fail(); });
  } else {
    legacyCopy(text) ? done() : fail();
  }
}

function legacyCopy(text) {
  try {
    var ta = document.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed'; ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.select();
    var ok = document.execCommand('copy');
    document.body.removeChild(ta);
    return ok;
  } catch (e) { return false; }
}

// PRE_Map / ADDER_Map / MeasurePU：透過 SpcMapInfoProxy.ashx 抓 SPC 系統頁面（沿用 NPW）
// NON-ADDER 只用它補 Measure_Tool，圖改走 loadProfile
function loadMaps(seq, d) {
  var site = siteOf(d.PROCESSUNIT || d.PROCESSINGUNIT);
  var pv = d.MEAN_VALUE == null ? '' : String(d.MEAN_VALUE);
  var isNonAdder = _currentDetail && _currentDetail.block === 'N';
  if (isNonAdder) loadProfile(seq, d, site, pv);

  var url = MAP_PROXY
    + '?site=' + encodeURIComponent(site)
    + '&uchart_id=' + encodeURIComponent(d.UCHART_ID)
    + '&chart_seq=' + encodeURIComponent(d.CHART_SEQ)
    + '&PointValue=' + encodeURIComponent(pv !== '' ? pv : '10');

  fetch(url, { credentials: 'include' })
    .then(function (res) { return res.json(); })
    .then(function (p) {
      if (seq !== _detailSeq) return;
      if (!p || !p.ok) throw new Error((p && p.error) || 'proxy 回傳失敗');

      // Measure_Tool 若前面沒填到，用代理抓到的 MeasurePU
      if ($('d-measure').classList.contains('pending') || $('d-measure').textContent === '—') {
        setText('d-measure', p.measurePU ? parseMeasurePu(p.measurePU) : '');
      }

      if (isNonAdder) return;  // NON-ADDER 沒有 PRE/ADDER Map

      $('d-premap').innerHTML = p.preMapImgUrl
        ? mapThumbHtml(String(p.preMapImgUrl), 'PRE MAP')
        : '無 PRE_Map';

      if (p.adderMapImgUrl) {
        if (_currentDetail.wm) {
          _currentDetail.wmImg = String(p.adderMapImgUrl);
          wmRefreshInline();
          $('d-addermap').innerHTML = adderMapThumbHtml(String(p.adderMapImgUrl));
          $('d-addermap').querySelector('a.wm').addEventListener('click', function () {
            wmOpenFromMap(String(p.adderMapImgUrl));
          });
        } else {
          $('d-addermap').innerHTML = plainThumbHtml(String(p.adderMapImgUrl), 'ADDER MAP');
        }
      } else {
        $('d-addermap').textContent = '無 ADDER_Map';
        wmResetInline('無 ADDER_Map，無法對位置');
      }
    })
    .catch(function (err) {
      if (seq !== _detailSeq) return;
      if ($('d-measure').classList.contains('pending')) setText('d-measure', '');
      if (isNonAdder) return;
      $('d-premap').textContent = 'Map 載入失敗：' + err.message;
      $('d-addermap').textContent = '—';
    });
}

// RECIPE 含 XFER → 只看母機台（MF）；不含 → 只看 chamber
function waferCountScope(recipe) {
  return /XFER/i.test(String(recipe || '')) ? 'MF' : 'CHAMBER';
}

// Wafer count：依 Tool_name 拆 chamber，列出累計片數 / SPEC（沿用 wafer_count 網站規則）；範圍由 RECIPE 決定
function loadWaferCount(seq, tool, recipe) {
  if (!tool) { setText('d-wafercount', ''); return; }
  var scope = waferCountScope(recipe);
  callApi('wafercount', { tool: tool, scope: scope })
    .then(function (data) {
      if (seq !== _detailSeq) return;
      if (_currentDetail.markTiming) _currentDetail.markTiming('WaferCount', data);
      var el = $('d-wafercount');
      el.classList.remove('pending');
      if (!data.supported) { el.textContent = '—（無法解析 Tool_name：' + tool + '）'; return; }
      var finalScope = data.scope || scope;   // 後端可能因為沒有 chamber 字母而改成 MF
      var scopeText = finalScope === 'MF'
        ? (data.noSuffixAsMf ? 'MF，Tool_name 沒有 chamber 字母' : 'MF，RECIPE 含 XFER')
        : 'chamber';
      if (!data.rows || !data.rows.length) {
        el.textContent = '—（查無計數器資料，範圍：' + scopeText + '，查的是 ' + (data.mom || tool) + '）';
        return;
      }
      var notes = [];
      if (data.noSuffixAsMf) notes.push('Tool_name 沒有 chamber 字母，視為 MF');
      el.innerHTML = renderWaferCount(data) + (notes.length ? '<div class="wc-note">' + escapeHtml(notes.join('；')) + '</div>' : '');
      emstSetWaferCount(waferCountSummary(data.rows));
    })
    .catch(function (err) {
      if (seq !== _detailSeq) return;
      var el = $('d-wafercount');
      el.classList.remove('pending');
      el.textContent = '載入失敗：' + err.message;
    });
}

function fmtNum(v) {
  if (v == null || v === '') return '';
  var n = Number(String(v).replace(/,/g, ''));
  return isFinite(n) ? n.toLocaleString() : String(v);
}

// 一行一個計數器：EQPID · METERTYPE  現值 / SPEC；經過的 chamber 標藍、達 SPEC 標紅
function renderWaferCount(data) {
  var hit = {};
  (data.chambers || []).forEach(function (c) { hit[c] = true; });
  return data.rows.map(function (r) {
    var val = Number(String(r.DATA_VAL == null ? '' : r.DATA_VAL).replace(/,/g, ''));
    var spec = Number(String(r.SPEC_VAL == null ? '' : r.SPEC_VAL).replace(/,/g, ''));
    var over = isFinite(val) && isFinite(spec) && r.SPEC_VAL != null && r.SPEC_VAL !== '' && val >= spec;
    var cls = 'wc-line' + (hit[r.EQPID] ? ' hit' : '') + (over ? ' over' : '');
    return '<div class="' + cls + '">'
      + '<span class="wc-eq">' + escapeHtml(r.DISP_EQPID) + '</span>'
      + '<span class="wc-meter">' + escapeHtml(r.DISP_METERTYPE) + '</span>'
      + '<span class="wc-val">' + escapeHtml(fmtNum(r.DATA_VAL)) + '</span>'
      + '<span class="wc-spec">/ ' + (r.SPEC_VAL == null || r.SPEC_VAL === '' ? '—' : escapeHtml(fmtNum(r.SPEC_VAL))) + '</span>'
      + '</div>';
  }).join('');
}

// NON-ADDER Profile RAW 圖：後端 profileimg 抓 SPC 的 contour 頁，優先挑該 WAFER 的圖（沿用 NPW）
function loadProfile(seq, d, site, pv) {
  callApi('profileimg', {
    uchart_id: d.UCHART_ID, chart_seq: d.CHART_SEQ,
    pointValue: pv, site: site, wafer: d.WAFER == null ? '' : String(d.WAFER)
  })
    .then(function (p) {
      if (seq !== _detailSeq) return;
      if (!p.imgUrl) { $('d-profile').textContent = '無 Profile 圖'; wmResetInline('無 Profile 圖，無法對位置'); return; }
      if (_currentDetail.wm) {
        _currentDetail.wmImg = String(p.imgUrl);
        wmRefreshInline();
        $('d-profile').innerHTML = profileThumbHtml(String(p.imgUrl));
        $('d-profile').querySelector('a.wm').addEventListener('click', function () {
          wmOpenFromProfile(String(p.imgUrl));
        });
      } else {
        $('d-profile').innerHTML = plainThumbHtml(String(p.imgUrl), 'Profile RAW');
      }
    })
    .catch(function (err) {
      if (seq !== _detailSeq) return;
      $('d-profile').textContent = 'Profile 載入失敗：' + err.message;
    });
}

// PRE_Map：點擊以 openie: 協定用 IE 開原圖（沿用 NPW 的做法，SPC 系統圖頁需要 IE）
function mapThumbHtml(imgUrl, alt) {
  return '<a class="zoom" href="openie:' + encodeURIComponent(imgUrl) + '" target="_blank" rel="noopener noreferrer" title="Open ' + escapeHtml(alt) + ' (IE)">'
    + '<img src="' + escapeHtml(imgUrl) + '" alt="' + escapeHtml(alt) + '" loading="lazy"></a>';
}

// 只顯示圖、不可點（不開對角度的 section 用）
function plainThumbHtml(imgUrl, alt) {
  return '<img src="' + escapeHtml(imgUrl) + '" alt="' + escapeHtml(alt) + '" loading="lazy">';
}

// ADDER_Map：點擊開 Wafer Match 對角度
function adderMapThumbHtml(imgUrl) {
  return '<a class="wm" href="javascript:void(0)" title="點擊對角度（Wafer Match）">'
    + '<img src="' + escapeHtml(imgUrl) + '" alt="ADDER MAP" loading="lazy"></a>';
}

// Profile：點擊開 Wafer Match 對角度（side / chamber / offset 由 CHART_NAME 推導）
function profileThumbHtml(imgUrl) {
  return '<a class="wm" href="javascript:void(0)" title="點擊對角度（Wafer Match）">'
    + '<img src="' + escapeHtml(imgUrl) + '" alt="Profile RAW" loading="lazy"></a>';
}

function closeDetail() {
  _detailSeq++;
  wmResetInline();
  $('detail-modal').hidden = true;
  document.body.style.overflow = '';
  if (_sparkInstance) { try { _sparkInstance.destroy(); } catch (e) {} _sparkInstance = null; }
}

// ===== Trend chart（Chart.js）：沿用 NPW 網站 drawSpark 的畫法 =====
// 代表值（取最後一個有效的 CL 值）
function reprVal(pts, key) {
  for (var i = pts.length - 1; i >= 0; i--) {
    var v = pts[i] && pts[i][key];
    if (v != null && isFinite(Number(v))) return Number(v);
  }
  return null;
}

// opts: { block:'A'|'N', uclLclPct, alarmSeq, alarmDay }
//   ADDER(A)：MEAN_VALUE/UCL/XBAR(CL)/+1σ/+2σ，Y 軸 0 ~ UCL×(1+pct)
//   NON-ADDER(N)：MEAN_VALUE/UCL/±2σ/±1σ/XBAR/LCL，Y 軸 LCL×(1-pct) ~ UCL×(1+pct)
//   alarm 點（CHART_SEQ 相同、或當天 ALARM_COUNT>=1）標紅放大
function drawSpark(canvas, pts, opts) {
  if (!canvas || !window.Chart || !pts || !pts.length) return null;
  opts = opts || {};

  var yMin = null, yMax = null;
  if (opts.uclLclPct != null) {
    var u = reprVal(pts, 'ucl'), l = reprVal(pts, 'lcl');
    if (u != null) yMax = u * (1 + opts.uclLclPct);
    yMin = (opts.block === 'A') ? 0 : ((l != null) ? l * (1 - opts.uclLclPct) : 0);
  }
  var hasMin = yMin != null, hasMax = yMax != null;

  var labels = pts.map(function (p) { return String(p.d || '').replace('T', ' '); });
  var meanRaw = pts.map(function (p) { return p.mean == null ? null : Number(p.mean); });
  var ucl = pts.map(function (p) { return p.ucl == null ? null : Number(p.ucl); });
  var lcl = pts.map(function (p) { return p.lcl == null ? null : Number(p.lcl); });
  var cl  = pts.map(function (p) { return p.xbar == null ? null : Number(p.xbar); });

  var alarmPt = pts.map(function (p) {
    var sameSeq = opts.alarmSeq && String(p.seq) === String(opts.alarmSeq);
    var sameDay = opts.alarmDay && String(p.d || '').substring(0, 10) === opts.alarmDay && Number(p.alarm) >= 1;
    return !!(sameSeq || sameDay);
  });

  // 超出上下界的點裁到邊界並標紅（tooltip 仍顯示真值）
  var overTop  = meanRaw.map(function (v) { return hasMax && isFinite(v) && v !== null && v > yMax; });
  var underBot = meanRaw.map(function (v) { return hasMin && isFinite(v) && v !== null && v < yMin; });
  var mean = meanRaw.map(function (v, i) { return v == null ? null : (overTop[i] ? yMax : (underBot[i] ? yMin : v)); });
  var ptColor  = alarmPt.map(function (a, i) { return (a || overTop[i] || underBot[i]) ? 'red' : '#000'; });
  var ptRadius = alarmPt.map(function (a, i) { return (a || overTop[i] || underBot[i]) ? 5 : 3; });

  var yScale = { ticks: { font: { size: 9 } } };
  if (hasMin) yScale.min = yMin;
  if (hasMax) yScale.max = yMax;
  if (!hasMin && !hasMax) yScale.beginAtZero = true;

  var meanDs = {
    label: 'MEAN_VALUE', data: mean, borderColor: '#000', backgroundColor: 'rgba(0,0,0,0.1)',
    pointStyle: 'triangle', fill: false, tension: .2, borderWidth: 1.5,
    pointBackgroundColor: ptColor, pointBorderColor: ptColor, pointRadius: ptRadius, pointHoverRadius: 6
  };
  function line(label, data, color, dash, width) {
    return { label: label, data: data, borderColor: color, borderDash: dash, fill: false, pointRadius: 0, borderWidth: width || 1.2, spanGaps: true };
  }

  var datasets;
  if (opts.block === 'N') {
    var avg1  = pts.map(function (p) { return p.avg1  == null ? null : Number(p.avg1); });
    var avgn1 = pts.map(function (p) { return p.avgn1 == null ? null : Number(p.avgn1); });
    var avg2  = pts.map(function (p) { return p.avg2  == null ? null : Number(p.avg2); });
    var avgn2 = pts.map(function (p) { return p.avgn2 == null ? null : Number(p.avgn2); });
    datasets = [meanDs,
      line('UCL', ucl, 'red', [4, 2]),
      line('+2σ', avg2, 'orange', [6, 2]),
      line('+1σ', avg1, '#1976d2', [2, 2]),
      line('XBAR (CL)', cl, '#0f766e', [0, 0]),
      line('-1σ', avgn1, '#1976d2', [2, 2]),
      line('-2σ', avgn2, 'orange', [6, 2]),
      line('LCL', lcl, 'red', [4, 2])
    ];
  } else {
    var p1 = pts.map(function (p) { return (p.xbar == null || p.sigma == null) ? null : Number(p.xbar) + Number(p.sigma); });
    var p2 = pts.map(function (p) { return (p.xbar == null || p.sigma == null) ? null : Number(p.xbar) + 2 * Number(p.sigma); });
    datasets = [meanDs,
      line('UCL', ucl, 'red', [4, 2], 1.5),
      line('XBAR (CL)', cl, '#0f766e', [0, 0], 1.5),
      line('+1σ (XBAR+σ)', p1, '#1976d2', [2, 2], 1),
      line('+2σ (XBAR+2σ)', p2, 'orange', [6, 2], 1)
    ];
  }

  return new Chart(canvas.getContext('2d'), {
    type: 'line',
    data: { labels: labels, datasets: datasets },
    options: {
      animation: false, responsive: true, maintainAspectRatio: false,
      layout: { padding: { top: 4 } },
      plugins: {
        legend: { display: true, position: 'top', align: 'end', labels: { usePointStyle: true, pointStyle: 'line', boxWidth: 26, boxHeight: 8, padding: 8, font: { size: 9, weight: '700' } } },
        tooltip: { callbacks: { label: function (c) {
          if (c.dataset.label === 'MEAN_VALUE') {
            var rv = meanRaw[c.dataIndex];
            var p = pts[c.dataIndex] || {};
            return 'MEAN_VALUE: ' + (rv == null ? '-' : rv)
              + (overTop[c.dataIndex] ? ' (>上限)' : (underBot[c.dataIndex] ? ' (<下限)' : ''))
              + (p.lot ? '  LOT ' + p.lot : '') + (p.wafer ? '  W' + p.wafer : '');
          }
          return c.dataset.label + ': ' + c.formattedValue;
        } } }
      },
      scales: {
        x: { ticks: { font: { size: 8 }, maxRotation: 90, minRotation: 90, autoSkip: true, maxTicksLimit: 14 } },
        y: yScale
      }
    }
  });
}

// ===== 對角度（Wafer Match）：沿用 NPW 網站的參數推導 =====
// 機台 B 編號 → FI 版本
function wmMode(entity, bnum) {
  entity = String(entity || '').toUpperCase();
  var n = parseInt(bnum, 10);
  if (entity === 'NISACVD') {
    if ((n >= 1 && n <= 5) || (n >= 9 && n <= 14)) return 'FI5.X';
    if (n >= 6 && n <= 8) return 'FI6.4';
  } else if (entity === 'SACVD') {
    if ((n >= 1 && n <= 5) || n === 7) return 'FI5.X';
    if (n === 6 || (n >= 8 && n <= 12) || n === 81) return 'FI6.4';
  }
  return 'FI5.X';  // 未列入者的預設
}

// Tool_name（如 NISACVD-B03C）/ Port / CHART_NAME → mode / CASS / side / station
function wmDeriveParams(tool, portStr, cname) {
  var m = String(tool || '').toUpperCase().match(/(NISACVD|SACVD)-B(\d+)\s*([A-Z]*)/);
  if (!m) return null;
  var entity = m[1], bnum = m[2], letter = m[3] || '';
  var mode = wmMode(entity, bnum);
  var firstPort = (String(portStr || '').split(',')[0] || '').trim();
  var pnum = parseInt(firstPort, 10);
  var cass = (pnum >= 1 && pnum <= 4) ? String.fromCharCode(64 + pnum) : 'A';  // 1→A … 4→D
  var side = /W2/i.test(String(cname || '')) ? 'S2' : 'S1';                    // W1→S1, W2→S2
  // 尾碼可含多個 chamber 字母（如 CB = CHC+CHB）；無字母（XFER NG）→ LL
  var stMap = { A: 'CHA', B: 'CHB', C: 'CHC' };
  var parts = [];
  for (var i = 0; i < letter.length; i++) { if (stMap[letter[i]]) parts.push(stMap[letter[i]]); }
  var station = parts.length ? parts.join('+') : 'LL';
  return { mode: mode, cass: cass, side: side, station: station, entity: entity, bnum: bnum, letter: letter };
}

// 依目前明細（ADDER 用 ADDER_Map 規則、NON-ADDER 用 Profile 規則）算出 WaferMatch 的查詢字串與標題
function wmParamsFor(imgUrl) {
  if (!_currentDetail) return null;
  var npw = _currentDetail.npw || {};
  var row = _currentDetail.row || {};
  var tool = npw.PROCESSUNIT || row.PROCESSINGUNIT || '';
  var port = (_currentDetail.ports || []).join(', ');
  var cname = row.CHART_NAME || '';
  var isProfile = _currentDetail.block === 'N';

  var p = isProfile ? wmDeriveProfileParams(tool, port, cname) : wmDeriveParams(tool, port, cname);
  if (!p) return { error: '無法從 Tool_name / Port / CHART_NAME 推導對角度參數（Tool_name：' + tool + '）' };

  var offset = isProfile ? p.offset : 0;
  var qs = 'mode=' + encodeURIComponent(p.mode) + '&cass=' + encodeURIComponent(p.cass)
    + '&side=' + encodeURIComponent(p.side) + '&station=' + encodeURIComponent(p.station)
    + '&offset=' + encodeURIComponent(offset) + '&img=' + encodeURIComponent(imgUrl);
  var title = p.entity + '-B' + p.bnum + (p.letter || '') + '｜' + p.mode + '｜CASS ' + p.cass + '｜' + p.side + '｜' + p.station
    + (isProfile ? '｜offset ' + offset + '°' : '');
  return { qs: qs, title: title };
}

// 開完整的對位置視窗
function wmOpenPopup(imgUrl) {
  var w = wmParamsFor(imgUrl);
  if (!w) return;
  if (w.error) { alert(w.error); return; }
  $('wmatchTitle').textContent = '對角度 · ' + w.title;
  $('wmatchFrame').src = 'WaferMatch.html?v=' + WM_VERSION + '&' + w.qs;
  $('wmatchModal').style.display = 'block';
}

// 內嵌在明細頁的小圖：圖片網址或 Port 有變就重算一次；src 沒變就不重載
function wmResetInline(message) {
  var frame = $('d-wm-frame');
  frame.src = 'about:blank';
  frame.className = 'wm-inline blank';
  $('d-wm-placeholder').hidden = false;
  $('d-wm-placeholder').textContent = message || '等待 Map 載入…';
  $('d-wm-title').textContent = '點擊可放大';
}

function wmRefreshInline() {
  if (!_currentDetail || !_currentDetail.wm || !_currentDetail.wmImg) return;
  var w = wmParamsFor(_currentDetail.wmImg);
  if (!w || w.error) { wmResetInline(w ? w.error : ''); return; }
  var src = 'WaferMatch.html?v=' + WM_VERSION + '&embed=1&' + w.qs;
  var frame = $('d-wm-frame');
  if (frame.getAttribute('data-src') !== src) {
    frame.setAttribute('data-src', src);
    frame.src = src;
  }
  frame.className = 'wm-inline';
  wmFixInlineHeight();
  $('d-wm-placeholder').hidden = true;
  $('d-wm-title').textContent = w.title + '｜點擊可放大';
}

// 舊瀏覽器不支援 aspect-ratio 時，用 JS 依寬度算高度（版面圖是 600x850）
function wmFixInlineHeight() {
  var frame = $('d-wm-frame');
  var supportsAspect = window.CSS && CSS.supports && CSS.supports('aspect-ratio', '1 / 1');
  if (supportsAspect || !frame.clientWidth) { frame.style.height = ''; return; }
  frame.style.height = Math.round(frame.clientWidth * 850 / 600) + 'px';
}

// iframe 載入後，由父頁直接整理裡面的畫面（同網域可以存取）：
//   不管伺服器上的 WaferMatch.html 是不是有 embed 模式的新版，都把設定區與即時放大圖藏掉、重算縮放，
//   並把點畫面接到開完整視窗。偵測到舊版時在卡片標題提醒重新部署。
function wmInlineLoaded() {
  var frame = $('d-wm-frame');
  if (!frame.getAttribute('data-src') || !frame.src || /about:blank$/.test(frame.src)) return;
  var doc, win;
  try { doc = frame.contentDocument; win = frame.contentWindow; } catch (e) { return; }
  if (!doc || !doc.body) return;

  var isNew = doc.documentElement.classList.contains('embed');
  ['toolbar', 'live-panel'].forEach(function (id) {
    var el = doc.getElementById(id);
    if (el) { el.hidden = true; el.style.display = 'none'; }
  });
  var wrap = doc.getElementById('main-wrap');
  if (wrap) { wrap.style.margin = '0'; wrap.style.gap = '0'; }
  var box = doc.getElementById('canvas-container');
  if (box) { box.style.boxShadow = 'none'; box.style.borderRadius = '0'; box.style.cursor = 'pointer'; }
  doc.body.style.background = 'transparent';
  doc.body.style.overflow = 'hidden';
  try { if (typeof win.applyResponsiveScale === 'function') win.applyResponsiveScale(); } catch (e) {}

  if (!isNew) {
    // 舊版不會 postMessage，自己接點擊；並提醒伺服器上的檔案要更新
    var canvas = doc.getElementById('mainCanvas');
    if (canvas && !canvas.getAttribute('data-ocap-click')) {
      canvas.setAttribute('data-ocap-click', '1');
      canvas.addEventListener('click', function () { if (_currentDetail && _currentDetail.wmImg) wmOpenPopup(_currentDetail.wmImg); });
    }
    $('d-wm-title').textContent += '｜伺服器上的 WaferMatch.html 是舊版，請重新部署';
  }
}

function wmOpenFromMap(imgUrl) { wmOpenPopup(imgUrl); }

// NON-ADDER Profile 對角度：side / chamber / offset 由 CHART_NAME 推導（沿用 NPW）
//   side/chamber：名稱以 dash 分段，找形如 AC2 / BC2 / B2 的段落，字母=chamber（可多個），尾數 1/2 → S1/S2
//   offset：含 HTN430D4 → 300；符合 HTN…D1 → 0；其他 → 180
//   mode/CASS 與 ADDER 相同
function wmDeriveProfileParams(tool, portStr, cname) {
  var m = String(tool || '').toUpperCase().match(/(NISACVD|SACVD)-B(\d+)/);
  if (!m) return null;
  var entity = m[1], bnum = m[2];
  var mode = wmMode(entity, bnum);
  var firstPort = (String(portStr || '').split(',')[0] || '').trim();
  var pnum = parseInt(firstPort, 10);
  var cass = (pnum >= 1 && pnum <= 4) ? String.fromCharCode(64 + pnum) : 'A';
  var name = String(cname || '').toUpperCase();
  var side = 'S1', station = 'LL';
  var seg = null;
  name.split('-').some(function (part) { if (/^[ABC]{1,3}[12]$/.test(part)) { seg = part; return true; } return false; });
  if (seg) {
    var letters = seg.slice(0, -1), digit = seg.slice(-1);
    side = (digit === '2') ? 'S2' : 'S1';
    var stMap = { A: 'CHA', B: 'CHB', C: 'CHC' };
    var parts = [];
    for (var i = 0; i < letters.length; i++) { if (stMap[letters[i]]) parts.push(stMap[letters[i]]); }
    if (parts.length) station = parts.join('+');
  }
  var offset = 180;
  if (name.indexOf('HTN430D4') >= 0) offset = 300;
  else if (/HTN[A-Z0-9_]*D1(?![0-9])/.test(name)) offset = 0;
  return { mode: mode, cass: cass, side: side, station: station, offset: offset, entity: entity, bnum: bnum };
}

function wmOpenFromProfile(imgUrl) { wmOpenPopup(imgUrl); }

function wmClose() {
  $('wmatchModal').style.display = 'none';
  $('wmatchFrame').src = 'about:blank';  // 停止 iframe、釋放
}

// ===== 事件綁定與初始化 =====
$('btn-search').addEventListener('click', search);
$('btn-prev').addEventListener('click', function () { shiftDate(-1); });
$('btn-next').addEventListener('click', function () { shiftDate(1); });
$('date').addEventListener('change', search);

$('d-close').addEventListener('click', closeDetail);
$('emst-save').addEventListener('click', emstSave);
$('emst-copy').addEventListener('click', emstCopy);
$('emst-tool').addEventListener('input', function () { _emst.touched.tool = true; });
$('emst-wc').addEventListener('input', function () { _emst.touched.wc = true; });
$('detail-modal').addEventListener('click', function (e) { if (e.target === this) closeDetail(); });
$('wmatchClose').addEventListener('click', wmClose);
window.addEventListener('message', function (e) {
  if (e.data && e.data.type === 'wm-open' && _currentDetail && _currentDetail.wmImg) wmOpenPopup(_currentDetail.wmImg);
});
$('d-wm-frame').addEventListener('load', wmInlineLoaded);
window.addEventListener('resize', wmFixInlineHeight);
$('wmatchModal').addEventListener('click', function (e) { if (e.target === this) wmClose(); });
document.addEventListener('keydown', function (e) {
  if (e.key !== 'Escape') return;
  if ($('wmatchModal').style.display === 'block') wmClose();
  else if (!$('detail-modal').hidden) closeDetail();
});

// 先畫出空的固定版面，再預設今天查一次
renderSections(groupBySection(SECTIONS, []));
$('date').value = toDateString(new Date());
ping();
search();
</script>

</body>
</html>
