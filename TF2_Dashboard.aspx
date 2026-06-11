<%@ Page Language="C#" AutoEventWireup="true" CodeFile="TF2_Dashboard.aspx.cs" Inherits="TF2_Dashboard" %>
<!DOCTYPE html>
<html lang="zh-Hant">
<head>
<meta charset="UTF-8">
<title>SPC 管制圖儀表板</title>
<!-- 外部套件 -->
<!-- 已移除 Excel 讀取：改由後端 API 從 SQL Server 撈資料 -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.3.0/dist/chart.umd.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chartjs-plugin-datalabels@2.2.0/dist/chartjs-plugin-datalabels.min.js"></script>
<style>
/* ---- 全局樣式 ---- */
* { box-sizing: border-box; }
body {
font-family: "Microsoft JhengHei", Arial, sans-serif;
margin: 0;
background: #f3f5f9;
color: #333;
}
/* 頁首 */
header {
background: radial-gradient(1200px 180px at 12% 20%, rgba(255,255,255,.18), rgba(255,255,255,0)),
linear-gradient(135deg, #1e88e5, #1565c0);
color: #fff;
padding: 16px 32px;
box-shadow: 0 14px 30px rgba(2,6,23,.18);
display: flex;
align-items: center;
justify-content: space-between;
}
header .title-block { display: flex; flex-direction: column; }
header h1 { margin: 0; font-size: 22px; letter-spacing: 1px; }
header .meta { font-size: 12px; text-align: right; opacity: 0.9; }
/* 主容器 */
.page-wrapper { max-width: 1720px; margin: 20px auto 40px; padding: 0 18px 24px; }
/* 上方操作區塊 */
#top-panel {
display: flex;
align-items: center;
justify-content: space-between;
margin-bottom: 16px;
flex-wrap: wrap;
gap: 12px;
}
#top-panel-left { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
/* 原 Excel 匯入已移除 */
.file-input-label { font-size: 13px; color: #555; margin-right: 4px; }
/* 按鈕 */
.btn-primary {
display: inline-flex;
align-items: center;
justify-content: center;
padding: 9px 16px;
font-size: 13px;
font-weight: 700;
letter-spacing: .5px;
line-height: 1;
border-radius: 10px;
border: 1px solid rgba(255,255,255,.18);
cursor: pointer;
background: linear-gradient(180deg, #1e88e5, #1565c0);
color: #fff;
box-shadow: 0 10px 22px rgba(2,6,23,.12), 0 2px 6px rgba(2,6,23,.10);
transition: transform .12s ease, box-shadow .12s ease, filter .12s ease;
min-height: 38px;
}
.btn-primary:focus { outline: none; box-shadow: 0 0 0 3px rgba(37,99,235,.25), 0 10px 22px rgba(2,6,23,.12), 0 2px 6px rgba(2,6,23,.10); }
.btn-primary:hover { filter: brightness(1.02); transform: translateY(-1px); }
.btn-primary:active { transform: translateY(0); box-shadow: 0 6px 14px rgba(2,6,23,.12), 0 2px 5px rgba(2,6,23,.10); }

/* 次要按鈕（例如：顯示30天未進點） */
.btn-secondary {
background: linear-gradient(180deg, #22c1f1, #0ea5e9);
border-color: rgba(255,255,255,.22);
}

/* 提示文字（按鈕下方小字） */
.btn-subtext { font-size: 11px; color: #64748b; margin-top: 4px; text-align: right; }
#back-to-top{
position: fixed;
right: 18px;
bottom: 18px;
z-index: 9999;
padding: 10px 12px;
border: 0;
border-radius: 999px;
background: #2563eb;
color: #fff;
cursor: pointer;
box-shadow: 0 6px 18px rgba(0,0,0,.18);
display: none; /* 預設隱藏 */
}
#back-to-top:hover{ filter: brightness(.95); }
.unit-link.badscore-B { color: #d47b00; background: #fff3e0; border-color: #ffb74d; }
.unit-link.badscore-C { color: #c62828; background: #ffebee; border-color: #ef9a9a; }
.btn-primary:hover { background: #145ea8; box-shadow: 0 2px 5px rgba(0,0,0,0.25); transform: translateY(-1px); }
.btn-primary:active { transform: translateY(0); box-shadow: 0 1px 3px rgba(0,0,0,0.2); }
/* 操作說明 */
.hint-text { font-size: 12px; color: #666; margin-top: 4px; }
/* 主要左右布局 */
#main-layout { display: flex; align-items: flex-start; margin-top: 6px; gap: 20px; }

/* =========================
   Left Side Toolbar
   ========================= */
#left-toolbar{
  position: fixed;
  left: 10px;
  top: 120px;
  z-index: 10001;

  width: 56px;
  padding: 10px 8px;
  border-radius: 999px;
  border: 1px solid rgba(148,163,184,.35);
  background: linear-gradient(180deg, rgba(255,255,255,.92), rgba(255,255,255,.78));
  box-shadow: 0 14px 30px rgba(2,6,23,.10);

  display: flex;
  flex-direction: column;
  gap: 12px;
  align-items: center;
}

.left-tool{
  width: 44px;
  height: 44px;
  border-radius: 16px;
  border: 1px solid rgba(148,163,184,.32);
  background: rgba(241,245,255,.65);
  box-shadow: inset 0 1px 0 rgba(255,255,255,.70);

  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;

  position: relative;
  overflow: visible;
  transition: transform .12s ease, filter .12s ease, background .18s ease;
}
.left-tool:hover{ filter: brightness(1.02); transform: translateY(-1px) scale(1.08); }

.left-tool .icon{
  width: 30px;
  height: 30px;
  border-radius: 999px;
  background: linear-gradient(180deg, rgba(148,163,184,.22), rgba(148,163,184,.10));
  border: 1px solid rgba(148,163,184,.25);
  display:flex;
  align-items:center;
  justify-content:center;
  color:#0f4aa8;
  font-weight: 900;
  line-height: 1;
}

/* hover label: simple tooltip, no large pill */
.left-tool .label{
  position: absolute;
  left: 60px;
  top: 50%;
  transform: translateY(-50%);
  padding: 8px 10px;
  border-radius: 12px;
  border: 1px solid rgba(148,163,184,.35);
  background: rgba(255,255,255,.96);
  box-shadow: 0 10px 22px rgba(2,6,23,.12);
  white-space: nowrap;
  font-weight: 900;
  color:#334155;
  opacity: 0;
  pointer-events: none;
  transition: opacity .12s ease;
}
.left-tool:hover .label{ opacity: 1; }


/* selected */
.left-tool.active{
  background: rgba(30,136,229,.18);
  border-color: rgba(30,136,229,.28);
  transform: scale(1.06);
}
.left-tool.active .icon{
  background: rgba(30,136,229,.22);
  border-color: rgba(30,136,229,.28);
}


/* =========================
   Settings Panel (modal)
   ========================= */
#settings-modal{
  display:none;
  position:fixed;
  inset:0;
  background: rgba(0,0,0,.45);
  z-index: 10002;
}
#settings-modal .panel{
  position:absolute;
  left: 70px;
  top: 90px;
  width: 520px;
  max-width: calc(100vw - 90px);
  height: 640px;
  max-height: calc(100vh - 120px);
  background: #fff;
  border-radius: 14px;
  overflow: hidden;
  box-shadow: 0 18px 42px rgba(2,6,23,.18);
  border: 1px solid rgba(148,163,184,.55);
  display:flex;
  flex-direction: column;
}
#settings-modal .head{
  background: linear-gradient(135deg, #1e88e5, #1565c0);
  color:#fff;
  padding: 10px 12px;
  display:flex;
  align-items:center;
  justify-content: space-between;
}
#settings-modal .head-title{ font-weight: 900; font-size: 13px; letter-spacing:.5px; }
#settings-modal .head-actions{ display:flex; gap:8px; }
#settings-modal .body{ padding: 12px; overflow:auto; }
.settings-section{ border:1px solid rgba(148,163,184,.35); border-radius: 12px; padding: 10px; margin-bottom: 10px; background: rgba(241,245,255,.35); }
.settings-section-title{ font-weight: 900; color:#0f4aa8; margin-bottom: 8px; }
.settings-grid{ display:grid; grid-template-columns: 1fr 1fr; gap: 10px; }
.settings-field label{ display:block; font-size: 12px; color:#334155; font-weight: 800; margin-bottom: 4px; }
.settings-field input{
  width:100%;
  padding: 8px 10px;
  border-radius: 10px;
  border: 1px solid rgba(148,163,184,.55);
  font-size: 13px;
}
.settings-hint{ font-size: 11px; color:#64748b; margin-top: 6px; line-height: 1.35; }

/* 左側：機台評分表卡片 */
#score-table-container {
width: 380px;
min-width: 220px;
position: sticky;
top: 90px;
align-self: flex-start;
z-index: 10;
background: linear-gradient(180deg, rgba(255,255,255,.95), rgba(255,255,255,.86));
backdrop-filter: blur(8px);
border-radius: 14px;
box-shadow: 0 14px 30px rgba(2,6,23,.10), 0 2px 8px rgba(2,6,23,.06);
padding: 12px 12px 14px 12px;
height: fit-content;
border: 1px solid rgba(148,163,184,.35);
}
#score-table-container > b {
display: flex;
align-items: center;
justify-content: space-between;
margin-bottom: 10px;
font-size: 14px;
color: #0f4aa8;
letter-spacing: .5px;
}

#score-table { width: 100%; border-collapse: separate; border-spacing: 0; font-size: 13px; overflow: hidden; border-radius: 12px; }
#score-table th, #score-table td { border: 0; padding: 8px 10px; text-align: center; }

/* 機台欄位：固定寬度 + 允許換行成兩行 */
#score-table th:first-child, #score-table td:first-child {
  width: 110px;
  max-width: 110px;
  white-space: normal;
  word-break: break-word;
}
/* 確保機台字串可以換行 */
#score-table .score-link{ display:inline-block; max-width:100%; white-space:normal; word-break:break-word; line-height:1.15; }

#score-table thead th {
background: #f1f5ff;
font-weight: 800;
color: #334155;
border-bottom: 1px solid rgba(148,163,184,.35);
}
#score-table tbody tr {
background: rgba(255,255,255,.9);
}
#score-table tbody tr + tr td { border-top: 1px solid rgba(226,232,240,.9); }
#score-table tbody tr:hover { background: #eef6ff; }

.score-link { color: #1d4ed8; cursor: pointer; text-decoration: none; font-weight: 800; }
.score-link:hover { text-decoration: underline; }

/* A/B/C 以 badge 顯示 */
#score-table td.score-cell { padding: 6px 10px; }
.score-badge{
display:inline-flex;
align-items:center;
justify-content:center;
min-width: 26px;
height: 22px;
padding: 0 8px;
border-radius: 999px;
font-weight: 900;
letter-spacing: .5px;
border: 1px solid transparent;
}
.score-badge-A{ background:#dcfce7; color:#166534; border-color:#86efac; }
.score-badge-B{ background:#fef9c3; color:#854d0e; border-color:#fde047; }
.score-badge-C{ background:#fee2e2; color:#991b1b; border-color:#fecaca; }
.score-badge--{ background:#e2e8f0; color:#334155; border-color:#cbd5e1; }
/* 可排序表頭樣式 */
#score-table th.sortable { cursor: pointer; position: relative; }
#score-table th.sortable::after { content: '▲'; font-size: 10px; margin-left: 4px; opacity: 0.4; }
#score-table th.sortable[data-order="desc"]::after { content: '▼'; }
/* 右側內容區 */
#right-panel { flex: 1; min-width: 0; }
/* Highlight 區塊 */
#highlight-units {
margin-bottom: 14px;
font-size: 13px;
display: none;

/* 固定大小 + 可滾動（避免重點提示過長） */
max-height: 420px;
overflow: auto;
padding-right: 6px;
}
#highlight-units-title {
font-weight: 900;
color: #0f4aa8;
margin-bottom: 10px;
letter-spacing: .6px;

/* 置頂，滾動時標題固定 */
position: sticky;
top: 0;
background: #f3f5f9;
padding: 6px 0;
z-index: 2;
}
.highlight-row { margin-bottom: 6px; display:flex; flex-wrap:wrap; align-items:center; gap:5px; }
.highlight-label {
font-weight: 800;
margin-right: 0;
color: #334155;
background: rgba(241,245,255,.9);
border: 1px solid rgba(148,163,184,.35);
padding: 2px 7px;
border-radius: 999px;
font-size: 12px;
}
.unit-link {
display: inline-flex;
align-items:center;
justify-content:center;
margin: 0;
padding: 3px 8px;
border-radius: 999px;
font-size: 11px;
font-weight: 800;
border: 1px solid transparent;
cursor: pointer;
text-decoration: none;
white-space: nowrap;
transition: transform .12s ease, filter .12s ease;
}
.highlight-subtitle{
font-weight: 900;
color: #0f4aa8;
margin: 5px 0 6px;
font-size: 11px;
letter-spacing: .45px;
}
.unit-link:hover { filter: brightness(0.98); transform: translateY(-1px); }

/* chips */
.unit-link.near2sigma { color: #92400e; background: #ffedd5; border-color: #fdba74; }
.unit-link.liftup { color: #854d0e; background: #fef9c3; border-color: #fde047; }

.unit-link.badscore-B { color: #854d0e; background: #fef9c3; border-color: #fde047; }
.unit-link.badscore-C { color: #991b1b; background: #fee2e2; border-color: #fecaca; }

/* Highlight - 依 RECIPE 分區塊（如示意圖） */
.recipe-block{
background: linear-gradient(180deg, rgba(227,242,253,.85), rgba(227,242,253,.65));
border-left: 4px solid #1976d2;
padding: 8px 10px 8px 12px;
border-radius: 10px;
margin-bottom: 10px;
box-shadow: 0 8px 18px rgba(2,6,23,.05);
}
.recipe-title{
font-weight: 900;
color: #0f4aa8;
margin-bottom: 8px;
letter-spacing: .5px;
font-size: 13px;
}

/* 3 欄顯示（RWD 自動降欄） */
#highlight-units-grid{
display: grid;
grid-template-columns: repeat(3, minmax(0, 1fr));
gap: 10px;
}
@media (max-width: 1200px){
#highlight-units-grid{ grid-template-columns: repeat(2, minmax(0, 1fr)); }
}
@media (max-width: 720px){
#highlight-units-grid{ grid-template-columns: 1fr; }
}

/* 顯示全部按鈕區塊 */
#show-all-btn { margin: 0 0 10px 0; display: none; }
#toggle-old-btn { margin: 0 0 10px 0; }
/* 圖表網格 */
#charts { display: flex; flex-wrap: wrap; gap: 18px; }
/* 圖表卡片 */
.chart-container {
width: 49%;
min-width: 360px;
background: linear-gradient(180deg, rgba(255,255,255,.95), rgba(255,255,255,.86));
backdrop-filter: blur(8px);
border: 1px solid rgba(148,163,184,.35);
border-radius: 14px;
margin-bottom: 10px;
padding: 10px 12px 12px 12px;
box-sizing: border-box;
box-shadow: 0 14px 30px rgba(2,6,23,.10), 0 2px 8px rgba(2,6,23,.06);
overflow: hidden;
transition: transform .12s ease, box-shadow .12s ease;
}
.chart-container:hover { transform: translateY(-2px); box-shadow: 0 18px 42px rgba(2,6,23,.14), 0 2px 10px rgba(2,6,23,.08); }

.chart-header {
display: flex;
align-items: flex-start;
justify-content: space-between;
margin-bottom: 8px;
padding-bottom: 8px;
border-bottom: 1px solid rgba(148,163,184,.35);
}
.chart-header-title {
margin: 0;
font-size: 14px;
color: #0f4aa8;
letter-spacing: .6px;
font-weight: 900;
line-height: 1.25;
}
.chart-header-tag {
font-size: 11px;
color: #64748b;
background: rgba(241,245,255,.9);
border: 1px solid rgba(148,163,184,.35);
padding: 3px 8px;
border-radius: 999px;
}
.chart-container canvas { margin-top: 4px; width: 100% !important; display: block; }
/* RWD */
@media (max-width: 1024px) {
#main-layout { flex-direction: column; }
#score-table-container { position: static; width: 100%; margin-bottom: 14px; }
.chart-container { width: 100%; min-width: 0; }
}
</style>

<style>
/* =========================
   AI Q&A Dock (右下角問答窗格)
   ========================= */
#ai-dock {
  position: fixed;
  right: 18px;
  bottom: 68px; /* 避免遮到右下 TOP 按鈕 */
  z-index: 10000;
  width: 480px;                /* 放大 */
  max-width: calc(100vw - 36px);
  font-family: "Microsoft JhengHei", Arial, sans-serif;
}
#ai-fab {
  position: absolute;
  right: 0;
  bottom: 0;
  border: 0;
  border-radius: 999px;
  padding: 11px 16px;          /* 放大 */
  cursor: pointer;
  background: linear-gradient(180deg, #1e88e5, #1565c0);
  color: #fff;
  font-weight: 900;
  box-shadow: 0 10px 24px rgba(2,6,23,.18);
}
#ai-panel {
  position: absolute;
  right: 0;
  bottom: 56px;
  /* 因為整個 dock 往上移了，面板底部也要跟著往上，避免越界 */
  transform: translateY(-50px);
  width: 480px;                /* 放大 */
  max-width: calc(100vw - 36px);
  height: 680px;               /* 放大 */
  max-height: calc(100vh - 110px);
  border-radius: 14px;
  overflow: hidden;
  border: 1px solid rgba(148,163,184,.55);
  background: linear-gradient(180deg, rgba(255,255,255,.98), rgba(255,255,255,.92));
  box-shadow: 0 18px 42px rgba(2,6,23,.18), 0 2px 10px rgba(2,6,23,.08);
  display: none;
}
#ai-panel.open { display: flex; flex-direction: column; }

#ai-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 10px 12px;
  background: linear-gradient(135deg, #1e88e5, #1565c0);
  color: #fff;
}
#ai-head-title { font-weight: 900; font-size: 13px; letter-spacing: .5px; }
#ai-head-actions { display: flex; align-items: center; gap: 8px; }
.ai-head-btn {
  border: 1px solid rgba(255,255,255,.35);
  background: rgba(255,255,255,.12);
  color: #fff;
  border-radius: 10px;
  padding: 6px 10px;
  cursor: pointer;
  font-weight: 800;
  font-size: 12px;
}
.ai-head-btn:hover { filter: brightness(1.02); }
#ai-status { font-size: 11px; opacity: .9; margin-top: 2px; }
#ai-log {
  flex: 1 1 auto;
  padding: 10px 10px 0 10px;
  overflow: auto;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.ai-bubble {
  max-width: 92%;
  border-radius: 14px;
  padding: 9px 10px;
  font-size: 13px;
  line-height: 1.55;
  border: 1px solid rgba(148,163,184,.35);
  background: rgba(255,255,255,.92);
  white-space: pre-wrap;
  word-break: break-word;
}
.ai-bubble.user { align-self: flex-end; background: #e3f2fd; border-color: rgba(30,136,229,.30); }
.ai-bubble.assistant { align-self: flex-start; background: #ffffff; }
.ai-bubble.error { align-self: flex-start; background: #ffebee; border-color: rgba(198,40,40,.30); color:#8b1d1d; }
#ai-compose {
  border-top: 1px solid rgba(148,163,184,.35);
  padding: 10px;
  display: grid;
  gap: 8px;
  background: rgba(241,245,255,.55);
}
#ai-input {
  width: 100%;
  min-height: 80px;
  resize: vertical;
  border-radius: 12px;
  border: 1px solid rgba(148,163,184,.55);
  padding: 10px;
  font-size: 13px;
  outline: none;
  background: #fff;
}
#ai-input:focus { box-shadow: 0 0 0 3px rgba(37,99,235,.18); border-color: rgba(30,136,229,.55); }
#ai-compose-row { display:flex; gap:8px; align-items:center; justify-content: space-between; }
#ai-send {
  border: 0;
  border-radius: 10px;
  padding: 9px 12px;
  cursor: pointer;
  background: linear-gradient(180deg, #1e88e5, #1565c0);
  color: #fff;
  font-weight: 900;
  min-width: 86px;
}
#ai-send[disabled] { opacity: .6; cursor: wait; }
#ai-hint { font-size: 11px; color: #64748b; line-height: 1.35; }
</style>
</head>
<body>
<header>
<div class="title-block"><h1>SPC 管制圖儀表板（TF2_EQ1）</h1></div>
<div class="meta">
<div>版本：v5.0（TF2_EQ1）</div>
<div id="page-time"></div>
</div>
</header>
<div id="left-toolbar" aria-label="tools">
    <div id="lt-chat" class="left-tool active" title="對話">
    <div class="icon">💬</div>
    <div class="label">對話</div>
  </div>
  <div id="lt-settings" class="left-tool" title="設定">
    <div class="icon">⚙</div>
    <div class="label">設定</div>
  </div>
  <div id="lt-fav" class="left-tool" title="收藏">
    <div class="icon">★</div>
    <div class="label">收藏</div>
  </div>
</div>

<!-- Settings Modal -->
<div id="settings-modal" role="dialog" aria-modal="true" aria-label="規則設定">
  <div class="panel">
    <div class="head">
      <div class="head-title">規則設定</div>
      <div class="head-actions">
        <button id="settings-reset" class="ai-head-btn" type="button">重設</button>
        <button id="settings-close" class="ai-head-btn" type="button">關閉</button>
      </div>
    </div>
    <div class="body">
            <div class="settings-section">
        <div class="settings-section-title">評分門檻</div>
        <div class="settings-hint" style="margin-bottom:8px;">依製程（NISACVD/SACVD）+ spec recipe 設定門檻：值≤A→A、A&lt;值&lt;C→B、值≥C→C。未列到的 recipe 走「其他(預設)」。</div>
        <div id="score-thr-container" class="settings-grid"></div>

                <div class="settings-grid" style="grid-template-columns: 1fr; margin-top:10px;">
          <div class="settings-field">
            <label>評分平均筆數 N（最後 N 筆 MEAN_VALUE 平均）</label>
            <input id="set-score-lastn" type="number" step="1" min="1" />
          </div>
        </div>
        <div class="settings-hint">評分使用「最後 N 筆 MEAN_VALUE 平均」套用門檻。</div>
      </div>

      <div class="settings-section">
        <div class="settings-section-title">接近 2σ 警戒</div>
        <div class="settings-grid">
          <div class="settings-field">
            <label>容許差值 (|MEAN - (XBAR+2σ)| ≤ ?)</label>
            <input id="set-near2-diff" type="number" step="0.1" />
          </div>
        </div>
      </div>

      <div class="settings-section">
        <div class="settings-section-title">最近 3 點上升</div>
        <div class="settings-grid">
          <div class="settings-field">
            <label>Last N（預設 3）</label>
            <input id="set-rise-lastn" type="number" step="1" />
          </div>
          <div class="settings-field">
            <label>Compare M（預設 10）</label>
            <input id="set-rise-compare" type="number" step="1" />
          </div>
          <div class="settings-field">
            <label>靠近 1σ 容許帶 ±</label>
            <input id="set-rise-band" type="number" step="0.1" />
          </div>
        </div>
        <div class="settings-hint">條件：最近 N 點平均 &gt; 最近 M 點平均，且最近 N 點每一點都在 (XBAR+σ)±band 的範圍內。</div>
      </div>

      <div class="settings-section">
        <div class="settings-section-title">收藏（待新增）</div>
        <div class="settings-hint">先預留：之後可收藏 CHART_NAME，快速跳轉。</div>
      </div>

      <button id="settings-apply" class="btn-primary" type="button" style="width:100%;">套用設定</button>
    </div>
  </div>
</div>

<div class="page-wrapper">
<div id="top-panel">
<div id="top-panel-left">
  <div style="display:flex; gap:10px; align-items:center; flex-wrap:wrap;">
    <span class="file-input-label">分頁：</span>
        <button id="tab-adder" class="btn-primary" type="button" style="min-height:34px; padding:8px 12px;">ADDER</button>
    <button id="tab-thk" class="btn-primary btn-secondary" type="button" style="min-height:34px; padding:8px 12px;">Partition</button>
    <button id="tab-u" class="btn-primary btn-secondary" type="button" style="min-height:34px; padding:8px 12px;">U%/Range</button>


        <span class="file-input-label" style="margin-left:6px;">群組：</span>
    <button id="btn-group-all" class="btn-primary" type="button" style="min-height:34px; padding:8px 12px;">ALL</button>
    <button id="btn-group-tu" class="btn-primary btn-secondary" type="button" style="min-height:34px; padding:8px 12px;">NISACVD</button>
    <button id="btn-group-abo" class="btn-primary btn-secondary" type="button" style="min-height:34px; padding:8px 12px;">SACVD</button>


    <span class="file-input-label" style="margin-left:6px;">分群(依 CHART_NAME)：</span>
                <select id="chartname-filter" style="padding:6px 10px;font-size:13px;border-radius:4px;border:1px solid:#ccc;background:#fff;">
      <option value="ALL">全部</option>
      <option value="-PA-">-PA-</option>
      <option value="HTSIN130_11">HTSIN130_11</option>

      <option value="PEOX50A">PEOX50A</option>
      <option value="XFER">XFER</option>
      <option value="HTN4DCPA">HTN4DCPA</option>
      <option value="FSHTN4DCPA">FSHTN4DCPA</option>
      <option value="LTUSG250_20">LTUSG250_20</option>
      <option value="LTUSG2.5K">LTUSG2.5K</option>
      <option value="STIPURGE">STIPURGE</option>
      <option value="NOSCRB7K">NOSCRB7K</option>
      <option value="USG50">USG50</option>
      <option value="NOSCRBUSG2K">NOSCRBUSG2K</option>
      <option value="SABOX110">SABOX110</option>
      <option value="OX50">OX50</option>
      <option value="HTSIN120_2.0">HTSIN120_2.0</option>
    </select>

                <span id="partition-hint" class="file-input-label" style="display:none; color:#0f4aa8; font-weight:900;">（Partition 分群：LTPA / PAR_）</span>



        <span class="file-input-label" style="margin-left:6px;">機台：</span>
        <input id="processunit-search" type="text" placeholder="輸入 tool ID 按 enter" style="padding:6px 10px;font-size:13px;border-radius:8px;border:1px solid #cbd5e1;min-width:220px;" />

    <button id="processunit-reset" class="btn-primary btn-secondary" type="button" style="min-height:34px; padding:8px 12px;">復原</button>

  </div>
</div>

<div style="display:flex; flex-direction:column; gap:8px; align-items:flex-end;">
<button id="show-all-btn" class="btn-primary" onclick="showAllCharts()">顯示全部機台</button>

</div>
</div>
<div id="load-status" class="hint-text" style="display:none; font-weight:800; color:#0f4aa8; margin-bottom:8px;"></div>
<div class="hint-text">
· 點機台名稱可只顯示該機台之管制圖。<br>
· 上方「接近兩倍σ / 三點上升」列表提供高風險機台快速篩選。
</div>
<div id="main-layout">
<!-- 左側：機台評分表 -->
<div id="score-table-container">
<b>機台評分表(Tool ABC)</b>
<table id="score-table">
<thead>
<tr>
<th id="th-unit" class="sortable" data-sort-key="unit" data-order="asc">機台</th>
<th id="th-recipe">RECIPE</th>
<th id="th-score" class="sortable" data-sort-key="score" data-order="asc">評分</th>
</tr>
</thead>
<tbody><!-- 動態產生 --></tbody>
</table>
</div>
<!-- 右側：Highlight + 圖表 -->
<div id="right-panel">
<div id="highlight-units"><div id="highlight-units-title">重點提示</div></div>
<div id="charts"></div>
</div>
</div>
</div>
<script>
/* =========================================================================
 *  設定區（CONFIG）— 規則與參數集中於此，方便修改
 * ========================================================================= */

// ---- 資料來源 / 後端 API ----
const SPC_API_URL = location.pathname; // 指回自己這支 .aspx（帶 ?tab= 時 code-behind 回 JSON）

// ---- AI 助手（前端不放金鑰，由 ai_proxy.aspx 從 web.config 取用）----
const AI_PROXY_URL = location.pathname + '?ai=1'; // 指回自己這支 .aspx（code-behind 代理 AI）
const AI_USER_ID = '00042507';
const AI_SYSTEM_PROMPT = '你是設備工程小助手,協助使用者查詢與整理 defect lesson learn。回答請精簡、條列重點。';

// ---- 評分：recipe 比對優先順序（較特定的排前面）----
const TF2_RECIPE_ORDER = {
  NISACVD: ['HTN4DCPA100', 'FSHTN4DCPA', 'HTSIN130_11', 'PEOX50A_PA', 'LTUSG250_20', 'XFER', '-PA-'],
  SACVD:   ['NOSCRBUSG2K', 'NOSCRB7K', 'HTN120_20', 'USG50', 'SABOX', 'XFER']
};

// ---- U%/Range：多段 recipe 時要排除的 token（大寫比對）----
const URANGE_RECIPE_EXCLUDE = ['ALERIS', 'SIN'];

// ---- 評分：未定義 recipe 的預設門檻 ----
const TF2_SCORE_DEFAULT = { a: 20, c: 50 };

// ---- 評分門檻 / 規則預設值（可在設定面板調整，存 localStorage）----
// 規則：值<=a → A；a<值<c → B；值>=c → C
const DEFAULT_RULES = {
  score: {
    NISACVD: {
      'HTN4DCPA100': { a: 3.2, c: 6.2 },
      'FSHTN4DCPA':  { a: 5.8, c: 7.9 },
      'HTSIN130_11': { a: 4.1, c: 10.5 },
      'PEOX50A_PA':  { a: 3.1, c: 8.1 },
      'LTUSG250_20': { a: 3.1, c: 8.1 },
      'XFER':        { a: 3.1, c: 4.6 },
      '-PA-':        { a: 2.7, c: 3.9 },
      'DEFAULT':     { a: 20,  c: 50 }
    },
    SACVD: {
      'NOSCRBUSG2K': { a: 7.5, c: 11.1 },
      'NOSCRB7K':    { a: 7.1, c: 13.1 },
      'HTN120_20':   { a: 4.1, c: 6.1 },
      'USG50':       { a: 5.1, c: 8.1 },
      'SABOX':       { a: 6.2, c: 8.8 },
      'XFER':        { a: 2.6, c: 3.9 },
      'DEFAULT':     { a: 20,  c: 50 }
    }
  },
  near2sigma: { diff: 1 },
  scoring: { lastN: 4 },
  liftup: { lastN: 3, compareM: 10, band: 2 }
};
let RULES = JSON.parse(JSON.stringify(DEFAULT_RULES));

/* ===================== 設定區結束 ===================== */

let lastNear2SigmaUnits = [];
let globalGroups = {};
let scoreRowsGlobal = [];
// 新增：保留原始匯入資料 + CHART_NAME 分群過濾
let rawJsonGlobal = [];
let chartInstances = []; // 追蹤已建立的 Chart.js 實例，重繪前先 destroy 避免記憶體洩漏
let currentChartNameFilter = 'ALL';
let currentProcessUnitSearch = '';


// （已取消）30天未進點功能
let oldUnitsSetGlobal = new Set();
let showOldUnitsInHighlight = false;




function applyChartNameFilter(data) {
  if (currentChartNameFilter === 'ALL') return data;
  const keyword = String(currentChartNameFilter || '').toUpperCase();

        // Partition 分頁：分群改用 CHART_NAME 關鍵字（PAR_1..8 / HTPA1..5 / LTPA1..5）
        if (String(currentTab || '').toUpperCase() === 'PARTITION') {
              return (data || []).filter(r => String(r.CHART_NAME || '').toUpperCase().includes(keyword));
        }



    // U%+RANGE 分頁：用 CHART_NAME + PARAMETER contains
  // 注意：是否能看到 RANGE，取決於後端 spc_data_tf2.aspx(tab=U) 是否也回傳 RANGE 的 rows
  if (String(currentTab || '').toUpperCase() === 'U') {
    const hay = (r) => (String(r.CHART_NAME || '') + ' ' + String(r.PARAMETER || '')).toUpperCase();
    return (data || []).filter(r => hay(r).includes(keyword));
  }


  // ADDER 分頁：依 TF2 現行代碼。OX50 為特例（含 OX50+SACVD、不含 NISACVD、不以 PEO 開頭）
  if (keyword === 'OX50') {
    return (data || []).filter(r => {
      const name = String(r.CHART_NAME || '').trim().toUpperCase();
      return name.includes('OX50') && name.includes('SACVD')
        && !name.includes('NISACVD') && !name.startsWith('PEO');
    });
  }
  return (data || []).filter(r => String(r.CHART_NAME || '').toUpperCase().includes(keyword));

}
/** =========================
*  新增：群組排序（B01 -> B02 -> B03 ...）
*  會同時影響：重點提示 / 評分表 / 圖表顯示順序
*  ========================= */
function getGroupSortKeyFromUnit(unitFullName) {
const parts = String(unitFullName || '').split('-');
const chamber = parts[2] || '';
const group = parts[3] || '';
const m = String(group).match(/B(\d+)/i);
const groupNo = m ? parseInt(m[1], 10) : 9999;
return { groupNo, chamber, unitFullName: String(unitFullName || '') };
}
function getSortedUnits(groupsObj) {
return Object.keys(groupsObj).sort((a, b) => {
const ka = getGroupSortKeyFromUnit(a);
const kb = getGroupSortKeyFromUnit(b);
if (ka.groupNo !== kb.groupNo) return ka.groupNo - kb.groupNo;
if (ka.chamber !== kb.chamber) return ka.chamber.localeCompare(kb.chamber);
return ka.unitFullName.localeCompare(kb.unitFullName);
});
}
// 顯示載入時間
(function showTime() {
const t = new Date();
const pad = n => String(n).padStart(2, '0');
const text = `更新時間：${t.getFullYear()}-${pad(t.getMonth()+1)}-${pad(t.getDate())} ${pad(t.getHours())}:${pad(t.getMinutes())}`;
document.getElementById('page-time').textContent = text;
})();
// ====== 執行狀態（SPC_API_URL 等設定見上方設定區）======
let currentTab = 'ADDER'; // ADDER / PARTITION / U

let currentProcessUnitGroup = 'ALL'; // ALL / NISACVD / SACVD

function setActiveTab(tab) {
  currentTab = tab;
  const btnAdder = document.getElementById('tab-adder');
  const btnThk = document.getElementById('tab-thk');
  const btnU = document.getElementById('tab-u');

  // 全部先設為未選取
  if (btnAdder) btnAdder.classList.add('btn-secondary');
  if (btnThk) btnThk.classList.add('btn-secondary');
  if (btnU) btnU.classList.add('btn-secondary');

  // 目前 tab 設為選取（移除 secondary）
  if (tab === 'ADDER') {
    if (btnAdder) btnAdder.classList.remove('btn-secondary');
  } else if (tab === 'PARTITION') {
    if (btnThk) btnThk.classList.remove('btn-secondary');
  } else if (tab === 'U') {
    if (btnU) btnU.classList.remove('btn-secondary');
  }

  // Partition 的分群提示
  const hint = document.getElementById('partition-hint');
  if (hint) hint.style.display = (String(tab).toUpperCase() === 'PARTITION') ? 'inline' : 'none';
}


async function fetchJsonOrThrow(url) {
  const res = await fetch(url, { method: 'GET' });
  if (!res.ok) {
    const t = await res.text();
    throw new Error(`載入 DB 失敗 HTTP ${res.status}: ${t}`);
  }
  return await res.json();
}

function setLoadStatus(text) {
  const el = document.getElementById('load-status');
  if (!el) return;
  if (!text) {
    el.style.display = 'none';
    el.textContent = '';
    return;
  }
  el.style.display = 'block';
  el.textContent = text;
}

function applyProcessUnitSearchFilter(data) {
  const kw = String(currentProcessUnitSearch || '').trim().toUpperCase();
  if (!kw) return data;
  return (data || []).filter(r => String(r.PROCESSUNIT || '').toUpperCase().includes(kw));
}

function applyProcessUnitGroupFilter(data) {
  const g = (currentProcessUnitGroup || 'ALL').toUpperCase();
  if (g === 'ALL') return data;


  // 依 CHART_NAME 判斷製程類型（NISACVD 字串含 SACVD，需先判 NISACVD）
  const isNISACVD = (name) => String(name || '').toUpperCase().includes('NISACVD');
  const isSACVD = (name) => {
    const u = String(name || '').toUpperCase();
    return u.includes('SACVD') && !u.includes('NISACVD');
  };

  if (g === 'NISACVD') return (data || []).filter(r => isNISACVD(r.CHART_NAME));
  if (g === 'SACVD') return (data || []).filter(r => isSACVD(r.CHART_NAME));
  return data;
}

function setActiveProcessUnitGroup(group) {
  currentProcessUnitGroup = group;

  const btnALL = document.getElementById('btn-group-all');
  const btnTU = document.getElementById('btn-group-tu');
  const btnABO = document.getElementById('btn-group-abo');

  // btn-secondary 代表未選取；選取時移除 secondary
  if (btnALL) btnALL.classList.add('btn-secondary');
  if (btnTU) btnTU.classList.add('btn-secondary');
  if (btnABO) btnABO.classList.add('btn-secondary');

  if (group === 'NISACVD') {
    if (btnTU) btnTU.classList.remove('btn-secondary');
  } else if (group === 'SACVD') {
    if (btnABO) btnABO.classList.remove('btn-secondary');
  } else {
    if (btnALL) btnALL.classList.remove('btn-secondary');
  }
}

async function loadDataFromDb() {
  const chartName = currentChartNameFilter || 'ALL';

  try {
    setLoadStatus('載入中：DB 查詢中...');

    const url = `${SPC_API_URL}?tab=${encodeURIComponent(currentTab)}&chartName=${encodeURIComponent(chartName)}&_=${Date.now()}`;
    const data = await fetchJsonOrThrow(url);

    rawJsonGlobal = data?.rows || [];

    setLoadStatus(`載入完成：資料列 ${rawJsonGlobal.length}，渲染中...`);

        let filtered = applyChartNameFilter(rawJsonGlobal);
    filtered = applyProcessUnitGroupFilter(filtered);
    filtered = applyProcessUnitSearchFilter(filtered);


    drawScoreTable(filtered);
    sortScoreTableBy('score', 'desc');

    const thUnit  = document.getElementById('th-unit');
    const thScore = document.getElementById('th-score');
    if (thScore) thScore.setAttribute('data-order', 'desc');
    if (thUnit)  thUnit.setAttribute('data-order', 'asc');

    drawCharts(filtered);
    showOnlyBadScoreCharts();

    setLoadStatus('');

  } catch (err) {
    console.error(err);
    setLoadStatus('');
    alert(String(err?.message || err));
  }
}





// chartname filter 切換 => 重抓 DB
document.getElementById('chartname-filter').addEventListener('change', (e) => {
  currentChartNameFilter = e.target.value;

  // Partition 的 LTPA/PAR_ 只需前端用 CHART_NAME 過濾即可（不需再打 API）
    if (String(currentTab || '').toUpperCase() === 'PARTITION') {
    const filtered = applyProcessUnitSearchFilter(applyProcessUnitGroupFilter(applyChartNameFilter(rawJsonGlobal)));
    drawScoreTable(filtered);
    sortScoreTableBy('score', 'desc');
    drawCharts(filtered);
    showOnlyBadScoreCharts();
    return;
  }


  loadDataFromDb();
});

// tab 切換 => 重抓 DB
document.getElementById('tab-adder')?.addEventListener('click', () => {
  setActiveTab('ADDER');

    // ADDER 分群回復原本清單（包含 -PA-）
    const sel = document.getElementById('chartname-filter');
    if (sel) {
      sel.innerHTML = `
        <option value="ALL">全部</option>
        <option value="-PA-">-PA-</option>
        <option value="HTSIN130_11">HTSIN130_11</option>

      <option value="PEOX50A">PEOX50A</option>
      <option value="XFER">XFER</option>
      <option value="HTN4DCPA">HTN4DCPA</option>
      <option value="FSHTN4DCPA">FSHTN4DCPA</option>
      <option value="LTUSG250_20">LTUSG250_20</option>
      <option value="LTUSG2.5K">LTUSG2.5K</option>
      <option value="STIPURGE">STIPURGE</option>
      <option value="NOSCRB7K">NOSCRB7K</option>
      <option value="USG50">USG50</option>
      <option value="NOSCRBUSG2K">NOSCRBUSG2K</option>
      <option value="SABOX110">SABOX110</option>
      <option value="OX50">OX50</option>
      <option value="HTSIN120_2.0">HTSIN120_2.0</option>
    `;
    currentChartNameFilter = 'ALL';
    sel.value = 'ALL';
  }


  // 分頁切換時：載入該分頁的設定
  loadRules();
  rulesToForm();
  loadDataFromDb();
});
document.getElementById('tab-thk')?.addEventListener('click', () => {
  setActiveTab('PARTITION');

    // Partition 分群改成 CHART_NAME 關鍵字 LTPA / PAR_（與後端分類一致）
    const sel = document.getElementById('chartname-filter');
    if (sel) {
            sel.innerHTML = `
        <option value="ALL">全部</option>
        <optgroup label="PAR_">
          <option value="PAR_1">PAR_1</option>
          <option value="PAR_2">PAR_2</option>
          <option value="PAR_3">PAR_3</option>
          <option value="PAR_4">PAR_4</option>
          <option value="PAR_5">PAR_5</option>
          <option value="PAR_6">PAR_6</option>
          <option value="PAR_7">PAR_7</option>
          <option value="PAR_8">PAR_8</option>
        </optgroup>
        <optgroup label="PA">
          <option value="PAR_1">PA1</option>
          <option value="PAR_2">PA2</option>
          <option value="PAR_3">PA3</option>
          <option value="PAR_4">PA4</option>
          <option value="PAR_5">PA5</option>
        </optgroup>
        <optgroup label="LTPA">
          <option value="LTPA1">LTPA1</option>
          <option value="LTPA2">LTPA2</option>
          <option value="LTPA3">LTPA3</option>
          <option value="LTPA4">LTPA4</option>
          <option value="LTPA5">LTPA5</option>
        </optgroup>
      `;
      currentChartNameFilter = 'ALL';
      sel.value = 'ALL';
    }




  // 分頁切換時：載入該分頁的設定
  loadRules();
  rulesToForm();
  loadDataFromDb();
});

// U%+RANGE tab：同一 DB（後端 tab=U 請同時回傳 U% 與 RANGE）
document.getElementById('tab-u')?.addEventListener('click', () => {
  setActiveTab('U');

  // 分群改成：U% / RANGE
  const sel = document.getElementById('chartname-filter');
  if (sel) {
    sel.innerHTML = `
      <option value="ALL">全部</option>
      <option value="U%">U%</option>
      <option value="RANGE">RANGE</option>
    `;
    currentChartNameFilter = 'ALL';
    sel.value = 'ALL';
  }

  loadRules();
  rulesToForm();
  loadDataFromDb();
});



// tool group 切換（不重抓 DB，直接用前端 filter 重繪）
document.getElementById('btn-group-all')?.addEventListener('click', () => {
    setActiveProcessUnitGroup('ALL');
  const filtered = applyProcessUnitSearchFilter(applyProcessUnitGroupFilter(applyChartNameFilter(rawJsonGlobal)));
  drawScoreTable(filtered);
  sortScoreTableBy('score', 'desc');
  drawCharts(filtered);
  showOnlyBadScoreCharts();
});
document.getElementById('btn-group-tu')?.addEventListener('click', () => {
    setActiveProcessUnitGroup('NISACVD');
  const filtered = applyProcessUnitSearchFilter(applyProcessUnitGroupFilter(applyChartNameFilter(rawJsonGlobal)));
  drawScoreTable(filtered);
  sortScoreTableBy('score', 'desc');
  drawCharts(filtered);
  showOnlyBadScoreCharts();
});
document.getElementById('btn-group-abo')?.addEventListener('click', () => {
    setActiveProcessUnitGroup('SACVD');
  const filtered = applyProcessUnitSearchFilter(applyProcessUnitGroupFilter(applyChartNameFilter(rawJsonGlobal)));
  drawScoreTable(filtered);
  sortScoreTableBy('score', 'desc');
  drawCharts(filtered);
  showOnlyBadScoreCharts();
});

const RULE_TOOLTIPS = {
near2sigma: '接近 2σ 警戒：最後一點與 2σ 差距 < 1',
scoreBC: '評分 B/C：最後 4 筆 MEAN_VALUE 的平均',
liftup: '最近 3 點上升：最近3點平均高於最近10點平均 + 最近3點靠近 1σ 線'
};
// 已移除 Excel 匯入/讀取流程（改由 DB API 提供資料）

// 依你的命名規則，把完整 CHART_NAME 精簡成短名稱
// ===== Partition 分頁專用：CHART_NAME 拆解規則 =====
// 結構：NT-{製程}-{腔體}-{群組}-{recipe token}-{PAxxx}-ADDER-W{n}[-[Partition Eng]]
function partitionParse(fullName) {
  const parts = String(fullName || '').split('-');
  const isNT = parts[0] && parts[0].toUpperCase() === 'NT';
  const process = (isNT ? parts[1] : parts[0]) || '';
  const chamber = (isNT ? parts[2] : parts[1]) || '';      // 例 B01
  const group   = (isNT ? parts[3] : parts[2]) || '';      // A / B
  const recipeToken = (isNT ? parts[4] : parts[3]) || '';  // PAR_5 / LTPA5
  const waferRaw = parts.find(p => /^W\d+$/i.test(p)) || '';
  const wafer = waferRaw ? waferRaw.replace(/^W/i, '') : '';
  return { process, chamber, group, recipeToken, wafer };
}
// 機台：{製程}-{腔體}{群組}{W數字}  例 NISACVD-B01A1
function partitionMachineName(fullName) {
  const p = partitionParse(fullName);
  return `${p.process}-${p.chamber}${p.group}${p.wafer}`;
}
// Recipe：PA + recipe token 結尾數字  例 PAR_5/LTPA5 -> PA5
function partitionRecipe(fullName) {
  const m = String(partitionParse(fullName).recipeToken).match(/(\d+)$/);
  return m ? ('PA' + m[1]) : '';
}
// 圖名：去開頭 NT-、去 -ADDER-、[Partition Eng] 前的 - 拿掉
function partitionShortName(fullName) {
  return String(fullName || '')
    .replace(/^NT-/i, '')
    .replace(/-ADDER-/i, '-')
    .replace(/-\[Partition/i, '[Partition');
}

// ===== U%/Range 分頁專用：CHART_NAME 拆解規則 =====
// 結構：NT-{製程}-{腔體}-{recipe...}-{群組+wafer}-THK-{U%|RANGE}[-[Partition Eng]]（THK 可省略）
function uRangeParse(fullName) {
  const parts = String(fullName || '').split('-');
  const isNT = parts[0] && parts[0].toUpperCase() === 'NT';
  const base = isNT ? 1 : 0;

  // 製程/腔體：可能分開(SACVD-B01) 或相連(SACVDB01)
  let process, chamber, recipeStart;
  const joined = /^(NISACVD|SACVD)(B\d+\w*)$/i.exec(String(parts[base] || ''));
  if (joined) {
    process = joined[1];
    chamber = joined[2];
    recipeStart = base + 1;        // 相連：recipe 緊接其後
  } else {
    process = parts[base] || '';
    chamber = parts[base + 1] || '';
    recipeStart = base + 2;        // 分開：跳過 process、chamber
  }

  // 尾段標記：THK / U% / RANGE 最先出現者
  let tailIdx = parts.findIndex(p => /^(THK|U%|RANGE)$/i.test(String(p)));
  if (tailIdx < 0) tailIdx = parts.length;
  const groupWafer = parts[tailIdx - 1] || '';            // 群組+wafer（尾段前一段）
  const recipe = parts.slice(recipeStart, tailIdx - 1)    // recipe 段 ~ groupWafer 前
    .filter(s => URANGE_RECIPE_EXCLUDE.indexOf(String(s).toUpperCase()) < 0)
    .join('-');
  return { process, chamber, groupWafer, recipe };
}
function uRangeMachineName(fullName) {
  const p = uRangeParse(fullName);
  return `${p.process}-${p.chamber}${p.groupWafer}`;
}
function uRangeRecipe(fullName) { return uRangeParse(fullName).recipe; }
function uRangeShortName(fullName) {
  let s = String(fullName || '').replace(/^NT-/i, '').replace(/-\[Partition/i, '[Partition');
  // STIUSG5.5K / STIUSG5.6K：圖名結尾不需要 -U%
  if (/STIUSG5\.[56]K/i.test(s)) s = s.replace(/-U%(?=$|\[Partition)/i, '');
  return s;
}

function getShortUnitName(fullName) {
if (!fullName) return '';
if (String(currentTab || '').toUpperCase() === 'PARTITION') return partitionShortName(fullName);
if (/^(U|UTHK|RANGE)$/.test(String(currentTab || '').toUpperCase())) return uRangeShortName(fullName);
const parts = fullName.split('-');
const toolType   = parts[1] || '';
const chamber    = parts[2] || '';
const group      = parts[3] || '';
const recipe     = parts[4] || '';
const waferStage = parts[parts.length - 1] || '';
return `${toolType}-${chamber}-${group}-${recipe}-${waferStage}`;
}

/* ===== 新增：抓 BS020 / PA009 這類 token，並加到圖表標題 ===== */
function extractExtraTokensFromChartName(fullName) {
  const s = String(fullName || '').toUpperCase();
  const tokens = [];

  // BS020 / BS002 ...
  const bs = s.match(/\bBS\d{3,5}\b/g);
  if (bs) tokens.push(...bs);

  // PA009 / PA123 ...
  const pa = s.match(/\bPA\d{3,5}\b/g);
  if (pa) tokens.push(...pa);

  // 去重
  return Array.from(new Set(tokens));
}

function getShortUnitNameWithTokens(fullName) {
  if (String(currentTab || '').toUpperCase() === 'PARTITION') return partitionShortName(fullName);
  if (/^(U|UTHK|RANGE)$/.test(String(currentTab || '').toUpperCase())) return uRangeShortName(fullName);
  const base = getShortUnitName(fullName);
  const tokens = extractExtraTokensFromChartName(fullName);
  return tokens.length ? `${base} (${tokens.join(',')})` : base;
}

// 例：NT-TEOSPE-B08-A-TEOS0.5K-PA009-ADDER-W1 → B08A1
function getScoreTableDisplayName(fullName) {
  if (!fullName) return '';
  if (String(currentTab || '').toUpperCase() === 'PARTITION') return partitionMachineName(fullName);
  if (/^(U|UTHK|RANGE)$/.test(String(currentTab || '').toUpperCase())) return uRangeMachineName(fullName);

  // 目標顯示格式：
  // APF-B01-A-900PURG-W1  => A-B01A1
  // 也支援：NT-TEOSPE-B08-A-TEOS0.5K-PA009-ADDER-W1 => T-B08A1

  const parts = String(fullName).split('-');

  // toolType 可能在 [0] 或 [1]（有些帶 NT- 前綴）
  const toolType = (parts[0] && parts[0].toUpperCase() === 'NT') ? (parts[1] || '') : (parts[0] || '');

  // group 通常為 Bxx
  const groupRaw = parts.find(p => /^B\d+/i.test(p)) || '';
  const group = groupRaw ? groupRaw.toUpperCase() : '';

  // chamber 通常為 A/B/C
  const chamberRaw = parts.find(p => /^[ABC]$/i.test(p)) || '';
  const chamber = chamberRaw ? chamberRaw.toUpperCase() : '';

  // wafer 通常為 W<number>
  const waferRaw = parts.find(p => /^W\d+$/i.test(p)) || '';
  const waferNum = waferRaw ? waferRaw.replace(/^W/i, '') : '';

  const toolShort = toolType ? toolType[0].toUpperCase() : '';
  return `${toolShort}-${group}${chamber}${waferNum}`;
}
// Excel 日期數字轉 JS 日期字串
function excelDateToJSDate(serial) {
var utc_days  = Math.floor(serial - 25569);
var utc_value = utc_days * 86400;
var date_info = new Date(utc_value * 1000);
var fractional_day = serial - Math.floor(serial) + 0.0000001;
var total_seconds = Math.floor(86400 * fractional_day);
var seconds = total_seconds % 60;
var hours = Math.floor(total_seconds / 3600);
var minutes = Math.floor(total_seconds / 60) % 60;
date_info.setHours(hours);
date_info.setMinutes(minutes);
date_info.setSeconds(seconds);
return date_info.getFullYear() + '-' +
String(date_info.getMonth() + 1).padStart(2, '0') + '-' +
String(date_info.getDate()).padStart(2, '0') + ' ' +
String(hours).padStart(2, '0') + ':' +
String(minutes).padStart(2, '0');
}
function formatDateTime(d) {
  if (!d || isNaN(d.getTime())) return '';
  const pad = n => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

function normalizeUpdateTimeToLabel(updateTime) {
  const d = parseUpdateTimeToDate(updateTime);
  return d ? formatDateTime(d) : String(updateTime ?? '');
}

/* ====== UPDATE_TIME 解析 + 30天判斷（支援 /Date(ms)/） ====== */
function parseUpdateTimeToDate(updateTime) {
  if (updateTime == null) return null;

  // ASP.NET JSON DateTime format: "/Date(1768525200000)/"
  const m = String(updateTime).match(/\/Date\((-?\d+)\)\//);
  if (m && m[1]) {
    const ms = parseInt(m[1], 10);
    return isNaN(ms) ? null : new Date(ms);
  }

  if (typeof updateTime === 'number') {
    return new Date(excelDateToJSDate(updateTime));
  }

  const s = String(updateTime || '').trim();
  if (!s) return null;
  const d = new Date(s.replace(' ', 'T'));
  return isNaN(d.getTime()) ? null : d;
}
function isOverDaysFromNow(dateObj, days) {
if (!dateObj) return false;
return (Date.now() - dateObj.getTime()) > days * 24 * 60 * 60 * 1000;
}
// ====== 評分規則／門檻（TF2_RECIPE_ORDER / DEFAULT_RULES / RULES）已移至上方設定區 ======

function getRulesStorageKey() {
  // 各分頁分開存
  const tab = String(currentTab || 'ADDER').toUpperCase();
  if (tab === 'PARTITION') return 'spc_rules_v1_PARTITION';
  if (tab === 'U') return 'spc_rules_v1_U';
  return 'spc_rules_v1_ADDER';
}


function loadRules() {
  try {
    const key = getRulesStorageKey();
    const raw = localStorage.getItem(key);
    if (!raw) {
      RULES = JSON.parse(JSON.stringify(DEFAULT_RULES));
      return;
    }
    const obj = JSON.parse(raw);
    if (obj && typeof obj === 'object') {
      const sc = obj.score || {};
      // 以預設為底，深層併入已存的 recipe 門檻（proc -> recipe -> {a,c}）
      const mergedScore = JSON.parse(JSON.stringify(DEFAULT_RULES.score));
      ['NISACVD', 'SACVD'].forEach(proc => {
        if (sc[proc] && typeof sc[proc] === 'object') {
          Object.keys(sc[proc]).forEach(key => {
            mergedScore[proc][key] = { ...(mergedScore[proc][key] || {}), ...sc[proc][key] };
          });
        }
      });
      RULES = {
        score: mergedScore,
        scoring: { ...DEFAULT_RULES.scoring, ...(obj.scoring || {}) },
        near2sigma: { ...DEFAULT_RULES.near2sigma, ...(obj.near2sigma || {}) },
        liftup: { ...DEFAULT_RULES.liftup, ...(obj.liftup || {}) }
      };
    }
  } catch (e) {
    console.warn('loadRules failed', e);
    RULES = JSON.parse(JSON.stringify(DEFAULT_RULES));
  }
}
function saveRules() {
  const key = getRulesStorageKey();
  localStorage.setItem(key, JSON.stringify(RULES));
}

// 依 RULES.score 動態產生 recipe 門檻欄位（NISACVD/SACVD 各 recipe + 其他預設）
function renderScoreThresholdFields() {
  const cont = document.getElementById('score-thr-container');
  if (!cont) return;
  cont.innerHTML = '';
  ['NISACVD', 'SACVD'].forEach(proc => {
    const map = (RULES.score && RULES.score[proc]) || {};
    const head = document.createElement('div');
    head.style.cssText = 'grid-column:1/-1;font-weight:800;color:#0f4aa8;margin-top:6px;';
    head.textContent = proc;
    cont.appendChild(head);
    (TF2_RECIPE_ORDER[proc] || []).concat(['DEFAULT']).forEach(key => {
      const thr = map[key] || {};
      [['a', 'A 上限'], ['c', 'C 下限']].forEach(pair => {
        const ac = pair[0], lab = pair[1];
        const field = document.createElement('div');
        field.className = 'settings-field';
        const label = document.createElement('label');
        label.textContent = (key === 'DEFAULT' ? '其他(預設)' : key) + '：' + lab;
        const input = document.createElement('input');
        input.type = 'number';
        input.step = '0.1';
        input.value = (thr[ac] != null ? thr[ac] : '');
        input.setAttribute('data-proc', proc);
        input.setAttribute('data-key', key);
        input.setAttribute('data-ac', ac);
        field.appendChild(label);
        field.appendChild(input);
        cont.appendChild(field);
      });
    });
  });
}

function rulesToForm() {
  renderScoreThresholdFields(); // 依 RULES.score 產生 recipe 門檻欄位
  document.getElementById('set-score-lastn').value = RULES.scoring.lastN;
  document.getElementById('set-near2-diff').value = RULES.near2sigma.diff;
  document.getElementById('set-rise-lastn').value = RULES.liftup.lastN;
  document.getElementById('set-rise-compare').value = RULES.liftup.compareM;
  document.getElementById('set-rise-band').value = RULES.liftup.band;
}


function formToRules() {
  const f = id => parseFloat(document.getElementById(id).value);
  const fi = id => parseInt(document.getElementById(id).value, 10);

  // 讀回 recipe 門檻（proc -> recipe -> {a,c}）
  document.querySelectorAll('#score-thr-container input[data-proc]').forEach(inp => {
    const proc = inp.getAttribute('data-proc');
    const key = inp.getAttribute('data-key');
    const ac = inp.getAttribute('data-ac');
    const v = parseFloat(inp.value);
    if (!RULES.score[proc]) RULES.score[proc] = {};
    if (!RULES.score[proc][key]) RULES.score[proc][key] = {};
    if (Number.isFinite(v)) RULES.score[proc][key][ac] = v;
  });

  RULES.scoring.lastN = Math.max(1, fi('set-score-lastn'));
  RULES.near2sigma.diff = f('set-near2-diff');
  RULES.liftup.lastN = fi('set-rise-lastn');
  RULES.liftup.compareM = fi('set-rise-compare');
  RULES.liftup.band = f('set-rise-band');
}



// ====== TF2 評分判定函式（門檻/順序/預設值見上方設定區）======
// 比對對象 = CHART_NAME（不用 RECIPE 欄，因常為 *INCLUDE）；規則：值<=a → A；a<值<c → B；值>=c → C
function tf2ClassifyProcess(hay) {
  if (hay.includes('NISACVD')) return 'NISACVD'; // 含 SACVD，需先判 NISACVD
  if (hay.includes('SACVD')) return 'SACVD';
  return null;
}
function tf2GetThreshold(proc, hay) {
  const map = (RULES.score && RULES.score[proc]) || {};
  const order = TF2_RECIPE_ORDER[proc] || [];
  for (let i = 0; i < order.length; i++) {
    if (hay.indexOf(String(order[i]).toUpperCase()) >= 0) {
      return map[order[i]] || map.DEFAULT || TF2_SCORE_DEFAULT;
    }
  }
  return map.DEFAULT || TF2_SCORE_DEFAULT;
}
function tf2ScoreByThreshold(value, a, c) {
  if (value <= a) return 'A';
  if (value < c) return 'B';
  return 'C';
}
// U%：依各 chart spec（管制線）判斷
// - 觸發 UCL => C
// - 介於 +2σ ~ UCL => B
// - 其他 => A
function tf2ScoreByUPercentSpec(value, xbar, sigma, ucl) {
  const v = Number(value);
  const xb = Number(xbar);
  const sg = Number(sigma);
  const u = Number(ucl);

  if (!Number.isFinite(v) || !Number.isFinite(xb) || !Number.isFinite(sg)) return '-';

  const plus2 = xb + 2 * sg;

  // 若 UCL 無效，仍可用 +2σ 做 A/B
  if (!Number.isFinite(u)) {
    return v > plus2 ? 'B' : 'A';
  }

  if (v >= u) return 'C';
  if (v > plus2) return 'B';
  return 'A';
}


// 取得在 CHART_NAME 比對到的 recipe 關鍵字（與評分一致）；用於評分表顯示
function tf2MatchedRecipeKey(unit, processunit) {
  const idHay = (String(processunit || '') + ' ' + String(unit || '')).toUpperCase();
  const proc = tf2ClassifyProcess(idHay);
  if (!proc) return '';
  const hay = String(unit || '').toUpperCase();
  const order = TF2_RECIPE_ORDER[proc] || [];
  for (let i = 0; i < order.length; i++) {
    if (hay.indexOf(String(order[i]).toUpperCase()) >= 0) return order[i];
  }
  // 比對不到就回空字串：由外層 fallback 顯示 DB 原始 RECIPE（不顯示「其他」）
  return '';
}


// 評分規則（TF2）：ADDER/PARTITION 依 spec recipe 門檻；U% 依各 chart spec
function getScore(unit, value, ctx) {
  ctx = ctx || {};
  const tab = String(ctx.tab || currentTab || 'ADDER').toUpperCase();

  // U%：TRIGGER UCL => C；+2σ => B；其他 => A
  if (tab === 'U') {
    return tf2ScoreByUPercentSpec(value, ctx.xbar, ctx.sigma, ctx.ucl);
  }


  const idHay = (String(ctx.processunit || '') + ' ' + String(unit || '')).toUpperCase();
  const proc = tf2ClassifyProcess(idHay);
  if (!proc) return '-';

  // 只用 CHART_NAME 比對 recipe 關鍵字（不用 RECIPE 欄，因常為 *INCLUDE 會誤判）
  const recipeHay = String(unit || '').toUpperCase();
  const thr = tf2GetThreshold(proc, recipeHay);
  return tf2ScoreByThreshold(value, Number(thr.a), Number(thr.c));
}
// 評分表格：計算並準備資料
function drawScoreTable(data) {
const groups = {};
data.forEach(row => {
const unit = row.CHART_NAME;
if (!groups[unit]) groups[unit] = [];
groups[unit].push(row);
});
globalGroups = groups;

const scoreRows = [];
getSortedUnits(groups).forEach(unit => {


  const rows = groups[unit];
  rows.sort((a, b) => {
    const ta = typeof a.UPDATE_TIME === 'number' ? excelDateToJSDate(a.UPDATE_TIME) : a.UPDATE_TIME;
    const tb = typeof b.UPDATE_TIME === 'number' ? excelDateToJSDate(b.UPDATE_TIME) : b.UPDATE_TIME;
    return new Date(ta) - new Date(tb);
  });

        const lastRow = rows[rows.length - 1];

    // RECIPE 欄顯示規則：
  // - U% 分頁：DB 的 RECIPE 常為 "*INCLUDE"（顯示會一堆 *），改顯示 CHART_NAME（或可視需要再縮短）
  // - 其他分頁：
  //   1) 優先顯示：在 CHART_NAME 比對到的 recipe key（例如 HTSIN130_11）
  //   2) 比對不到：改顯示 DB 原始 RECIPE（去掉結尾 -A/-B/-C），不要顯示「其他」
  const tabUpper = String(currentTab || '').toUpperCase();
  const dbRecipe = lastRow ? String(lastRow.RECIPE || '').replace(/-[ABC].*$/i, '') : '';

  let recipe = '';
    if (tabUpper === 'U' || tabUpper === 'UTHK' || tabUpper === 'RANGE') {
      // U%/Range：腔體後 ~ 群組wafer 前的 recipe 段（排除 URANGE_RECIPE_EXCLUDE）
      recipe = uRangeRecipe(unit);
    } else if (tabUpper === 'PARTITION') {
      // Partition：PA + recipe token 結尾數字（PAR_5/LTPA5 -> PA5）
      recipe = partitionRecipe(unit);
    } else {
    recipe = tf2MatchedRecipeKey(unit, lastRow ? lastRow.PROCESSUNIT : '');
    if (!recipe) recipe = dbRecipe;
  }



    const nAvg = Math.max(1, parseInt(RULES?.scoring?.lastN ?? 4, 10));
  const lastNRows = rows.slice(-nAvg);
  const sum = lastNRows.reduce((acc, r) => acc + Number(r.MEAN_VALUE || 0), 0);
  const meanValue = sum / lastNRows.length;
  // U%/RANGE 評分需要管制線：取整段 XBAR / SIGMA 平均
    const xbarsAll = rows.map(r => Number(r.XBAR)).filter(Number.isFinite);
  const sigmasAll = rows.map(r => Number(r.SIGMA)).filter(Number.isFinite);
  const uclsAll = rows.map(r => Number(r.UCL)).filter(Number.isFinite);

  const avgXbar = xbarsAll.length ? xbarsAll.reduce((a, b) => a + b, 0) / xbarsAll.length : NaN;
  const avgSigma = sigmasAll.length ? sigmasAll.reduce((a, b) => a + b, 0) / sigmasAll.length : NaN;
  const avgUcl = uclsAll.length ? uclsAll.reduce((a, b) => a + b, 0) / uclsAll.length : NaN;

  const score = getScore(unit, meanValue, {
    tab: currentTab,
    xbar: avgXbar,
    sigma: avgSigma,
    ucl: avgUcl,
    recipe: lastRow ? lastRow.RECIPE : '',
    processunit: lastRow ? lastRow.PROCESSUNIT : ''
  });

  scoreRows.push({ unit, score, recipe });
});
// 預設評分表只顯示 B/C（A 不顯示）
scoreRowsGlobal = scoreRows.filter(r => r.score === 'B' || r.score === 'C');
renderScoreTable(scoreRowsGlobal);
setTimeout(bindScoreTableClick, 0);
}
function renderScoreTable(scoreRows) {
const tbody = document.querySelector('#score-table tbody');
tbody.innerHTML = '';
scoreRows.forEach(row => {
const displayName = getScoreTableDisplayName(row.unit);
const tr = document.createElement('tr');
tr.innerHTML = `
<td>
<span class="score-link" data-unit="${row.unit}" title="${row.unit}">
${displayName}
</span>
</td>
<td title="${(row.recipe || '').replace(/"/g,'&quot;')}">${row.recipe || ''}</td>
<td class="score-cell">
<span class="score-badge score-badge-${row.score}">${row.score}</span>
</td>
`;
tbody.appendChild(tr);
});
}
const scoreOrder = { 'A': 1, 'B': 2, 'C': 3, '-': 99 };
function sortScoreTableBy(key, order) {
if (!scoreRowsGlobal || scoreRowsGlobal.length === 0) return;
const sorted = [...scoreRowsGlobal].sort((a, b) => {
if (key === 'unit') {
if (a.unit < b.unit) return order === 'asc' ? -1 : 1;
if (a.unit > b.unit) return order === 'asc' ? 1 : -1;
return 0;
} else if (key === 'score') {
const sa = scoreOrder[a.score] ?? 99;
const sb = scoreOrder[b.score] ?? 99;
return order === 'asc' ? sa - sb : sb - sa;
}
return 0;
});
renderScoreTable(sorted);
setTimeout(bindScoreTableClick, 0);
}
function bindScoreTableClick() {
document.querySelectorAll('.score-link').forEach(link => {
link.onclick = function() {
const unit = this.getAttribute('data-unit');
showOnlyChart(unit);
};
});
}
function showOnlyChart(unit) {
document.querySelectorAll('.chart-container').forEach(div => {
const match = div.getAttribute('data-unit') === unit;
if (match && div._buildChart) div._buildChart(); // 延後建立的圖：點選時才建
div.style.display = match ? '' : 'none';
});
document.getElementById('show-all-btn').style.display = 'inline-block';
}
function showOnlyBadScoreCharts() {
  // 建 unit -> score 的對照表
  const scoreMap = {};
  (scoreRowsGlobal || []).forEach(r => scoreMap[r.unit] = r.score);

  document.querySelectorAll('.chart-container').forEach(div => {
    const unit = div.getAttribute('data-unit');

    

    const s = scoreMap[unit] || '-';
    div.style.display = (s === 'C' || s === 'B') ? '' : 'none';
  });

  const btn = document.getElementById('show-all-btn');
  if (btn) btn.style.display = 'inline-block';
}
function showAllCharts() {
document.querySelectorAll('.chart-container').forEach(div => {
if (div._buildChart) div._buildChart(); // 延後建立的圖：顯示全部時才建
div.style.display = '';
});
const btn = document.getElementById('show-all-btn');
if (btn) btn.style.display = 'none';
}

function drawCharts(data) {
const groups = {};
data.forEach(row => {
const unit = row.CHART_NAME;
if (!groups[unit]) groups[unit] = [];
groups[unit].push(row);
});
// 重繪前銷毀舊圖表，避免 Chart.js 實例累積造成卡頓／記憶體洩漏
chartInstances.forEach(c => { try { c.destroy(); } catch (e) {} });
chartInstances = [];
document.getElementById('charts').innerHTML = '';
const near2SigmaUnits = [];
const liftUpUnits = [];

const scoreMap = {};
scoreRowsGlobal.forEach(r => { scoreMap[r.unit] = r.score; });
// 先跑一次：判斷 near2sigma / liftup（依最後一點時間 > 30 天分流）
getSortedUnits(groups).forEach(unit => {
const rows = groups[unit];
rows.sort((a, b) => {
const ta = typeof a.UPDATE_TIME === 'number' ? excelDateToJSDate(a.UPDATE_TIME) : a.UPDATE_TIME;
const tb = typeof b.UPDATE_TIME === 'number' ? excelDateToJSDate(b.UPDATE_TIME) : b.UPDATE_TIME;
return new Date(ta) - new Date(tb);
});
const lastRow = rows[rows.length - 1];
const lastDate = parseUpdateTimeToDate(lastRow.UPDATE_TIME);
const isOld = false;
const meanValueLast = Number(lastRow.MEAN_VALUE);
const xbarLast = Number(lastRow.XBAR);
const sigmaLast = Number(lastRow.SIGMA);
const twoSigmaLast = xbarLast + 2 * sigmaLast;
// 距離 2σ 的絕對差
const diffAbs2 = Math.abs(meanValueLast - twoSigmaLast);
if (diffAbs2 <= Number(RULES?.near2sigma?.diff ?? 1)) {
near2SigmaUnits.push(unit);
}
const meanValuesRaw = rows.map(r => Number(r.MEAN_VALUE));
const xbarsAll = rows.map(r => Number(r.XBAR));
const sigmasAll = rows.map(r => Number(r.SIGMA));
const totalPoints = meanValuesRaw.length;
const lastN = Math.max(1, parseInt(RULES?.liftup?.lastN ?? 3, 10));
const compareM = Math.max(lastN, parseInt(RULES?.liftup?.compareM ?? 10, 10));
const band = Number(RULES?.liftup?.band ?? 2);

if (totalPoints >= lastN) {
const lastMStartIndex = Math.max(0, totalPoints - compareM);
const lastM = meanValuesRaw.slice(lastMStartIndex);
const avgLastM = lastM.reduce((a, b) => a + b, 0) / lastM.length;

const lastNArr = meanValuesRaw.slice(-lastN);
const avgLastN = lastNArr.reduce((a, b) => a + b, 0) / lastNArr.length;

const lastNIndices = Array.from({ length: lastN }, (_, i) => totalPoints - lastN + i);
const isAllNearOneSigma = lastNIndices.every(idx => {
const meanVal = meanValuesRaw[idx];
const xbar = xbarsAll[idx];
const sigma = sigmasAll[idx];
const oneSigmaLine = xbar + sigma;
return meanVal >= (oneSigmaLine - band) && meanVal <= (oneSigmaLine + band);
});

if (avgLastN > avgLastM && isAllNearOneSigma) {
liftUpUnits.push(unit);
}
}
});
lastNear2SigmaUnits = near2SigmaUnits;

// ====== 依最後一點時間，分流 B/C 清單 ======
const sortByGroup = (a, b) => {
const ka = getGroupSortKeyFromUnit(a);
const kb = getGroupSortKeyFromUnit(b);
if (ka.groupNo !== kb.groupNo) return ka.groupNo - kb.groupNo;
if (ka.chamber !== kb.chamber) return ka.chamber.localeCompare(kb.chamber);
return ka.unitFullName.localeCompare(kb.unitFullName);
};
const allB = Object.keys(scoreMap).filter(u => scoreMap[u] === 'B');
const allC = Object.keys(scoreMap).filter(u => scoreMap[u] === 'C');
const BUnits = [];
const CUnits = [];
allB.forEach(unit => {
const rows = groups[unit] || [];
if (!rows.length) return;
const lastRow = rows[rows.length - 1];
const lastDate = parseUpdateTimeToDate(lastRow.UPDATE_TIME);
BUnits.push(unit);
});
allC.forEach(unit => {
const rows = groups[unit] || [];
if (!rows.length) return;
const lastRow = rows[rows.length - 1];
const lastDate = parseUpdateTimeToDate(lastRow.UPDATE_TIME);
CUnits.push(unit);
});
BUnits.sort(sortByGroup);
CUnits.sort(sortByGroup);


// ====== highlight 組裝（3 欄 + RECIPE 合併） ======
const highlightDiv = document.getElementById('highlight-units');

// 把 row.RECIPE 做「合併 key」：TEOS0.5K-A/TEOS0.5K-B/TEOS0.5K-C → TEOS0.5K
function getRecipeGroupKey(recipeRaw) {
const s = String(recipeRaw || '').trim();
if (!s) return 'UNKNOWN';

// 忽略像 "*INCLUDE" 這種非 recipe 的雜項群組：
// 讓它併回 UNKNOWN（不另外產生一個群）
if (s.startsWith('*')) return 'UNKNOWN';

// U% 分頁：重點提示分類改為指定清單（以 PARAMETER/內容關鍵字做歸類）
if (String(currentTab || '').toUpperCase() === 'U') {
  const u = s.toUpperCase();
  const keys = ['WEEKLY','D2120U1920F','D2850U2550H','PHM2000','TEOS2.25KO','TEOS5K','D2120U1920PF','D860U790F'];
  for (var i = 0; i < keys.length; i++) {
    if (u.indexOf(keys[i]) >= 0) return keys[i];
  }
  return 'UNKNOWN';
}




// 其他分頁：原本做法（TEOS0.5K-A/TEOS0.5K-B/TEOS0.5K-C → TEOS0.5K）
return s.split('-')[0].trim() || 'UNKNOWN';
}


// 若同一顆(同 Tool/Group/Chamber/Wafer)同時存在 "[Partition Eng]" 與其他版本，
// 則「不顯示 Partition Eng」：保留非 Partition Eng 的那張。
function preferNonPartitionEng(unitsArr) {
  const map = new Map();
  (unitsArr || []).forEach(u => {
    const key = getScoreTableDisplayName(u);
    if (!key) return;

    const isPE = String(u).toUpperCase().includes('PARTITION ENG');

    // 若尚未有，直接放入
    if (!map.has(key)) {
      map.set(key, u);
      return;
    }

    const existing = map.get(key);
    const existingIsPE = String(existing).toUpperCase().includes('PARTITION ENG');

    // 已有的是 PE、新來的不是 PE => 用新來的取代（丟掉 PE）
    if (existingIsPE && !isPE) {
      map.set(key, u);
      return;
    }

    // 其他情況：維持既有（例如兩個都非 PE 或兩個都是 PE）
  });
  return Array.from(map.values());
}


// unit -> recipeGroup（取該 unit 最新一筆的 RECIPE）
const unitToRecipeGroup = {};
Object.keys(groups).forEach(unit => {
const rows = groups[unit];
if (!rows || rows.length === 0) return;
rows.sort((a, b) => {
const ta = typeof a.UPDATE_TIME === 'number' ? excelDateToJSDate(a.UPDATE_TIME) : a.UPDATE_TIME;
const tb = typeof b.UPDATE_TIME === 'number' ? excelDateToJSDate(b.UPDATE_TIME) : b.UPDATE_TIME;
return new Date(ta) - new Date(tb);
});
const lastRow = rows[rows.length - 1];
// U% 分頁分類看 PARAMETER 比較準
unitToRecipeGroup[unit] = getRecipeGroupKey(
  (String(currentTab || '').toUpperCase() === 'U') ? lastRow.PARAMETER : lastRow.RECIPE
);

});

// 依 recipeGroup 分桶
function bucketByRecipeGroup(unitsArr) {
const m = {};
(unitsArr || []).forEach(u => {
const key = unitToRecipeGroup[u] || 'UNKNOWN';
if (!m[key]) m[key] = [];
m[key].push(u);
});
return m;
}

// 套用「重覆則不顯示 Partition Eng」
const near2SigmaUnits2 = preferNonPartitionEng(near2SigmaUnits);
const BUnits2          = preferNonPartitionEng(BUnits);
const CUnits2          = preferNonPartitionEng(CUnits);
const liftUpUnits2     = preferNonPartitionEng(liftUpUnits);

const bNear2 = bucketByRecipeGroup(near2SigmaUnits2);
const bB     = bucketByRecipeGroup(BUnits2);
const bC     = bucketByRecipeGroup(CUnits2);
const bLift  = bucketByRecipeGroup(liftUpUnits2);




// recipeGroup 顯示順序
let recipeGroupOrder = [];

if (String(currentTab || '').toUpperCase() === 'U') {
  // U%：固定順序
  recipeGroupOrder = ['WEEKLY','D2120U1920F','D2850U2550H','PHM2000','TEOS2.25KO','TEOS5K','D2120U1920PF','D860U790F','UNKNOWN'];
} else {
  // 其他：依「機台數量」由多到少
  const recipeGroupSet = new Set();
  data.forEach(r => {
      const key = getRecipeGroupKey(
        (String(currentTab || '').toUpperCase() === 'U') ? r.PARAMETER : r.RECIPE
      );
      if (key) recipeGroupSet.add(key);
    });


  recipeGroupOrder = Array.from(recipeGroupSet).sort((a, b) => {
    // 不顯示 UNKNOWN；但排序時仍保留，後面會 return
    const ca = (bB[a]?.length || 0) + (bC[a]?.length || 0) + (bNear2[a]?.length || 0) + (bLift[a]?.length || 0);
    const cb = (bB[b]?.length || 0) + (bC[b]?.length || 0) + (bNear2[b]?.length || 0) + (bLift[b]?.length || 0);
    return cb - ca;
  });
}


const blocks = [];

recipeGroupOrder.forEach(recipeKey => {
// 不顯示 UNKNOWN 群組
if (recipeKey === 'UNKNOWN') return;

const rowsText = [];

const near2 = (bNear2[recipeKey] || []);
const bu    = (bB[recipeKey] || []);
const cu    = (bC[recipeKey] || []);
const lift  = (bLift[recipeKey] || []);




if (near2.length > 0) {
rowsText.push(
`<div class="highlight-row"><span class="highlight-label" title="${RULE_TOOLTIPS.near2sigma}">接近 2σ 警戒：</span>` +
near2.map(unit => {
const shortName = getScoreTableDisplayName(unit);
return `<span class="unit-link near2sigma" data-unit="${unit}" title="${unit}">${shortName}</span>`;
}).join('') + `</div>`
);
}

if (bu.length > 0) {
rowsText.push(
`<div class="highlight-row"><span class="highlight-label" title="${RULE_TOOLTIPS.scoreBC}">評分 B：</span>` +
bu.map(unit => {
const shortName = getScoreTableDisplayName(unit);
return `<span class="unit-link badscore-B" data-unit="${unit}" title="${unit}">${shortName}</span>`;
}).join('') + `</div>`
);
}

if (cu.length > 0) {
rowsText.push(
`<div class="highlight-row"><span class="highlight-label" title="${RULE_TOOLTIPS.scoreBC}">評分 C：</span>` +
cu.map(unit => {
const shortName = getScoreTableDisplayName(unit);
return `<span class="unit-link badscore-C" data-unit="${unit}" title="${unit}">${shortName}</span>`;
}).join('') + `</div>`
);
}

if (lift.length > 0) {
rowsText.push(
`<div class="highlight-row"><span class="highlight-label" title="${RULE_TOOLTIPS.liftup}">最近 3 點上升：</span>` +
lift.map(unit => {
const shortName = getScoreTableDisplayName(unit);
return `<span class="unit-link liftup" data-unit="${unit}" title="${unit}">${shortName}</span>`;
}).join('') + `</div>`
);
}



if (rowsText.length === 0) return;

blocks.push(
`<div class="recipe-block">
<div class="recipe-title">${recipeKey}</div>
${rowsText.join('')}
</div>`
);
});

if (blocks.length > 0) {
highlightDiv.style.display = 'block';
highlightDiv.innerHTML =
`<div id="highlight-units-title">重點提示</div>` +
`<div id="highlight-units-grid">${blocks.join('')}</div>`;
document.getElementById('show-all-btn').style.display = 'inline-block';


} else {
highlightDiv.style.display = 'none';
highlightDiv.innerHTML = '';
document.getElementById('show-all-btn').style.display = 'none';

}

setTimeout(() => {
document.querySelectorAll('.unit-link').forEach(link => {
link.onclick = function() {
const unit = this.getAttribute('data-unit');
showOnlyChart(unit);
};
});
}, 0);

// ====== charts ======
getSortedUnits(groups).forEach(unit => {
const rows = groups[unit];
rows.sort((a, b) => {
const ta = typeof a.UPDATE_TIME === 'number' ? excelDateToJSDate(a.UPDATE_TIME) : a.UPDATE_TIME;
const tb = typeof b.UPDATE_TIME === 'number' ? excelDateToJSDate(b.UPDATE_TIME) : b.UPDATE_TIME;
return new Date(ta) - new Date(tb);
});
const labels = rows.map(r => normalizeUpdateTimeToLabel(r.UPDATE_TIME));
const meanValuesRaw = rows.map(r => Number(r.MEAN_VALUE));
const ucl = rows.map(r => Number(r.UCL));
const uclValue = Math.max(...ucl);

const xbars = rows.map(r => {
  const v = Number(r.XBAR);
  return Number.isFinite(v) ? v : null;
});
const sigmas = rows.map(r => {
  const v = Number(r.SIGMA);
  return Number.isFinite(v) ? v : null;
});


// 線規則：
// - ADDER / PARTITION：用「平均」XBAR/SIGMA 畫水平線（符合你給的原生圖2）
// - U%：用每一筆 XBAR/SIGMA 畫線，但只顯示 +1/+2（不顯示 -1/-2）
const tabUpper = String(currentTab || '').toUpperCase();

let cl = [];
let plus1Sigma = [];
let minus1Sigma = [];
let plus2Sigma = [];
let minus2Sigma = [];

// 全部分頁：都用「平均」XBAR/SIGMA 畫水平線（你現在要的圖3風格）
{
  const xbarFinite = xbars.filter(v => Number.isFinite(v));
  const sigmaFinite = sigmas.filter(v => Number.isFinite(v));

  const avgXbar = xbarFinite.length ? (xbarFinite.reduce((a, b) => a + b, 0) / xbarFinite.length) : null;
  const avgSigma = sigmaFinite.length ? (sigmaFinite.reduce((a, b) => a + b, 0) / sigmaFinite.length) : null;

  cl = Array(labels.length).fill((avgXbar == null) ? 0 : avgXbar);

  plus1Sigma = Array(labels.length).fill((avgXbar == null || avgSigma == null) ? 0 : (avgXbar + avgSigma));

  plus2Sigma = Array(labels.length).fill((avgXbar == null || avgSigma == null) ? 0 : (avgXbar + 2 * avgSigma));

  // 已移除 -1/-2，不再需要
  minus1Sigma = Array(labels.length).fill(null);
  minus2Sigma = Array(labels.length).fill(null);
}




// Y 軸自動範圍（避免固定 ucl+5 比例怪）
const yCandidates = []
  .concat(meanValuesRaw)
  .concat(cl)
    .concat(plus1Sigma, plus2Sigma)

  .concat(Number.isFinite(uclValue) ? [uclValue] : []);
const finiteY = yCandidates.filter(v => Number.isFinite(v));
const yMinRaw = finiteY.length ? Math.min.apply(null, finiteY) : 0;
const yMaxRaw = finiteY.length ? Math.max.apply(null, finiteY) : 1;

const pad = Math.max(0.2, (yMaxRaw - yMinRaw) * 0.08);
const yMin = Math.max(0, yMinRaw - pad);
const yMax = Math.max(1, yMaxRaw + pad);

const meanValues = meanValuesRaw;
const meanValueColors = meanValuesRaw.map(_ => 'black');
const meanValueBorderColors = meanValuesRaw.map(_ => 'black');
const meanValueRadius = meanValuesRaw.map(_ => 4);

const container = document.createElement('div');
container.className = 'chart-container';
container.setAttribute('data-unit', unit);
let shortName = getShortUnitNameWithTokens(unit);
// U% 分頁：標題補上 U%，方便辨識
if (String(currentTab || '').toUpperCase() === 'U') {
  // 先把重複的 -U% 收斂成一個
  shortName = shortName.replace(/(?:-U%)+$/i, '-U%');
  // 若尾端沒有 U% 才補上
  if (!/-U%$/i.test(shortName)) shortName = `${shortName}-U%`;
}
container.innerHTML = `
<div class="chart-header">
<h3 class="chart-header-title"><strong>${shortName}</strong></h3>
<div class="chart-header-tag" title="${unit}">SPC 管制圖</div>
</div>
<canvas height="350"></canvas>
`;
document.getElementById('charts').appendChild(container);
const buildChart = () => {
if (container._chartBuilt) return;
const ctx = container.querySelector('canvas').getContext('2d');
chartInstances.push(new Chart(ctx, {
type: 'line',
data: {
labels,
datasets: [
{
label: 'MEAN_VALUE',
data: meanValues,
borderColor: 'black',
backgroundColor: 'rgba(0,0,0,0.1)',
pointStyle: 'triangle',
fill: false,
tension: 0.2,
borderWidth: 2,
pointBackgroundColor: meanValueColors,
pointBorderColor: meanValueBorderColors,
pointRadius: meanValueRadius,
datalabels: { display: false }
},
{
label: 'UCL',
data: Array(labels.length).fill(uclValue),
borderColor: 'red',
borderDash: [4, 2],
fill: false,
pointRadius: 0,
borderWidth: 2,
datalabels: { display: false }
},
{
label: 'XBAR (CL)',
data: cl,
borderColor: '#0f766e',
borderDash: [0, 0],
fill: false,
pointRadius: 0,
borderWidth: 2,
spanGaps: true,
datalabels: { display: false }
},
{
label: '+1σ (XBAR+σ)',
data: plus1Sigma,
borderColor: '#1976d2',
borderDash: [2, 2],
fill: false,
pointRadius: 0,
borderWidth: 2,
spanGaps: true,
datalabels: { display: false }
},
{
label: '+2σ (XBAR+2σ)',
data: plus2Sigma,
borderColor: 'orange',
borderDash: [6, 2],
fill: false,
pointRadius: 0,
borderWidth: 2,
spanGaps: true,
datalabels: { display: false }
}




]
},
options: {
animation: false,
responsive: false,
layout: { padding: { top: 16 } },




onClick: (evt, elements, chart) => {

const points = chart.getElementsAtEventForMode(
evt,
'nearest',
{ intersect: true },
true
);
if (!points.length) return;
const first = points[0];
const datasetIndex = first.datasetIndex;
const index = first.index;
if (datasetIndex !== 0) return; // 只允許點 MEAN_VALUE
const row = rows[index];
const timeLabel = labels[index];
openParticleModal(row, unit, timeLabel);
},
plugins: {
legend: {
  display: true,
  position: 'top',
  align: 'end',



  labels: {
    // 圖3：legend 顯示「線段樣式」（不是方框）
    usePointStyle: true,
    pointStyle: 'line',
        boxWidth: 44,
    boxHeight: 10,
    padding: 18,

    font: { size: 12, weight: '700' },

    // 強制包含所有 datasets（避免 +2σ 因為資料是 null 被 Chart.js 判定為 hidden 而不出現）
    filter: (item, data) => {
      return true;
    }
  },
  maxHeight: 40


},



title: { display: false },
datalabels: { display: false },
tooltip: {

callbacks: {
label: function(context) {
const idx = context.dataIndex;
const raw = meanValuesRaw[idx];
if (context.dataset.label === 'MEAN_VALUE') return 'MEAN_VALUE: ' + raw;
if (context.dataset.label === 'UCL') return 'UCL: ' + uclValue;
if (context.dataset.label === 'XBAR (CL)') return 'XBAR: ' + cl[idx];
if (context.dataset.label === '+1σ (XBAR+σ)') return '+1σ: ' + plus1Sigma[idx];

if (context.dataset.label === '+2σ (XBAR+2σ)') return '+2σ: ' + plus2Sigma[idx];


}
}
}
},
scales: {
x: { title: { display: true, text: '時間' } },
y: { title: { display: true, text: '測量值' }, min: yMin, max: yMax }

}
},
plugins: [ChartDataLabels]
}));
container._chartBuilt = true;
};
// 延後建圖：預設只建立會顯示的 B/C 圖，其餘存 builder，待「顯示全部／點選」時才建
const __scoreForUnit = scoreMap[unit] || '-';
if (__scoreForUnit === 'B' || __scoreForUnit === 'C') {
  buildChart();
} else {
  container._buildChart = buildChart;
}
});
}

// 綁定表頭排序點擊 + 自動載入 DB (預設 ADDER)
window.addEventListener('DOMContentLoaded', () => {
// load rules before first render
loadRules();
rulesToForm();

// ===== ProcessUnit 搜尋（按 Enter 才套用 + 可復原） =====
const puInput = document.getElementById('processunit-search');
const puReset = document.getElementById('processunit-reset');

function applyProcessUnitSearchAndRender() {
  const filtered = applyProcessUnitSearchFilter(applyProcessUnitGroupFilter(applyChartNameFilter(rawJsonGlobal)));
  drawScoreTable(filtered);
  sortScoreTableBy('score', 'desc');
  drawCharts(filtered);

  // 搜尋後：直接顯示全部 chart（不要只顯示 B/C）
  showAllCharts();
}

if (puInput) {
  puInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      currentProcessUnitSearch = puInput.value || '';
      applyProcessUnitSearchAndRender();
    }
  });
}

if (puReset) {
  puReset.addEventListener('click', () => {
    currentProcessUnitSearch = '';
    if (puInput) puInput.value = '';

    // 復原：回到進入時的畫面（只顯示置頂的 B/C chart）
    const filtered = applyProcessUnitSearchFilter(applyProcessUnitGroupFilter(applyChartNameFilter(rawJsonGlobal)));
    drawScoreTable(filtered);
    sortScoreTableBy('score', 'desc');
    drawCharts(filtered);
    showOnlyBadScoreCharts();
  });
}





// ===== Left toolbar actions =====
const ltChat = document.getElementById('lt-chat');
const ltSettings = document.getElementById('lt-settings');
const ltFav = document.getElementById('lt-fav');

function openSettings() {
  const m = document.getElementById('settings-modal');
  if (m) m.style.display = 'block';
}
function closeSettings() {
  const m = document.getElementById('settings-modal');
  if (m) m.style.display = 'none';
}

function setLeftToolActive(which) {
  const ids = ['lt-chat', 'lt-settings', 'lt-fav'];
  ids.forEach(id => {
    const el = document.getElementById(id);
    if (!el) return;
    el.classList.toggle('active', id === which);
  });
}

if (ltChat) ltChat.addEventListener('click', () => {
  setLeftToolActive('lt-chat');
  const panel = document.getElementById('ai-panel');
  const fab = document.getElementById('ai-fab');
  if (panel && fab) fab.click();
});
if (ltSettings) ltSettings.addEventListener('click', () => {
  setLeftToolActive('lt-settings');
  openSettings();
});
if (ltFav) ltFav.addEventListener('click', () => {
  setLeftToolActive('lt-fav');
  alert('收藏功能待新增：將支援收藏 CHART_NAME');
});

const btnCloseSettings = document.getElementById('settings-close');
if (btnCloseSettings) btnCloseSettings.addEventListener('click', closeSettings);
const modalSettings = document.getElementById('settings-modal');
if (modalSettings) modalSettings.addEventListener('click', (e) => {
  if (e.target && e.target.id === 'settings-modal') closeSettings();
});

const btnResetSettings = document.getElementById('settings-reset');
if (btnResetSettings) btnResetSettings.addEventListener('click', () => {
  RULES = JSON.parse(JSON.stringify(DEFAULT_RULES));
  saveRules();
  rulesToForm();
  if (rawJsonGlobal && rawJsonGlobal.length) {
    const filtered = applyProcessUnitSearchFilter(applyProcessUnitGroupFilter(applyChartNameFilter(rawJsonGlobal)));
    drawScoreTable(filtered);
    sortScoreTableBy('score', 'desc');
    drawCharts(filtered);
    showOnlyBadScoreCharts();
  }
});


const btnApplySettings = document.getElementById('settings-apply');
if (btnApplySettings) btnApplySettings.addEventListener('click', () => {
  formToRules();
  saveRules();
  if (rawJsonGlobal && rawJsonGlobal.length) {
    const filtered = applyProcessUnitSearchFilter(applyProcessUnitGroupFilter(applyChartNameFilter(rawJsonGlobal)));
    drawScoreTable(filtered);
    sortScoreTableBy('score', 'desc');
    drawCharts(filtered);
    showOnlyBadScoreCharts();
  }
  closeSettings();
});


const thUnit = document.getElementById('th-unit');
const thScore = document.getElementById('th-score');
if (thUnit) {
thUnit.addEventListener('click', () => {
const currentOrder = thUnit.getAttribute('data-order') || 'asc';
const newOrder = currentOrder === 'asc' ? 'desc' : 'asc';
thUnit.setAttribute('data-order', newOrder);
thScore.setAttribute('data-order', 'asc');
sortScoreTableBy('unit', newOrder);
});
}
if (thScore) {
thScore.addEventListener('click', () => {
const currentOrder = thScore.getAttribute('data-order') || 'asc';
const newOrder = currentOrder === 'asc' ? 'desc' : 'asc';
thScore.setAttribute('data-order', newOrder);
thUnit.setAttribute('data-order', 'asc');
sortScoreTableBy('score', newOrder);
});
}
// ★ 開啟網頁就自動載入 DB（預設 ADDER）
setActiveTab('ADDER');
setActiveProcessUnitGroup('ALL');
loadDataFromDb();
});
function buildParticleMapUrl(row) {
  const chartId  = row.CHART_ID;
  const chartSeq = row.CHART_SEQ;

  // PointValue 用原始值（避免科學記號或 null 造成後端判斷失敗）
  const pointVal = (row.MEAN_VALUE == null) ? '' : String(row.MEAN_VALUE);

    const tab = String(currentTab || '').toUpperCase();

  // U%：用 Contour
  if (tab === 'U') {
    return (
      `http://10.10.101.170/Project1/_Contour_Multi.asp` +
      `?site=12AP58` +
      `&ChartID=${encodeURIComponent(chartId)}` +
      `&ChartSEQ=${encodeURIComponent(chartSeq)}` +
      `&PointValue=${encodeURIComponent(pointVal)}`
    );
  }

  // ADDER / PARTITION：沿用舊 Blob ShowImage（你提供的範例）
  return (
    `http://10.10.101.170/Project1/_Blob_ShowImage_4WebResultLoop.asp` +
    `?site=12AP58` +
    `&uchart_id=${encodeURIComponent(chartId)}` +
    `&chart_seq=${encodeURIComponent(chartSeq)}` +
    `&PointValue=${encodeURIComponent(pointVal)}`
  );

}


function openParticleModal(row, unit, timeLabel) {
if (!row || !row.CHART_ID || !row.CHART_SEQ) {
alert('找不到 CHART_ID / CHART_SEQ，無法開啟 particle map');
return;
}

const url = buildParticleMapUrl(row);
const modal = document.getElementById('particle-modal');
const iframe = document.getElementById('particle-iframe');
const title = document.getElementById('particle-title');
title.textContent = `Particle Map｜${getScoreTableDisplayName(unit)}｜${timeLabel}｜ID=${row.CHART_ID}｜SEQ=${row.CHART_SEQ}｜MEAN=${row.MEAN_VALUE}`;

// 先清空再載入，避免同 URL 時 iframe 不刷新
iframe.src = 'about:blank';
modal.style.display = 'block';
setTimeout(() => {
  iframe.src = url;
}, 0);
}

function closeParticleModal() {
const modal = document.getElementById('particle-modal');
const iframe = document.getElementById('particle-iframe');
modal.style.display = 'none';
iframe.src = 'about:blank';
}
window.addEventListener('DOMContentLoaded', () => {
const modal = document.getElementById('particle-modal');
const btnClose = document.getElementById('particle-close');
if (btnClose) btnClose.addEventListener('click', closeParticleModal);
// 點黑底關閉
if (modal) {
modal.addEventListener('click', (e) => {
if (e.target === modal) closeParticleModal();
});
}
// ESC 關閉
document.addEventListener('keydown', (e) => {
if (e.key === 'Escape') closeParticleModal();
});
});
window.addEventListener('DOMContentLoaded', () => {
const btn = document.getElementById('back-to-top');
if (!btn) return;
function shouldShow() {
const scrollY = window.scrollY || document.documentElement.scrollTop || 0;
return scrollY > 300;
}
function update() {
btn.style.display = shouldShow() ? 'inline-block' : 'none';
}
window.addEventListener('scroll', update, { passive: true });
window.addEventListener('resize', update);
update();
btn.addEventListener('click', () => {
window.scrollTo({ top: 0, behavior: 'smooth' });
});
});
</script>
<!-- Particle Map Modal -->
<div id="particle-modal" style="display:none; position:fixed; inset:0; background:rgba(0,0,0,.55); z-index:9999;">
<div style="position:absolute; left:4vw; top:4vh; width:92vw; height:92vh; background:#fff; border-radius:10px; overflow:hidden; box-shadow:0 10px 30px rgba(0,0,0,.35);">
<div style="height:44px; display:flex; align-items:center; justify-content:space-between; padding:0 10px; background:#1565c0; color:#fff;">
<div id="particle-title" style="font-size:13px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">
Particle Map
</div>
<button id="particle-close" class="btn-primary" style="background:#0d47a1; box-shadow:none;">關閉</button>
</div>
<iframe id="particle-iframe" src="about:blank" style="width:100%; height:calc(100% - 44px); border:0;"></iframe>
</div>
</div>
<button id="back-to-top" type="button" title="回到最上面">TOP</button>

<!-- =========================
     AI Q&A Dock
     - 注意：AiApiKey 不應放在前端。
     - 建議：由 IIS/ASP.NET 端提供 /api/ai/chat 之類的 proxy，再由前端呼叫。
     ========================= -->
<div id="ai-dock" aria-live="polite">
  <button id="ai-fab" type="button" title="開啟 AI 問答">AI 問答</button>
  <div id="ai-panel" role="dialog" aria-modal="false" aria-label="AI 問答窗格">
    <div id="ai-head">
      <div>
        <div id="ai-head-title">設備工程小助手</div>
        <div id="ai-status">就緒</div>
      </div>
      <div id="ai-head-actions">
        <button id="ai-clear" class="ai-head-btn" type="button">清除</button>
        <button id="ai-close" class="ai-head-btn" type="button">關閉</button>
      </div>
    </div>
    <div id="ai-log"></div>
    <div id="ai-compose">
      <textarea id="ai-input" placeholder="請輸入問題（例如：這張 SPC 報表中，哪些機台評分 C？原因可能是什麼？）"></textarea>
      <div id="ai-compose-row">
        <div id="ai-hint">提示：此頁面不會直接帶入 API KEY；需後端 proxy 才能連線。</div>
        <button id="ai-send" type="button">送出</button>
      </div>
    </div>
  </div>
</div>

<script>
// ========== AI Dock 設定（請改成你的後端 proxy） ==========
// AI 設定（AI_PROXY_URL / AI_USER_ID / AI_SYSTEM_PROMPT）已移至上方主 script 的設定區

// 點 AI 回覆中的機台代號 → 跳到該台 chart
function applyFilterByDisplayToken(token) {
  const t = String(token || '').trim();
  if (!t) return;
  // 用顯示名稱反查 unit(CHART_NAME)：先找評分表(B/C)，找不到再找全部已載入機台（含 A 級）
  let hit = (scoreRowsGlobal || []).find(r => getScoreTableDisplayName(r.unit) === t);
  let unit = hit ? hit.unit : Object.keys(globalGroups || {}).find(u => getScoreTableDisplayName(u) === t);
  if (!unit) return;

  showOnlyChart(unit); // 只顯示該台 chart（延後建圖會即時補建）

  const puInput = document.getElementById('processunit-search');
  if (puInput) puInput.value = '';

  const charts = document.getElementById('charts');
  if (charts) charts.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

// 把 AI 回覆中像 A-B01A1 / T-B08A1 的機台代號變成可點 span（避免 innerHTML 注入）
function aiRenderClickableText(text) {
  const frag = document.createDocumentFragment();
  const s = String(text || '');
  const re = /\b([A-Z]{1,2}-B\d{2}[A-Z]\d*)\b/g;
  let last = 0, m;
  while ((m = re.exec(s)) !== null) {
    const start = m.index, end = start + m[0].length;
    if (start > last) frag.appendChild(document.createTextNode(s.slice(last, start)));
    const token = m[1];
    const span = document.createElement('span');
    span.textContent = token;
    span.style.cursor = 'pointer';
    span.style.color = '#1d4ed8';
    span.style.fontWeight = '900';
    span.style.textDecoration = 'underline';
    span.addEventListener('click', () => applyFilterByDisplayToken(token));
    frag.appendChild(span);
    last = end;
  }
  if (last < s.length) frag.appendChild(document.createTextNode(s.slice(last)));
  return frag;
}

function aiAppendBubble(role, text, extraClass) {
  const log = document.getElementById('ai-log');
  const div = document.createElement('div');
  div.className = `ai-bubble ${role}` + (extraClass ? ` ${extraClass}` : '');
  if (role === 'assistant') {
    div.appendChild(aiRenderClickableText(text)); // 機台代號可點 → 跳到該台 chart
  } else {
    div.textContent = text;
  }
  log.appendChild(div);
  log.scrollTop = log.scrollHeight;
}

function aiAppendImage(role, imgUrl, caption) {
  const log = document.getElementById('ai-log');
  const wrap = document.createElement('div');
  wrap.className = `ai-bubble ${role}`;

  const img = document.createElement('img');
  img.src = imgUrl;
  img.alt = caption || 'image';
  img.style.width = '100%';
  img.style.height = 'auto';
  img.style.borderRadius = '10px';
  img.style.border = '1px solid rgba(148,163,184,.35)';
  img.style.background = '#fff';

  wrap.appendChild(img);
  if (caption) {
    const cap = document.createElement('div');
    cap.style.marginTop = '6px';
    cap.style.fontSize = '11px';
    cap.style.color = '#64748b';
    cap.textContent = caption;
    wrap.appendChild(cap);
  }

  log.appendChild(wrap);
  log.scrollTop = log.scrollHeight;
}

function aiTryRenderImagesFromText(replyText) {
  // 支援：
  // 1) 圖1: http(s)://... 或 data:image/...
  // 2) CHART=... / MAP=...
  // 3) Markdown: ![alt](url)
  if (!replyText) return;
  const text = String(replyText);

  // Markdown image
  const mdRe = /!\[[^\]]*\]\(([^)]+)\)/g;
  let m;
  while ((m = mdRe.exec(text)) !== null) {
    const url = (m[1] || '').trim();
    if (url) aiAppendImage('assistant', url, '圖片');
  }

  // CHART= / MAP=
  const chartRe = /(CHART|圖1)\s*[:=]\s*(\S+)/ig;
  const mapRe   = /(MAP|map|圖2)\s*[:=]\s*(\S+)/ig;

  while ((m = chartRe.exec(text)) !== null) {
    const url = (m[2] || '').trim();
    if (url) aiAppendImage('assistant', url, 'CHART');
  }
  while ((m = mapRe.exec(text)) !== null) {
    const url = (m[2] || '').trim();
    if (url) aiAppendImage('assistant', url, 'MAP');
  }
}


function aiSetStatus(text) {
  const el = document.getElementById('ai-status');
  if (el) el.textContent = text;
}

function aiGetContextSnapshot() {
  // 把目前頁面的「篩選條件、分數統計、重點提示」帶給 AI，回答會更貼近你現在看的畫面
  const chartFilter = document.getElementById('chartname-filter')?.value || 'ALL';

  const scoreCounts = { A: 0, B: 0, C: 0, '-': 0 };
  (scoreRowsGlobal || []).forEach(r => {
    const k = (r.score in scoreCounts) ? r.score : '-';
    scoreCounts[k]++;
  });

  const topBC = (scoreRowsGlobal || [])
    .filter(r => r.score === 'C' || r.score === 'B')
    .slice(0, 30)
    .map(r => ({ unit: r.unit, display: getScoreTableDisplayName(r.unit), score: r.score }));

  return {
    page: 'SPC 管制圖儀表板 (ABC GRADE.html)',
    chartNameFilter: chartFilter,
    showOldUnitsInHighlight,
    scoreCounts,
    topBC,
    near2sigma: (lastNear2SigmaUnits || []).slice(0, 30).map(u => ({ unit: u, display: getScoreTableDisplayName(u) })),
  };
}

async function aiSend() {
  const input = document.getElementById('ai-input');
  const btn = document.getElementById('ai-send');
  const q = (input?.value || '').trim();
  if (!q) return;

  aiAppendBubble('user', q);
  input.value = '';
  btn.disabled = true;
  aiSetStatus('處理中...');

  // 組 payload（採用 OpenAI Chat Completions 常見格式）
  const context = aiGetContextSnapshot();
    const payload = {
    // OpenAI Chat Completions 參數名稱為 user（不是 userId）
    user: AI_USER_ID,
    messages: [
      { role: 'system', content: AI_SYSTEM_PROMPT },
      { role: 'system', content: '以下是使用者目前儀表板的狀態摘要（JSON）：\n' + JSON.stringify(context) },
      { role: 'system', content: '若你要回傳圖片，請用以下格式直接給 URL（同網域或可被瀏覽器讀取）：\nCHART=<image_url>\nMAP=<image_url>\n也可用 Markdown: ![chart](url) / ![map](url)；回答文字請精簡條列。' },
      { role: 'user', content: q }
    ]
  };

  try {
    const res = await fetch(AI_PROXY_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    if (!res.ok) {
      const t = await res.text();
      throw new Error(`HTTP ${res.status}: ${t}`);
    }

    const data = await res.json();

    // 兼容：你的 proxy 可以直接回 { reply: '...' }
    // 或回 OpenAI 標準：{ choices: [ { message: { content: '...' } } ] }
    const reply =
      data?.reply ??
      data?.choices?.[0]?.message?.content ??
      data?.choices?.[0]?.delta?.content ??
      '';

        if (!reply) throw new Error('AI 回傳內容為空（請確認 proxy 回傳格式）');
    aiAppendBubble('assistant', reply);

    // 若回覆內容有帶圖片 URL（圖1/圖2、CHART/MAP、或 Markdown 圖片），就直接顯示
    aiTryRenderImagesFromText(reply);

    aiSetStatus('就緒');
  } catch (err) {
    aiAppendBubble('assistant', String(err?.message || err), 'error');
    aiSetStatus('錯誤');
  } finally {
    btn.disabled = false;
  }
}

(function initAiDock(){
  const fab = document.getElementById('ai-fab');
  const panel = document.getElementById('ai-panel');
  const closeBtn = document.getElementById('ai-close');
  const clearBtn = document.getElementById('ai-clear');
  const sendBtn = document.getElementById('ai-send');
  const input = document.getElementById('ai-input');

  function open() {
      panel.classList.add('open');
      panel.style.display = 'flex';
      // keep transform from css
      setTimeout(() => input?.focus(), 0);
    }
  function close() {
      panel.classList.remove('open');
      panel.style.display = 'none';
      // reset transform just in case
      panel.style.transform = '';
    }

  fab?.addEventListener('click', () => {
    const isOpen = panel.classList.contains('open');
    isOpen ? close() : open();
  });
  closeBtn?.addEventListener('click', close);
  clearBtn?.addEventListener('click', () => {
    const log = document.getElementById('ai-log');
    if (log) log.innerHTML = '';
    aiSetStatus('就緒');
  });
  sendBtn?.addEventListener('click', aiSend);
  input?.addEventListener('keydown', (e) => {
    // Enter 送出 / Shift+Enter 換行
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      aiSend();
    }
  });

  // 初始提示
  aiAppendBubble('assistant', '我可以協助整理 defect lesson learn，也可以根據你目前的 SPC 分群/評分狀態做快速摘要。');
})();
</script>
</body>
</html>
