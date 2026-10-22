<%@ Page Language="C#" AutoEventWireup="true" Inherits="NPW_Inspection" CodeFile="NPW_inspection_tool.aspx.cs" EnableSessionState="false" %>
<!DOCTYPE html>
<html lang="zh-Hant">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>TF2/T_EQ1 NPW inspection tool</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.3.0/dist/chart.umd.min.js"></script>
    <style>
        :root { --bd: 2px solid #000; --accent: #1976d2; }
        * { box-sizing: border-box; }
        body { margin: 0; background: #f3f6fa; font-family: Arial, "Microsoft JhengHei", "PingFang TC", sans-serif; color: #111; font-size: 14px; }
        /* 滿版：不限制最大寬度，兩側只留 12px */
        .wrap { max-width: none; margin: 0; padding: 12px 12px 60px; }
        h1 { font-size: 20px; margin: 0 0 12px; }
        .card { background: #fff; border: 1px solid #d6dbe3; border-radius: 8px; padding: 12px 14px; margin-bottom: 14px; }
        .card h2 { font-size: 15px; margin: 0 0 10px; color: #0f4aa8; }
        .toolbar { display: flex; gap: 10px; align-items: flex-end; flex-wrap: wrap; }
        .field { display: flex; flex-direction: column; gap: 3px; font-size: 12px; color: #555; }
        .field input, .field select { padding: 6px 8px; border: 1px solid #b8c0cc; border-radius: 6px; font: inherit; font-size: 13px; min-width: 150px; }
        .field input[type=date] { min-width: 150px; }
        .radios { display: inline-flex; gap: 10px; padding: 6px 8px; border: 1px solid #b8c0cc; border-radius: 6px; background: #fff; font-size: 13px; color: #111; }
        .radios label { display: inline-flex; align-items: center; gap: 3px; cursor: pointer; }
        .field .radios input[type=radio] { min-width: 0; width: auto; padding: 0; margin: 0; }
        button { font: inherit; cursor: pointer; }
        .btn { padding: 6px 14px; border: 0; border-radius: 6px; background: var(--accent); color: #fff; font-weight: 700; }
        .btn.ghost { background: #fff; color: var(--accent); border: 1px solid var(--accent); }
        .btn.small { padding: 3px 8px; font-size: 12px; font-weight: 600; }
        .btn.danger { background: #fff; color: #c00; border: 1px solid #c00; }
        .btn:disabled { opacity: .5; cursor: default; }
        .quick { display: inline-flex; gap: 4px; }
        .status { font-size: 12px; color: #006400; }
        .status.err { color: #c00; }
        .hint { font-size: 12px; color: #666; }

        /* 搜尋結果 */
        /* 搜尋結果不用捲軸：表格依頁寬排版，長文字自動換行 */
        .res-wrap { overflow: visible; }
        table.res { border-collapse: collapse; width: 100%; background: #fff; }
        table.res th, table.res td { border: 1px solid #222; padding: 4px 6px; font-size: 12px; white-space: normal; word-break: break-word; }
        table.res th, table.res td.num, table.res td.c, table.res td.addcell, table.res td.tools { white-space: nowrap; }
        table.res th { background: #e9f0ff; font-weight: 700; position: sticky; top: 0; }
        table.res td.num { text-align: right; font-variant-numeric: tabular-nums; }
        table.res td.c { text-align: center; }
        table.res tr.vals td { background: #fafafa; white-space: normal; }
        table.res tr.added td { background: #fff8d6; }
        table.res td.addcell { white-space: nowrap; }
        table.res td.addcell select { padding: 3px 4px; border: 1px solid var(--accent); border-radius: 6px; color: var(--accent); font: inherit; font-size: 12px; font-weight: 700; margin-left: 4px; }
        .valbox { font-size: 11px; }   /* 明細全部展開，不用捲軸 */
        .valbox table { border-collapse: collapse; }
        .valbox td, .valbox th { border: 1px solid #ccc; padding: 2px 6px; }
        .valbox tr.excluded td { color: #999; text-decoration: line-through; background: #f6f6f6; }
        .valbox tr.excluded td:first-child { text-decoration: none; }
        .valbox .btn.small { padding: 1px 6px; font-size: 11px; }
        table.res tr.adjusted td:nth-child(6), table.res tr.adjusted td:nth-child(7), table.res tr.adjusted td:nth-child(8) { background: #fde9c9; }
        table.res .adjnote { font-size: 10px; color: #a35; margin-left: 2px; }
        table.res td.tools { white-space: nowrap; }
        table.res td.tools .btn + .btn { margin-left: 3px; }
        table.res tr.trend td { background: #fbfbfb; }
        .trendbox { position: relative; width: 100%; height: 300px; }
        .trendbox canvas { display: block; width: 100% !important; height: 100% !important; }
        /* Matching chart（比較） */
        .mchips { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 8px; }
        .mchip { display: inline-flex; align-items: center; gap: 6px; border: 1px solid #b8c0cc; border-radius: 14px; padding: 2px 8px 2px 6px; font-size: 12px; background: #fff; }
        .mchip .sw { width: 12px; height: 12px; border-radius: 3px; display: inline-block; }
        .mchip button { border: 0; background: transparent; color: #c00; cursor: pointer; font-weight: 700; padding: 0 2px; }
        .mbox { position: relative; width: 100%; height: 380px; }
        .mbox canvas { display: block; width: 100% !important; height: 100% !important; }
        table.mstat { border-collapse: collapse; margin-top: 8px; }
        table.mstat th, table.mstat td { border: 1px solid #222; padding: 3px 8px; font-size: 12px; white-space: nowrap; }
        table.mstat th { background: #e9f0ff; }
        table.mstat td.num { text-align: right; font-variant-numeric: tabular-nums; }
        .rpanel { margin: 8px 0; padding: 8px 10px; border: 1px dashed #1976d2; border-radius: 8px; background: #f6faff; }
        .rpanel table { margin-top: 6px; }
        .rpanel .tag { display: inline-block; padding: 1px 6px; border-radius: 4px; font-size: 11px; font-weight: 700; }
        .rpanel .tag.bsl { background: rgba(0,160,0,.18); border: 1px solid #0a0; color: #064; }
        .rpanel .tag.test { background: rgba(220,0,0,.18); border: 1px solid #c00; color: #800; }
        .rpanel select { padding: 2px 4px; border: 1px solid var(--accent); border-radius: 6px; color: var(--accent); font: inherit; font-size: 12px; font-weight: 700; }
        #btnRegion.on { background: var(--accent); color: #fff; }
        table.res button[data-match].on { background: #2e7d32; border-color: #2e7d32; color: #fff; }
        #matchCanvas.grab { cursor: grab; } #matchCanvas.resize { cursor: col-resize; } #matchCanvas.move { cursor: move; }

        /* 檢定表格（PCRB，沿用檢定機器人） */
        .pcrb-wrap { overflow-x: auto; }
        table.pcrb { border-collapse: collapse; width: 100%; table-layout: auto; }
        table.pcrb th, table.pcrb td { border: var(--bd); padding: 6px 8px; text-align: center; vertical-align: middle; }
        table.pcrb thead th { background: #fff6a5; font-weight: 700; }
        table.pcrb td.no { background: #e9f0ff; font-weight: 700; font-size: 16px; }
        table.pcrb td.item { background: #f3c19b; }
        table.pcrb td.item.green { background: #b9f0b7; }
        /* PU 欄：寬度隨內容長短變化（輸入框依字數設定 ch 寬度，欄寬收縮到最寬的那一列） */
        table.pcrb td.pu { background: #c9f6c9; text-align: left; width: 1%; white-space: nowrap; }
        table.pcrb td.pu input.cell { width: auto; min-width: 12ch; max-width: 70ch; }
        table.pcrb td.result { background: #9fc6ff; font-variant-numeric: tabular-nums; }
        table.pcrb td.verdict { font-weight: 700; }
        table.pcrb td.verdict.pass { background: #b9f0b7; color: #0a5c0a; }
        table.pcrb td.verdict.fail { background: #ffb3b3; color: #a00; }
        table.pcrb td.muted { color: rgba(0,0,0,.55); }
        table.pcrb input.cell { width: 100%; border: 0; outline: none; background: transparent; font: inherit; text-align: inherit; }
        table.pcrb input.num { text-align: right; font-variant-numeric: tabular-nums; }
        table.pcrb td.ops { white-space: nowrap; }
        table.pcrb tr.flash td { animation: flash 1.2s ease-out; }
        @keyframes flash { from { background-color: #ffe9a8; } to { } }
        .pcrb-actions { display: flex; gap: 8px; flex-wrap: wrap; align-items: center; margin-top: 10px; }
        .summary { font-size: 13px; margin-left: auto; }
        .summary b.pass { color: #0a5c0a; } .summary b.fail { color: #a00; }
    </style>
</head>
<body>
<div class="wrap">
    <h1>TF2/T_EQ1 NPW inspection tool（檢定）</h1>

    <!-- 1. 條件式搜尋 -->
    <div class="card">
        <h2>搜尋條件（資料來源：TF2_NPW_CHART）</h2>
        <div class="toolbar">
            <label class="field">Chart_ID<input id="qCid" type="text" placeholder="例 85766（精確）" autocomplete="off" /></label>
            <label class="field">Chart_name<input id="qName" type="text" placeholder="包含文字或用 %，例 %5.5K%PA%" autocomplete="off" /></label>
            <label class="field">機台（PROCESSUNIT）<input id="qPu" type="text" placeholder="包含文字或用 %，例 SACVD-B1%" autocomplete="off" /></label>
            <label class="field">開始時間<input id="qStart" type="datetime-local" step="60" /></label>
            <label class="field">結束時間<input id="qEnd" type="datetime-local" step="60" /></label>
            <span class="field">PROD Type
                <span class="radios" id="qProd">
                    <label><input type="radio" name="prod" value="ctrl" checked />內控</label>
                    <label><input type="radio" name="prod" value="ocap" />OCAP</label>
                </span>
            </span>
            <span class="quick">
                <button type="button" class="btn ghost small" data-days="7">近 7 天</button>
                <button type="button" class="btn ghost small" data-days="30">近 30 天</button>
                <button type="button" class="btn ghost small" data-days="90">近 90 天</button>
            </span>
            <button type="button" class="btn" id="btnSearch">搜尋</button>
            <span class="status" id="qStatus"></span>
        </div>
        <div class="hint" style="margin-top:6px;">Chart_ID / Chart_name / 機台 至少填一項（可組合）。Chart_name 與機台：不含 % 時為「包含」比對；可自行加 % 當萬用字元（例 <code>SACVD-B1%</code>、<code>%5.5K%PA%</code>），`_` 視為一般字元。時間區間依 <b>UPDATE_TIME</b>，可選到幾點幾分（結束時間含該分鐘），最長 400 天。每張 chart 只顯示一列：N = 筆數、AVG = MEAN_VALUE 平均、STDEVA = 樣本標準差（Excel STDEV.S / STDEVA），區間內所有 MEAN_VALUE 都納入。</div>
    </div>

    <!-- 2. 搜尋結果 -->
    <div class="card">
        <div class="toolbar" style="margin-bottom:8px;">
            <h2 style="margin:0;">搜尋結果 <small id="resInfo" class="hint"></small></h2>
            <span class="hint">每列右側下拉選「列編號」後按「加入檢定」，即以本次搜尋區間的 N / AVG / STDEVA 填入該列；填完下拉會自動跳到下一列</span>
            <button type="button" class="btn small" id="btnMatchAll" style="margin-left:auto;" title="把本次搜尋結果全部加入 Matching chart">全部加入 matching</button>
        </div>
        <div class="res-wrap">
            <table class="res" id="resTable">
                <thead>
                    <tr>
                        <th>加入</th><th>CHART_ID</th><th>CHART_NAME</th><th>機台</th><th>Type</th>
                        <th>N</th><th>AVG</th><th>STDEVA</th><th>Min</th><th>Max</th><th>首筆</th><th>末筆</th><th>明細 / chart</th>
                    </tr>
                </thead>
                <tbody id="resBody"><tr><td colspan="13" class="hint">尚未搜尋</td></tr></tbody>
            </table>
        </div>
    </div>

    <!-- Matching chart：使用者從搜尋結果點「＋matching」加入的 chart 疊在一起比較（可跨 tool / 跨區間） -->
    <div class="card" id="matchCard" hidden>
        <div class="toolbar" style="margin-bottom:8px;">
            <h2 style="margin:0;">Matching chart（比較）<small id="matchInfo" class="hint"></small></h2>
            <span class="hint">X 軸：
                <label><input type="radio" name="mx" value="idx" checked />依序排列（左右分開）</label>
                <label><input type="radio" name="mx" value="time" />時間（疊圖）</label>
            </span>
            <span class="hint">Spec 來源：<select id="specSrc" title="UCL / CL / LCL 取哪一條序列"></select></span>
            <button type="button" class="btn ghost small" id="btnRegion" style="margin-left:auto;">檢定區間：關</button>
            <button type="button" class="btn ghost small" id="btnMatchClear">清空 matching</button>
        </div>
        <div class="mbox"><canvas id="matchCanvas"></canvas></div>
        <!-- 檢定區間：每條序列可加 BSL（綠）與檢定（紅）區間，直接在圖上拖拉邊界或整塊移動，完成後帶入檢定表 -->
        <div id="regionPanel" class="rpanel" hidden>
            <div class="hint">在圖上<b>拖拉方框左右邊界</b>調整區間、<b>拖拉方框中間</b>整段平移（只在「依序排列」模式）。帶入時 BSL 區間 → 該組奇數列（X1、σ1），檢定區間 → 偶數列（X2、σ2）。</div>
            <table class="mstat" id="regionTable"></table>
        </div>
        <table class="mstat" id="matchStat"></table>
    </div>

    <!-- 3/4/5. 檢定表格 -->
    <div class="card">
        <h2>檢定表（PCRB）</h2>
        <div class="pcrb-wrap">
            <table class="pcrb" id="pcrb">
                <thead>
                    <tr>
                        <th>編號</th>
                        <th>Item</th>
                        <th>PU</th>
                        <th><input class="cell" id="adderHeader" value="ADDER" aria-label="ADDER 標題可編輯" style="text-align:center;font-weight:700;"></th>
                        <th>σ</th>
                        <th>/X2-X1//σ1</th>
                        <th>≦1</th>
                        <th>σ2^2/σ1^2</th>
                        <th>(σ2^2/σ1^2)&lt;2</th>
                        <th>檢定結果</th>
                        <th>操作</th>
                    </tr>
                </thead>
                <tbody id="tbodyPairs"></tbody>
            </table>
        </div>
        <div class="pcrb-actions">
            <button type="button" class="btn ghost" id="btnAddPair">＋ 新增一組（兩列）</button>
            <button type="button" class="btn ghost" id="btnCopy">複製檢定表</button>
            <button type="button" class="btn danger" id="btnClearAll">全部清除</button>
            <span class="hint">每列一個編號：奇數列 BSL、偶數列 wafer extend，1-2、3-4… 兩列一組檢定。PU 自行填寫；X / σ 由區間統計帶入後仍可手動修改；/X2-X1//σ1 ≦ 1 且 σ2²/σ1² &lt; 2 才算 PASS。內容會自動保存在此瀏覽器。</span>
            <span class="summary" id="summary"></span>
        </div>
    </div>
</div>

<script>
(function(){
    'use strict';
    const PAGE = location.pathname.split('/').pop() || 'NPW_inspection_tool.aspx';
    const $ = id => document.getElementById(id);
    const esc = s => String(s == null ? '' : s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;').replaceAll("'",'&#39;');
    const fmt = (n, dp) => { n = Number(n); return Number.isFinite(n) ? n.toFixed(dp == null ? 5 : dp) : ''; };
    const div0 = () => '#DIV/0!';
    const ymd = d => { const y=d.getFullYear(), m=String(d.getMonth()+1).padStart(2,'0'), dd=String(d.getDate()).padStart(2,'0'); return `${y}-${m}-${dd}`; };

    // ===== 1. 搜尋 =====
    let _results = [];      // 最近一次搜尋結果（物件陣列）
    let _range = { start:'', end:'', prod:'ctrl' };
    const prodOf = () => (document.querySelector('#qProd input[name=prod]:checked') || {}).value || 'ctrl';
    const prodLabel = p => p === 'ocap' ? 'OCAP' : '內控';
    // datetime-local 的值：yyyy-MM-ddTHH:mm
    const ymdhm = d => `${ymd(d)}T${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`;
    function setQuick(days){
        const end = new Date(); end.setSeconds(0, 0);
        const start = new Date(end); start.setDate(end.getDate() - days + 1); start.setHours(0, 0, 0, 0);
        $('qStart').value = ymdhm(start); $('qEnd').value = ymdhm(end);
    }
    function setStatus(t, err){ const s=$('qStatus'); s.textContent=t||''; s.className='status'+(err?' err':''); }

    async function doSearch(){
        const cid = $('qCid').value.trim(), cname = $('qName').value.trim(), pu = $('qPu').value.trim();
        if(!cid && !cname && !pu){ setStatus('請至少填 Chart_ID / Chart_name / 機台 其中一項', true); return; }
        if(!$('qEnd').value){ const n=new Date(); n.setSeconds(0,0); $('qEnd').value = ymdhm(n); }
        if(!$('qStart').value){ const d=new Date($('qEnd').value); d.setDate(d.getDate()-29); d.setHours(0,0,0,0); $('qStart').value=ymdhm(d); }
        const qs = new URLSearchParams({ op:'search', start:$('qStart').value, end:$('qEnd').value, prod:prodOf() });
        if(cid) qs.set('cid', cid); if(cname) qs.set('cname', cname); if(pu) qs.set('pu', pu);
        $('btnSearch').disabled = true; setStatus('查詢中…');
        try{
            const res = await fetch(PAGE + '?' + qs.toString(), { cache:'no-store' });
            const data = await res.json();
            if(!data.ok) throw new Error(data.error || ('HTTP ' + res.status));
            _results = data.rows || [];
            Object.keys(_vals).forEach(k => delete _vals[k]);   // 新搜尋：明細與排除點全部重來
            Object.keys(_trendCharts).forEach(k => { try{ _trendCharts[k].destroy(); }catch(e){} delete _trendCharts[k]; });
            _range = { start:data.start, end:data.end, prod:qs.get('prod') };
            renderResults();
            setStatus('完成：' + _results.length + ' 張 chart' + (data.truncated ? '（已達上限，請縮小條件）' : ''));
        }catch(e){
            _results = []; renderResults();
            setStatus('查詢失敗：' + e.message, true);
        }finally{ $('btnSearch').disabled = false; }
    }

    function renderResults(){
        const tb = $('resBody');
        $('resInfo').textContent = _results.length ? `（${_range.start} ~ ${_range.end}，${prodLabel(_range.prod)}，${_results.length} 張 chart）` : '';
        if(!_results.length){ tb.innerHTML = '<tr><td colspan="13" class="hint">無資料</td></tr>'; return; }
        let html = '';
        _results.forEach((r, i) => {
            html += `<tr data-i="${i}">
                <td class="c addcell"><button type="button" class="btn small" data-add="${i}" title="以本次搜尋區間的統計值填入右側選的列編號">加入檢定</button><select class="rowsel" data-i="${i}" title="填入的列編號">${rowOptions(_nextRow)}</select></td>
                <td>${esc(r.CHART_ID)}</td><td>${esc(r.CHART_NAME)}</td><td>${esc(r.PROCESSUNIT)}</td><td class="c">${esc(r.CHART_TYPE)}</td>
                <td class="num">${esc(r.N)}</td><td class="num">${fmt(r.AVG)}</td><td class="num">${r.STDEV == null ? '—' : fmt(r.STDEV)}</td>
                <td class="num">${fmt(r.MIN)}</td><td class="num">${fmt(r.MAX)}</td>
                <td>${esc(r.FIRST_TIME)}</td><td>${esc(r.LAST_TIME)}</td>
                <td class="c tools"><button type="button" class="btn small ghost" data-vals="${i}">明細</button><button type="button" class="btn small ghost" data-trend="${i}" title="在下方展開此 chart 區間內的趨勢圖">看 chart</button><button type="button" class="btn small" data-match="${i}" title="加入下方 Matching chart 一起比較（可跨 tool / 區間）">＋matching</button></td>
            </tr>`;
        });
        tb.innerHTML = html;
        syncMatchButtons();
    }

    // 明細：列出區間內每一筆 MEAN_VALUE；每一點可「刪除」（排除）後前端重算 N / AVG / STDEVA，
    // 重算值會回寫到該列搜尋結果（標示已排除幾點），之後「加入檢定」就用重算後的值
    const _vals = {};   // i -> { rows:[...], excluded:Set(index) }
    const stdevS = a => { const n = a.length; if(n < 2) return NaN; const m = a.reduce((s,v)=>s+v,0)/n; return Math.sqrt(a.reduce((s,v)=>s+(v-m)*(v-m),0)/(n-1)); };
    function recomputeValues(i){
        const v = _vals[i], r = _results[i]; if(!v || !r) return;
        const kept = v.rows.filter((x, k) => !v.excluded.has(k)).map(x => Number(x.mean)).filter(Number.isFinite);
        const n = kept.length, avg = n ? kept.reduce((s,x)=>s+x,0)/n : NaN, sd = stdevS(kept);
        const ex = v.excluded.size;
        r.adj = ex ? { n, avg: Number.isFinite(avg) ? avg : null, sd: Number.isFinite(sd) ? sd : null, excluded: ex } : null;
        // 回寫搜尋結果該列的 N / AVG / STDEVA
        const tr = $('resBody').querySelector(`tr[data-i="${i}"]`);
        if(tr){
            const tds = tr.querySelectorAll('td');
            if(ex){
                tds[5].innerHTML = `${n}<span class="adjnote">（原 ${esc(r.N)}，排除 ${ex}）</span>`;
                tds[6].textContent = Number.isFinite(avg) ? fmt(avg) : '—';
                tds[7].textContent = Number.isFinite(sd) ? fmt(sd) : '—';
                tr.classList.add('adjusted');
            }else{
                tds[5].textContent = String(r.N == null ? '' : r.N);
                tds[6].textContent = fmt(r.AVG);
                tds[7].textContent = r.STDEV == null ? '—' : fmt(r.STDEV);
                tr.classList.remove('adjusted');
            }
        }
        const sum = $('resBody').querySelector(`tr.vals[data-vi="${i}"] .valsum`);
        if(sum) sum.innerHTML = `共 ${v.rows.length} 筆，已排除 <b>${ex}</b> 點，採用 <b>${n}</b> 筆：AVG = <b>${Number.isFinite(avg)?fmt(avg):'—'}</b>、STDEVA = <b>${Number.isFinite(sd)?fmt(sd):'—'}</b>` + (ex ? '　<button type="button" class="btn small ghost" data-restore="' + i + '">全部還原</button>' : '');
        $('resBody').querySelectorAll(`tr.vals[data-vi="${i}"] tr[data-pt]`).forEach(ptr => {
            const k = Number(ptr.getAttribute('data-pt')); const on = v.excluded.has(k);
            ptr.classList.toggle('excluded', on);
            const b = ptr.querySelector('button[data-ex]'); if(b) b.textContent = on ? '還原' : '刪除';
        });
        if($('resBody').querySelector(`tr.trend[data-ti="${i}"]`)) drawTrend(i);   // 趨勢圖同步更新排除點
        // Matching chart 若已加入同一張 chart（同區間、同 PROD Type），排除狀態也同步過去並重畫
        const mkey = `${r.CHART_ID}|${_range.start}|${_range.end}|${_range.prod}`;
        let touched = false;
        _match.forEach(m => { if(m.key === mkey){ m.excluded = new Set(v.excluded); touched = true; } });
        if(touched) renderMatch();
    }
    // 取得（必要時載入）某列的明細點
    async function ensureVals(i){
        if(_vals[i]) return _vals[i];
        const r = _results[i];
        const qs = new URLSearchParams({ op:'values', cid:r.CHART_ID, start:_range.start, end:_range.end, prod:_range.prod || 'ctrl' });
        const res = await fetch(PAGE + '?' + qs.toString(), { cache:'no-store' });
        const data = await res.json();
        if(!data.ok) throw new Error(data.error || ('HTTP ' + res.status));
        _vals[i] = { rows: data.rows || [], excluded: new Set() };
        return _vals[i];
    }
    async function toggleValues(i, btn){
        const tr = btn.closest('tr'); const next = $('resBody').querySelector(`tr.vals[data-vi="${i}"]`);
        if(next){ next.remove(); btn.textContent='明細'; return; }
        btn.disabled = true;
        try{
            const rows = (await ensureVals(i)).rows;
            let inner = `<div class="hint valsum"></div><div class="valbox"><table><tr><th></th><th>#</th><th>UPDATE_TIME</th><th>CHART_SEQ</th><th>MEAN_VALUE</th><th>LOT</th><th>WAFER</th></tr>`;
            rows.forEach((x, k) => { inner += `<tr data-pt="${k}"><td><button type="button" class="btn small danger" data-ex="${k}" title="排除這一點，重算 N / AVG / STDEVA">刪除</button></td><td>${k+1}</td><td>${esc(x.d)}</td><td>${esc(x.seq)}</td><td style="text-align:right">${esc(x.mean)}</td><td>${esc(x.lot)}</td><td>${esc(x.wafer)}</td></tr>`; });
            inner += '</table></div>';
            const vr = document.createElement('tr'); vr.className = 'vals'; vr.setAttribute('data-vi', String(i));
            vr.innerHTML = `<td colspan="13">${inner}</td>`;
            tr.after(vr); btn.textContent = '收合';
            recomputeValues(i);
        }catch(e){ alert('明細載入失敗：' + e.message); }
        finally{ btn.disabled = false; }
    }
    function togglePoint(i, k){
        const v = _vals[i]; if(!v) return;
        if(v.excluded.has(k)) v.excluded.delete(k); else v.excluded.add(k);
        recomputeValues(i);
    }
    function restorePoints(i){ const v = _vals[i]; if(!v) return; v.excluded.clear(); recomputeValues(i); }

    // ===== 看 chart：該列下方展開區間內趨勢圖（MEAN_VALUE + UCL / LCL / XBAR；排除點灰色空心）=====
    const _trendCharts = {};   // i -> Chart 實例
    const numOrNull = x => (x == null || x === '' || !isFinite(Number(x))) ? null : Number(x);
    function lineDs(label, data, color, dash, width){ return { label, data, borderColor: color, borderDash: dash, fill: false, pointRadius: 0, borderWidth: width || 1.2, spanGaps: true }; }
    async function toggleTrend(i, btn){
        const tr = btn.closest('tr'); const open = $('resBody').querySelector(`tr.trend[data-ti="${i}"]`);
        if(open){ if(_trendCharts[i]){ try{ _trendCharts[i].destroy(); }catch(e){} delete _trendCharts[i]; } open.remove(); btn.textContent = '看 chart'; return; }
        btn.disabled = true;
        try{
            await ensureVals(i);
            const t = document.createElement('tr'); t.className = 'trend'; t.setAttribute('data-ti', String(i));
            t.innerHTML = `<td colspan="13"><div class="hint trendsum"></div><div class="trendbox"><canvas></canvas></div></td>`;
            // 放在明細列之後（若已展開），否則緊接在結果列之後
            const vals = $('resBody').querySelector(`tr.vals[data-vi="${i}"]`);
            (vals || tr).after(t);
            btn.textContent = '收合 chart';
            drawTrend(i);
        }catch(e){ alert('趨勢圖載入失敗：' + e.message); }
        finally{ btn.disabled = false; }
    }
    function drawTrend(i){
        const holder = $('resBody').querySelector(`tr.trend[data-ti="${i}"]`); const v = _vals[i], r = _results[i];
        if(!holder || !v || !r) return;
        const rows = v.rows;
        holder.querySelector('.trendsum').textContent = `CHART_ID ${r.CHART_ID}　${r.CHART_NAME || ''}　${r.PROCESSUNIT || ''}　${_range.start}~${_range.end}　共 ${rows.length} 點` + (v.excluded.size ? `（排除 ${v.excluded.size} 點，灰色空心）` : '');
        if(!window.Chart){ holder.querySelector('.trendsum').textContent += '　（Chart.js 未載入，無法繪圖）'; return; }
        if(_trendCharts[i]){ try{ _trendCharts[i].destroy(); }catch(e){} }
        const labels = rows.map(x => String(x.d || '').substring(5, 16));
        const mean = rows.map(x => numOrNull(x.mean));
        const ex = rows.map((x, k) => v.excluded.has(k));
        const ds = [{
            label: 'MEAN_VALUE', data: mean, borderColor: '#000', backgroundColor: 'rgba(0,0,0,.08)', fill: false, tension: .2, borderWidth: 1.5,
            pointStyle: 'triangle', pointRadius: ex.map(e => e ? 5 : 3), pointHoverRadius: 6,
            pointBackgroundColor: ex.map(e => e ? '#fff' : '#000'), pointBorderColor: ex.map(e => e ? '#999' : '#000'),
            segment: { borderColor: ctx => (ex[ctx.p0DataIndex] || ex[ctx.p1DataIndex]) ? '#bbb' : '#000' }
        },
            lineDs('UCL', rows.map(x => numOrNull(x.ucl)), 'red', [4, 2], 1.5),
            lineDs('XBAR (CL)', rows.map(x => numOrNull(x.xbar)), '#0f766e', [0, 0], 1.5),
            lineDs('LCL', rows.map(x => numOrNull(x.lcl)), 'red', [4, 2], 1.5)
        ];
        _trendCharts[i] = new Chart(holder.querySelector('canvas').getContext('2d'), {
            type: 'line', data: { labels, datasets: ds },
            options: { animation: false, responsive: true, maintainAspectRatio: false,
                plugins: { legend: { position: 'top', align: 'end', labels: { usePointStyle: true, pointStyle: 'line', boxWidth: 26, font: { size: 10 } } },
                    tooltip: { callbacks: { label: c => { if(c.dataset.label !== 'MEAN_VALUE') return c.dataset.label + ': ' + c.formattedValue; const x = rows[c.dataIndex] || {}; return 'MEAN_VALUE: ' + (x.mean == null ? '-' : x.mean) + (ex[c.dataIndex] ? '（已排除）' : '') + (x.lot ? '  LOT ' + x.lot : '') + (x.wafer ? '  W' + x.wafer : '') + (x.seq != null ? '  SEQ ' + x.seq : ''); } } } },
                scales: { x: { ticks: { font: { size: 9 }, maxRotation: 90, minRotation: 90, autoSkip: true, maxTicksLimit: 20 } }, y: { ticks: { font: { size: 10 } } } } }
        });
    }

    // ===== Matching chart：使用者點「＋matching」加入的 chart 疊在同一張圖比較 =====
    // 加入時快照該列目前的點與排除狀態（之後重新搜尋不影響已加入的序列）
    const _match = [];   // [{key,label,cid,name,pu,start,end,prod,rows,excluded:Set}]
    let _matchChart = null;
    // Chart.js 會把傳入的 config 包成自己的物件，掛在 config 上的自訂欄位外掛讀不到，所以版面資訊放這裡
    let _matchMeta = { boundaries: [], sideBySide: false };
    const MCOLORS = ['#1976d2','#d32f2f','#2e7d32','#f57c00','#7b1fa2','#00838f','#5d4037','#c2185b','#455a64','#9e9d24'];
    async function addToMatch(i, btn){
        const r = _results[i]; if(!r) return;
        btn.disabled = true;
        try{
            const v = await ensureVals(i);
            const key = `${r.CHART_ID}|${_range.start}|${_range.end}|${_range.prod}`;
            const dup = _match.findIndex(m => m.key === key);
            const entry = { key, cid: String(r.CHART_ID), name: r.CHART_NAME || '', pu: r.PROCESSUNIT || '', start: _range.start, end: _range.end, prod: _range.prod,
                label: `${r.PROCESSUNIT || ''} ${r.CHART_NAME || ''}（${_range.start}~${_range.end}）`,
                rows: v.rows.slice(), excluded: new Set(v.excluded) };
            if(dup >= 0){ entry.regions = _match[dup].regions || null; _match[dup] = entry; } else _match.push(entry);
            renderMatch();
            setStatus(`已${dup >= 0 ? '更新' : '加入'} matching：CHART_ID ${r.CHART_ID}（${_match.length} 條序列）`);
        }catch(e){ alert('加入 matching 失敗：' + e.message); btn.disabled = false; }
    }
    function removeMatch(k){ _match.splice(k, 1); renderMatch(); }
    function matchKeyOf(r){ return `${r.CHART_ID}|${_range.start}|${_range.end}|${_range.prod}`; }
    // ＋matching 再按一次 = 移除該序列
    function toggleMatch(i, btn){
        const r = _results[i]; if(!r) return;
        const k = _match.findIndex(m => m.key === matchKeyOf(r));
        if(k >= 0){ removeMatch(k); setStatus(`已從 matching 移除 CHART_ID ${r.CHART_ID}（剩 ${_match.length} 條）`); }
        else addToMatch(i, btn);
    }
    // 一鍵把本次搜尋結果全部加入（已加入的略過）
    async function addAllToMatch(btn){
        if(!_results.length){ setStatus('沒有搜尋結果可加入', true); return; }
        btn.disabled = true; setStatus('加入中…');
        try{
            let added = 0;
            for(let i = 0; i < _results.length; i++){
                const r = _results[i]; if(_match.some(m => m.key === matchKeyOf(r))) continue;
                const v = await ensureVals(i);
                _match.push({ key: matchKeyOf(r), cid: String(r.CHART_ID), name: r.CHART_NAME || '', pu: r.PROCESSUNIT || '', start: _range.start, end: _range.end, prod: _range.prod,
                    label: `${r.PROCESSUNIT || ''} ${r.CHART_NAME || ''}（${_range.start}~${_range.end}）`, rows: v.rows.slice(), excluded: new Set(v.excluded) });
                added++;
            }
            renderMatch();
            setStatus(`已加入 ${added} 條到 matching（共 ${_match.length} 條）`);
        }catch(e){ alert('加入 matching 失敗：' + e.message); }
        finally{ btn.disabled = false; }
    }
    $('btnMatchAll').addEventListener('click', e => addAllToMatch(e.currentTarget));
    // Spec 來源：預設第一條；下拉可改；找不到有 UCL/LCL 的點就往後找其他序列
    let _specKey = null;
    function specFrom(series){
        const pick = s => { for(let j = s.kept.length - 1; j >= 0; j--){ const x = s.kept[j]; if(numOrNull(x.ucl) != null || numOrNull(x.lcl) != null || numOrNull(x.xbar) != null) return { ucl: numOrNull(x.ucl), cl: numOrNull(x.xbar), lcl: numOrNull(x.lcl), name: s.m.name, key: s.m.key }; } return null; };
        const ordered = series.slice(); const si = series.findIndex(s => s.m.key === _specKey);
        if(si > 0){ ordered.splice(si, 1); ordered.unshift(series[si]); }
        for(const s of ordered){ const sp = pick(s); if(sp) return sp; }
        return null;
    }
    function renderSpecSelect(){
        const sel = $('specSrc'); if(!sel) return;
        sel.innerHTML = _match.map(m => `<option value="${esc(m.key)}"${m.key === _specKey ? ' selected' : ''}>${esc(m.pu)} ${esc(m.name)}</option>`).join('');
        if(!_match.some(m => m.key === _specKey)) { _specKey = _match.length ? _match[0].key : null; if(sel.options.length) sel.value = _specKey; }
    }
    $('specSrc').addEventListener('change', e => { _specKey = e.target.value; renderMatch(); });
    // 已加入 matching 的搜尋結果列：＋matching 按鈕反灰並顯示「已加入」；移除或清空後恢復
    function syncMatchButtons(){
        document.querySelectorAll('#resBody button[data-match]').forEach(b => {
            const r = _results[Number(b.getAttribute('data-match'))]; if(!r) return;
            const key = `${r.CHART_ID}|${_range.start}|${_range.end}|${_range.prod}`;
            const on = _match.some(m => m.key === key);
            b.textContent = on ? '已加入（再按移除）' : '＋matching';
            b.classList.toggle('on', on); b.title = on ? '已在 Matching chart；再按一次會把這條序列移除' : '加入下方 Matching chart 一起比較（可跨 tool / 區間）';
        });
    }
    function renderMatch(){
        syncMatchButtons();
        const card = $('matchCard');
        if(!_match.length){ if(_matchChart){ try{ _matchChart.destroy(); }catch(e){} _matchChart = null; } card.hidden = true; $('regionPanel').hidden = true; return; }
        card.hidden = false;
        renderSpecSelect();
        // 統計表：每條序列 N / AVG / STDEVA / Min / Max
        let st = '<tr><th></th><th>CHART_ID</th><th>CHART_NAME</th><th>機台</th><th>區間</th><th>N</th><th>AVG</th><th>STDEVA</th><th>Min</th><th>Max</th></tr>';
        const series = _match.map((m, k) => {
            const kept = m.rows.filter((x, j) => !m.excluded.has(j)).filter(x => numOrNull(x.mean) != null);
            const vals = kept.map(x => Number(x.mean));
            const n = vals.length, avg = n ? vals.reduce((s, x) => s + x, 0) / n : NaN, sd = stdevS(vals);
            st += `<tr><td><span class="sw" style="display:inline-block;width:12px;height:12px;border-radius:3px;background:${MCOLORS[k % MCOLORS.length]}"></span></td><td>${esc(m.cid)}</td><td>${esc(m.name)}</td><td>${esc(m.pu)}</td><td>${esc(m.start)}~${esc(m.end)}</td><td class="num">${n}</td><td class="num">${Number.isFinite(avg)?fmt(avg):'—'}</td><td class="num">${Number.isFinite(sd)?fmt(sd):'—'}</td><td class="num">${n?fmt(Math.min(...vals)):'—'}</td><td class="num">${n?fmt(Math.max(...vals)):'—'}</td></tr>`;
            return { m, kept, color: MCOLORS[k % MCOLORS.length] };
        });
        $('matchStat').innerHTML = st;
        drawMatch(series);
    }
    function drawMatch(series){
        if(!window.Chart) return;
        if(_matchChart){ try{ _matchChart.destroy(); }catch(e){} _matchChart = null; }
        const byTime = (document.querySelector('input[name=mx]:checked') || {}).value === 'time';
        const toT = d => { const t = new Date(String(d || '').replace(' ', 'T')); return isNaN(t) ? null : t.getTime(); };
        const fmtT = v => { const d = new Date(v); return isNaN(d) ? '' : `${d.getMonth()+1}/${d.getDate()} ${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`; };
        // Spec 預設以「第一張點選加入」的 chart 為主（可用下拉改選）：取其最後一個有 UCL / LCL 的採用點
        const spec = specFrom(series);
        { const sel = _match.find(m => m.key === _specKey) || _match[0];
          $('matchInfo').textContent = `（${_match.length} 條序列；排除的點不列入；Spec 取「${spec ? spec.name : '—'}」` + (spec && sel && spec.key !== sel.key ? `，因「${sel.name}」沒有 UCL / LCL 而改用` : '') + '）'; }
        const specDs = (label, val, color, dash, len, xs) => ({ label, _spec: true, data: xs ? xs.map(x => ({ x, y: val })) : new Array(len).fill(val), borderColor: color, borderDash: dash, borderWidth: 1.3, pointRadius: 0, fill: false, spanGaps: true });
        const specSets = (len, xs) => !spec ? [] : [
            spec.ucl != null ? specDs(`UCL ${fmt(spec.ucl)}（${spec.name}）`, spec.ucl, 'red', [4, 2], len, xs) : null,
            spec.cl != null ? specDs(`CL ${fmt(spec.cl)}（${spec.name}）`, spec.cl, '#0f766e', [0, 0], len, xs) : null,
            spec.lcl != null ? specDs(`LCL ${fmt(spec.lcl)}（${spec.name}）`, spec.lcl, 'red', [4, 2], len, xs) : null
        ].filter(Boolean);
        // 序列之間的分隔線（只在依序排列模式）：在相鄰兩段的邊界畫一條垂直虛線
        // 多條序列時在每一段上方標示 chamber（PROCESSUNIT），用該序列顏色、置中
        // S1/S2：由 CHART_NAME 推導（W1/W2，或 AC1/AC2、B2 這類段落的尾數）→ 「SACVD-B10A S1」「SACVD-B10A S2」
        const sideOfName = name => {
            const u = String(name || '').toUpperCase();
            const m = u.match(/(^|[-_])W([12])(?=[-_]|$)/); if(m) return 'S' + m[2];
            const seg = u.split('-').find(x => /^[ABC]{1,3}[12]$/.test(x)); return seg ? 'S' + seg.slice(-1) : '';
        };
        const segLabel = m => { const side = sideOfName(m.name); return ((m.pu || m.name) + (side ? ' ' + side : '')).trim(); };
        // chamber 標籤畫在繪圖區上方獨立的一條帶（layout.padding.top 預留，與圖例分開），
        // 相鄰段落交錯上下兩列、段太窄時縮小字體，避免互相重疊
        const CHAMBER_BAND = 30;
        const chamberPlugin = { id: 'npwChambers', afterDraw(chart){
            const segs = _matchMeta.segments || []; if(segs.length < 2) return;
            const { ctx, chartArea, scales } = chart; const x = scales.x; if(!x) return;
            ctx.save(); ctx.textAlign = 'center'; ctx.textBaseline = 'bottom';
            segs.forEach((sg, k) => {
                if(!sg.n) return;
                const left = x.getPixelForValue(sg.off), right = x.getPixelForValue(sg.off + sg.n - 1);
                const segW = Math.max(right - left, 12) + 12;
                let size = 12; ctx.font = `bold ${size}px Arial`;
                while(size > 8 && ctx.measureText(sg.label).width > segW * 2){ size--; ctx.font = `bold ${size}px Arial`; }
                const cx = Math.min(Math.max((left + right) / 2, chartArea.left + 10), chartArea.right - 10);
                const y = chartArea.top - 2 - (k % 2 ? 0 : 14);   // 偶數段上列、奇數段下列
                ctx.fillStyle = sg.color; ctx.fillText(sg.label, cx, y);
            });
            ctx.restore();
        } };
        const separatorPlugin = { id: 'npwSeparators', afterDraw(chart){
            const b = _matchMeta.boundaries || []; if(!b.length) return;
            const { ctx, chartArea, scales } = chart; const x = scales.x; if(!x) return;
            ctx.save(); ctx.strokeStyle = '#555'; ctx.setLineDash([5, 4]); ctx.lineWidth = 1.2;
            b.forEach(idx => { const px = (x.getPixelForValue(idx - 1) + x.getPixelForValue(idx)) / 2; ctx.beginPath(); ctx.moveTo(px, chartArea.top); ctx.lineTo(px, chartArea.bottom); ctx.stroke(); });
            ctx.restore();
        } };
        let cfg;
        if(!byTime){
            // 左右分開（依序排列）：像 SPC 多 chart 檢視，序列一條接一條排在 X 軸上，中間以分隔線隔開
            const total = series.reduce((s, x) => s + x.kept.length, 0);
            const labels = []; const pts = new Array(total).fill(null);
            const datasets = []; const boundaries = []; const segments = []; let off = 0;
            series.forEach((s, k) => {
                const mean = new Array(total).fill(null);
                s.m._off = off; s.m._kept = s.kept;   // 檢定區間需要知道每條序列在 X 軸上的起點與採用點
                segments.push({ off, n: s.kept.length, label: segLabel(s.m), color: s.color });
                clampRegions(s.m);
                s.kept.forEach((x, j) => {
                    const idx = off + j; labels[idx] = String(x.d || '').substring(5, 16); pts[idx] = x;
                    mean[idx] = Number(x.mean);
                });
                datasets.push({ label: segLabel(s.m), _full: `${s.m.pu} ${s.m.name}`.trim(), data: mean, borderColor: s.color, backgroundColor: s.color, fill: false, tension: .15, borderWidth: 1.5, pointRadius: 3, pointHoverRadius: 6, spanGaps: false });
                off += s.kept.length;
                if(k < series.length - 1 && s.kept.length) boundaries.push(off);
            });
            datasets.push(...specSets(total, null));
            { const seen = {}; segments.forEach(sg => { seen[sg.label] = (seen[sg.label] || 0) + 1; });
              series.forEach((x, k) => { if(seen[segments[k].label] > 1) segments[k].label = segLabel(x.m) + '（' + x.m.name + '）'; }); }
            _matchMeta = { boundaries, segments, sideBySide: true };
            cfg = { type: 'line', data: { labels, datasets }, plugins: [chamberPlugin, separatorPlugin, regionPlugin],
                options: { animation: false, responsive: true, maintainAspectRatio: false, layout: { padding: { top: series.length > 1 ? CHAMBER_BAND : 4 } },
                    plugins: { legend: { position: 'top', align: 'start', labels: { usePointStyle: true, boxWidth: 10, font: { size: 11 } } },
                        tooltip: { filter: it => !it.dataset._spec, callbacks: { title: items => items.length ? ((pts[items[0].dataIndex] || {}).d || '') : '',
                            label: c => { const p = pts[c.dataIndex] || {}; return `${c.dataset._full || c.dataset.label}: ${p.mean}` + (p.lot ? '  LOT ' + p.lot : '') + (p.wafer ? '  W' + p.wafer : '') + (p.seq != null ? '  SEQ ' + p.seq : ''); } } } },
                    scales: { x: { title: { display: true, text: '依序排列（各 chart 左右分開，虛線為分隔）' }, ticks: { font: { size: 9 }, maxRotation: 90, minRotation: 90, autoSkip: true, maxTicksLimit: 40 } },
                              y: { title: { display: true, text: 'MEAN_VALUE' }, ticks: { font: { size: 10 } } } } } };
        }else{
            _matchMeta = { boundaries: [], segments: [], sideBySide: false };
            series.forEach(s => { s.m._kept = s.kept; clampRegions(s.m); });
            const datasets = series.map(s => ({
                label: segLabel(s.m), _full: `${s.m.pu} ${s.m.name}`.trim(), borderColor: s.color, backgroundColor: s.color, fill: false, tension: .15, borderWidth: 1.5, pointRadius: 3, pointHoverRadius: 6, spanGaps: true, showLine: true,
                data: s.kept.map(x => ({ x: toT(x.d), y: Number(x.mean), _p: x })).filter(p => p.x != null)
            }));
            const allX = datasets.flatMap(d => d.data.map(p => p.x));
            if(allX.length) datasets.push(...specSets(0, [Math.min(...allX), Math.max(...allX)]));
            cfg = { type: 'line', data: { datasets },
                options: { animation: false, responsive: true, maintainAspectRatio: false, parsing: false,
                    plugins: { legend: { position: 'top', align: 'start', labels: { usePointStyle: true, boxWidth: 10, font: { size: 11 } } },
                        tooltip: { filter: it => !it.dataset._spec, callbacks: { title: items => items.length ? fmtT(items[0].parsed.x) : '',
                            label: c => { const p = c.raw && c.raw._p || {}; return `${c.dataset._full || c.dataset.label}: ${p.mean}` + (p.d ? '  ' + p.d : '') + (p.lot ? '  LOT ' + p.lot : '') + (p.wafer ? '  W' + p.wafer : ''); } } } },
                    scales: { x: { type: 'linear', title: { display: true, text: '時間（同一時間軸疊圖）' }, ticks: { font: { size: 10 }, maxRotation: 60, autoSkip: true, maxTicksLimit: 16, callback: v => fmtT(v) } },
                              y: { title: { display: true, text: 'MEAN_VALUE' }, ticks: { font: { size: 10 } } } } } };
        }
        _matchChart = new Chart($('matchCanvas').getContext('2d'), cfg);
        renderRegionPanel();
    }
    document.querySelectorAll('input[name=mx]').forEach(r => r.addEventListener('change', () => renderMatch()));
    $('btnMatchClear').addEventListener('click', () => { _match.length = 0; renderMatch(); });

    // ===== 檢定區間：在 matching chart 上拖拉 BSL（綠）/ 檢定（紅）方框，完成後帶入檢定表 =====
    // 區間存在序列快照上：m.regions = { bsl:{a,b}, test:{a,b} }，a/b 為該序列「採用點」的 0 起索引（含）
    let _regionMode = false;
    // 採用點數變了（例如明細又排除了點）時，把區間索引夾回合法範圍
    function clampRegions(m){
        if(!m.regions) return; const n = (m._kept || []).length;
        ['bsl', 'test'].forEach(kind => { const rg = m.regions[kind]; if(!rg) return;
            if(!n){ m.regions[kind] = null; return; }
            rg.a = Math.max(0, Math.min(n - 1, rg.a)); rg.b = Math.max(rg.a, Math.min(n - 1, rg.b)); });
    }
    const REGION_STYLE = { bsl: { fill: 'rgba(0,160,0,.18)', line: '#0a0', text: '#064', name: 'BSL' }, test: { fill: 'rgba(220,0,0,.18)', line: '#c00', text: '#800', name: '檢定' } };
    function regionStats(m, kind){
        const rg = m.regions && m.regions[kind]; const kept = m._kept || []; if(!rg || !kept.length) return null;
        const vals = kept.slice(rg.a, rg.b + 1).map(x => Number(x.mean)).filter(Number.isFinite);
        const n = vals.length, avg = n ? vals.reduce((s, x) => s + x, 0) / n : NaN, sd = stdevS(vals);
        return { n, avg, sd, a: rg.a, b: rg.b, from: (kept[rg.a] || {}).d || '', to: (kept[rg.b] || {}).d || '' };
    }
    // 圖上方框的左右像素邊界（半格外擴，讓方框包住整個點）
    function regionPixels(chart, m, rg){
        const x = chart.scales.x; const total = chart.data.labels.length;
        const px = i => x.getPixelForValue(i);
        const step = total > 1 ? Math.abs(px(1) - px(0)) : 20;
        const gi0 = m._off + rg.a, gi1 = m._off + rg.b;
        return { left: px(gi0) - step / 2, right: px(gi1) + step / 2 };
    }
    const regionPlugin = { id: 'npwRegions', afterDatasetsDraw(chart){
        if(!_regionMode || !_matchMeta.sideBySide) return;
        const { ctx, chartArea } = chart;
        _match.forEach(m => { if(!m.regions || !m._kept) return; ['bsl', 'test'].forEach(kind => {
            const rg = m.regions[kind]; if(!rg) return;
            const { left, right } = regionPixels(chart, m, rg); const st = REGION_STYLE[kind]; const s = regionStats(m, kind);
            ctx.save(); ctx.beginPath(); ctx.rect(chartArea.left, chartArea.top, chartArea.right - chartArea.left, chartArea.bottom - chartArea.top); ctx.clip();
            ctx.fillStyle = st.fill; ctx.fillRect(left, chartArea.top, right - left, chartArea.bottom - chartArea.top);
            ctx.strokeStyle = st.line; ctx.lineWidth = 1.5; ctx.setLineDash([]); ctx.strokeRect(left, chartArea.top, right - left, chartArea.bottom - chartArea.top);
            // 邊界把手
            ctx.fillStyle = st.line; ctx.fillRect(left - 2, chartArea.top, 4, 14); ctx.fillRect(right - 2, chartArea.top, 4, 14);
            ctx.fillStyle = st.text; ctx.font = 'bold 11px Arial'; ctx.textBaseline = 'top';
            ctx.fillText(`${st.name} ${m.name}  N=${s ? s.n : 0}  AVG=${s && Number.isFinite(s.avg) ? fmt(s.avg) : '—'}  σ=${s && Number.isFinite(s.sd) ? fmt(s.sd) : '—'}`, Math.max(left, chartArea.left) + 4, chartArea.top + (kind === 'test' ? 16 : 2));
            ctx.restore();
        }); });
    } };
    // 滑鼠位置 → 命中的方框（優先邊界）
    function regionHit(chart, mx, my){
        if(!_regionMode || !chart || !_matchMeta.sideBySide) return null;
        const ca = chart.chartArea; if(my < ca.top || my > ca.bottom) return null;
        let best = null;
        _match.forEach((m, k) => { if(!m.regions) return; ['bsl', 'test'].forEach(kind => {
            const rg = m.regions[kind]; if(!rg) return;
            const { left, right } = regionPixels(chart, m, rg);
            const dl = Math.abs(mx - left), dr = Math.abs(mx - right);
            if(dl <= 6 && (!best || dl < best.d)) best = { m, k, kind, mode: 'left', d: dl };
            if(dr <= 6 && (!best || dr < best.d)) best = { m, k, kind, mode: 'right', d: dr };
            if(mx > left + 6 && mx < right - 6 && !best) best = { m, k, kind, mode: 'move', d: 999 };
        }); });
        return best;
    }
    // 像素 → 該序列內最接近的採用點索引（夾在 0..n-1）
    function pixelToLocalIndex(chart, m, px){
        const x = chart.scales.x; const n = (m._kept || []).length; let bi = 0, bd = Infinity;
        for(let j = 0; j < n; j++){ const d = Math.abs(x.getPixelForValue(m._off + j) - px); if(d < bd){ bd = d; bi = j; } }
        return bi;
    }
    let _drag = null;
    (function regionMouseInit(){
        const cv = $('matchCanvas');
        const pos = e => { const r = cv.getBoundingClientRect(); return { x: e.clientX - r.left, y: e.clientY - r.top }; };
        cv.addEventListener('mousedown', e => {
            const p = pos(e); const h = regionHit(_matchChart, p.x, p.y); if(!h) return;
            const rg = h.m.regions[h.kind];
            _drag = { h, startX: p.x, a0: rg.a, b0: rg.b, startIdx: pixelToLocalIndex(_matchChart, h.m, p.x) };
            e.preventDefault();
        });
        window.addEventListener('mousemove', e => {
            if(!_matchChart) return;
            const p = pos(e);
            if(!_drag){
                const h = regionHit(_matchChart, p.x, p.y);
                cv.className = h ? (h.mode === 'move' ? 'move' : 'resize') : '';
                return;
            }
            const { h, a0, b0, startIdx } = _drag; const m = h.m; const n = (m._kept || []).length; const rg = m.regions[h.kind];
            const idx = pixelToLocalIndex(_matchChart, m, p.x);
            const clamp = v => Math.max(0, Math.min(n - 1, v));
            if(h.mode === 'left'){ rg.a = clamp(Math.min(idx, b0)); rg.b = b0; }
            else if(h.mode === 'right'){ rg.b = clamp(Math.max(idx, a0)); rg.a = a0; }
            else { const len = b0 - a0; let na = a0 + (idx - startIdx); na = Math.max(0, Math.min(n - 1 - len, na)); rg.a = na; rg.b = na + len; }
            _matchChart.update('none'); updateRegionTexts();
        });
        window.addEventListener('mouseup', () => { if(_drag){ _drag = null; updateRegionTexts(); } });
    })();
    function defaultRegions(m){
        const n = (m._kept || []).length; if(!n) return null;
        const half = Math.max(1, Math.floor(n / 2));
        return { bsl: { a: 0, b: Math.max(0, half - 1) }, test: { a: Math.min(n - 1, half), b: n - 1 } };
    }
    function toggleRegion(k, kind){
        const m = _match[k]; if(!m) return;
        if(!m.regions) m.regions = { bsl: null, test: null };
        if(m.regions[kind]) m.regions[kind] = null;
        else { const d = defaultRegions(m); if(!d){ alert('此序列沒有可用的點'); return; } m.regions[kind] = d[kind]; }
        if(_matchChart) _matchChart.update('none');
        renderRegionPanel();
    }
    function groupOptions(selected){
        const opts = pairs.map((p, g) => `<option value="${g}"${g === selected ? ' selected' : ''}>第 ${g + 1} 組（列 ${g * 2 + 1}、${g * 2 + 2}）</option>`);
        opts.push(`<option value="new"${selected === 'new' ? ' selected' : ''}>＋新增一組</option>`);
        return opts.join('');
    }
    function nextEmptyGroup(){ const g = pairs.findIndex(p => !p.bsl.x && !p.ext.x); return g >= 0 ? g : 'new'; }
    function renderRegionPanel(){
        const panel = $('regionPanel'); const btn = $('btnRegion');
        btn.textContent = '檢定區間：' + (_regionMode ? '開' : '關'); btn.classList.toggle('on', _regionMode);
        if(!_regionMode || !_match.length){ panel.hidden = true; return; }
        panel.hidden = false;
        const sideBySide = !!(_matchChart && _matchMeta.sideBySide);
        let html = '<tr><th></th><th>序列</th><th>BSL 區間（綠）</th><th>檢定區間（紅）</th><th>帶入檢定表</th></tr>';
        _match.forEach((m, k) => {
            const r = m.regions || {};
            html += `<tr data-rk="${k}"><td><span class="sw" style="display:inline-block;width:12px;height:12px;border-radius:3px;background:${MCOLORS[k % MCOLORS.length]}"></span></td>
                <td>${esc(m.pu)} ${esc(m.name)}<br><span class="hint">${esc(m.start)}~${esc(m.end)}，${(m._kept || []).length} 點</span></td>
                <td><button type="button" class="btn small ${r.bsl ? 'danger' : 'ghost'}" data-rtoggle="bsl" data-k="${k}">${r.bsl ? '移除 BSL' : '＋BSL 區間'}</button> <span class="rtext" data-kind="bsl"></span></td>
                <td><button type="button" class="btn small ${r.test ? 'danger' : 'ghost'}" data-rtoggle="test" data-k="${k}">${r.test ? '移除檢定' : '＋檢定區間'}</button> <span class="rtext" data-kind="test"></span></td>
                <td><select class="rgroup" data-k="${k}">${groupOptions(nextEmptyGroup())}</select> <button type="button" class="btn small" data-rfill="${k}" ${(r.bsl || r.test) ? '' : 'disabled'}>帶入</button></td></tr>`;
        });
        $('regionTable').innerHTML = html + (sideBySide ? '' : '<tr><td colspan="5" class="hint">目前是「時間」模式，方框不顯示；請切回「依序排列（左右分開）」再拖拉區間。</td></tr>');
        updateRegionTexts();
    }
    function updateRegionTexts(){
        document.querySelectorAll('#regionTable tr[data-rk]').forEach(tr => {
            const m = _match[Number(tr.getAttribute('data-rk'))]; if(!m) return;
            tr.querySelectorAll('.rtext').forEach(sp => {
                const kind = sp.getAttribute('data-kind'); const s = regionStats(m, kind);
                sp.innerHTML = s ? `<span class="tag ${kind}">點 ${s.a + 1}~${s.b + 1}</span> N=<b>${s.n}</b> AVG=<b>${Number.isFinite(s.avg) ? fmt(s.avg) : '—'}</b> σ=<b>${Number.isFinite(s.sd) ? fmt(s.sd) : '—'}</b><br><span class="hint">${esc(s.from)} ~ ${esc(s.to)}</span>` : '';
            });
        });
    }
    function fillFromRegions(k){
        const m = _match[k]; if(!m || !m.regions) return;
        const sel = document.querySelector(`#regionTable select.rgroup[data-k="${k}"]`); let g = sel ? sel.value : 'new';
        if(g === 'new'){ pairs.push(newPair()); g = pairs.length - 1; } else g = Number(g);
        if(!pairs[g]) return;
        const put = (side, kind) => {
            const s = regionStats(m, kind); if(!s) return false;
            side.x = Number.isFinite(s.avg) ? fmt(s.avg) : ''; side.s = Number.isFinite(s.sd) ? fmt(s.sd) : ''; side.n = String(s.n);
            side.cid = m.cid; side.src = `${m.pu} ${REGION_STYLE[kind].name}區間 點${s.a + 1}~${s.b + 1}（${s.from}~${s.to}）${prodLabel(m.prod)}`.trim();
            return true;
        };
        const okB = put(pairs[g].bsl, 'bsl'), okT = put(pairs[g].ext, 'test');
        _nextRow = Math.min(pairs.length * 2, g * 2 + 3);
        renderPairs(); save(); renderRegionPanel();
        [okB ? g * 2 + 1 : 0, okT ? g * 2 + 2 : 0].filter(Boolean).forEach(rn => { const tr = $('tbodyPairs').querySelector(`tr[data-row="${rn}"]`); if(tr){ tr.classList.add('flash'); setTimeout(() => tr.classList.remove('flash'), 1300); } });
        setStatus(`已將 ${m.name} 的${okB ? ' BSL 區間→列 ' + (g * 2 + 1) : ''}${okB && okT ? '、' : ''}${okT ? '檢定區間→列 ' + (g * 2 + 2) : ''} 帶入第 ${g + 1} 組`);
        $('pcrb').scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
    $('btnRegion').addEventListener('click', () => { _regionMode = !_regionMode; if(_matchChart) _matchChart.update('none'); renderRegionPanel(); });
    $('regionTable').addEventListener('click', e => {
        const t = e.target.closest('button[data-rtoggle]'); if(t){ toggleRegion(Number(t.getAttribute('data-k')), t.getAttribute('data-rtoggle')); return; }
        const f = e.target.closest('button[data-rfill]'); if(f){ fillFromRegions(Number(f.getAttribute('data-rfill'))); }
    });

    // ===== 3/4/5. 檢定表（PCRB）=====
    // 每一列一個編號：奇數列 = BSL（X1、σ1）、偶數列 = wafer extend（X2、σ2），
    // 相鄰兩列（1-2、3-4…）為一組做檢定；公式沿用檢定機器人：
    //   Z = |X2-X1| / σ1（≦1 為 Y）、R = σ2^2 / σ1^2（<2 為 Y）；兩者皆 Y 才 PASS
    const STORE_KEY = 'npwInspect.pairs.v1';
    let pairs = [];   // [{bsl:{pu,x,s,n,cid,src}, ext:{...}}]；列編號 r（1 起）→ pairs[floor((r-1)/2)][r 奇數 ? bsl : ext]

    const rowNoOf = (idx, key) => idx * 2 + (key === 'ext' ? 2 : 1);
    const rowOf = r => ({ idx: Math.floor((r - 1) / 2), key: (r % 2 === 1) ? 'bsl' : 'ext' });
    const rowLabel = r => `${r}（${r % 2 === 1 ? 'BSL' : 'wafer extend'}）`;

    function blankSide(){ return { pu:'', x:'', s:'', n:'', cid:'', src:'' }; }
    function newPair(){ return { bsl: blankSide(), ext: blankSide() }; }
    function save(){ try{ localStorage.setItem(STORE_KEY, JSON.stringify({ header: $('adderHeader').value, pairs })); }catch(e){} }
    function load(){
        try{
            const d = JSON.parse(localStorage.getItem(STORE_KEY) || 'null');
            if(d && Array.isArray(d.pairs) && d.pairs.length){ pairs = d.pairs; if(d.header) $('adderHeader').value = d.header; return; }
        }catch(e){}
        pairs = [newPair(), newPair()];
    }

    function sideRow(idx, key, side, label){
        const isExt = key === 'ext';
        let cells = `
            <td class="item${isExt ? ' green' : ''}"><input class="cell" data-f="item" value="${esc(label)}" aria-label="Item"></td>
            <td class="pu"><input class="cell" data-f="pu" value="${esc(side.pu)}" placeholder="PU（自行填寫）" aria-label="PU" title="${esc(side.cid ? 'CHART_ID ' + side.cid + (side.src ? '　' + side.src : '') : '')}"></td>
            <td><input class="cell num" data-f="x" type="number" step="any" value="${esc(side.x)}" placeholder="${isExt ? 'X2' : 'X1'}" aria-label="X"></td>
            <td><input class="cell num" data-f="s" type="number" step="any" value="${esc(side.s)}" placeholder="${isExt ? 'σ2' : 'σ1'}" aria-label="σ"></td>`;
        // 檢定結果五格屬於整組（兩列），放在 BSL 列並以 rowspan=2 跨到 wafer extend 列
        if(!isExt){
            cells += `<td class="result z" rowspan="2">—</td><td class="result zOK" rowspan="2">—</td><td class="result r" rowspan="2">—</td><td class="result rOK" rowspan="2">—</td><td class="verdict" rowspan="2">—</td>`;
        }
        const ops = `<td class="ops"><button type="button" class="btn small danger" data-clear="${rowNoOf(idx, key)}" title="清空此列的 PU / X / σ / N 與註記（編號與配對不變）">刪除</button></td>`;
        return `<tr data-idx="${idx}" data-side="${key}" data-row="${rowNoOf(idx, key)}"><td class="no">${rowNoOf(idx, key)}</td>${cells}${ops}</tr>`;
    }

    function renderPairs(){
        const tb = $('tbodyPairs');
        tb.innerHTML = pairs.map((p, i) => sideRow(i, 'bsl', p.bsl, p.bsl.item || 'BSL') + sideRow(i, 'ext', p.ext, p.ext.item || 'wafer extend')).join('');
        tb.querySelectorAll('input[data-f="pu"]').forEach(fitPu);
        refreshRowSelects();
        recalcAll();
    }
    // PU 輸入框寬度隨字數變化（中文字算 2 格），最窄 12ch、最寬 70ch
    function fitPu(inp){
        let w = 0; for(const ch of String(inp.value || inp.placeholder || '')) w += ch.charCodeAt(0) > 255 ? 2 : 1;
        inp.style.width = Math.min(70, Math.max(12, w + 2)) + 'ch';
    }

    function recalcAll(){
        let pass = 0, fail = 0;
        pairs.forEach((p, i) => {
            const X1 = parseFloat(p.bsl.x), S1 = parseFloat(p.bsl.s), X2 = parseFloat(p.ext.x), S2 = parseFloat(p.ext.s);
            const row = $('tbodyPairs').querySelector(`tr[data-idx="${i}"][data-side="bsl"]`);   // 結果格在 BSL 列（rowspan 2）
            if(!row) return;
            const zCell=row.querySelector('.z'), zOK=row.querySelector('.zOK'), rCell=row.querySelector('.r'), rOK=row.querySelector('.rOK'), v=row.querySelector('.verdict');
            let zok = null, rok = null;
            if(Number.isFinite(X1) && Number.isFinite(X2) && Number.isFinite(S1) && S1 !== 0){
                const Z = Math.abs(X2 - X1) / S1; zCell.textContent = fmt(Z); zok = Z <= 1; zOK.textContent = zok ? 'Y' : 'N';
            }else{ zCell.textContent = div0(); zOK.textContent = div0(); }
            if(Number.isFinite(S2) && Number.isFinite(S1) && S1 !== 0){
                const R = (S2*S2) / (S1*S1); rCell.textContent = fmt(R); rok = R < 2; rOK.textContent = rok ? 'Y' : 'N';
            }else{ rCell.textContent = div0(); rOK.textContent = div0(); }
            v.className = 'verdict';
            if(zok === null || rok === null){ v.textContent = '—'; }
            else if(zok && rok){ v.textContent = 'PASS'; v.classList.add('pass'); pass++; }
            else { v.textContent = 'FAIL'; v.classList.add('fail'); fail++; }
        });
        const sm = $('summary');
        sm.innerHTML = (pass + fail) ? `檢定：<b class="pass">PASS ${pass}</b>／<b class="fail">FAIL ${fail}</b>／未完成 ${pairs.length - pass - fail}` : '';
    }

    // 表格內輸入 → 回寫資料並重算
    $('tbodyPairs').addEventListener('input', e => {
        const inp = e.target; if(!inp.matches('input')) return;
        const tr = inp.closest('tr'); const idx = Number(tr.getAttribute('data-idx')); const side = tr.getAttribute('data-side');
        const f = inp.getAttribute('data-f'); const obj = pairs[idx][side];
        if(f === 'item') obj.item = inp.value; else obj[f] = inp.value;
        if(f === 'pu') fitPu(inp);
        recalcAll(); save();
    });
    $('tbodyPairs').addEventListener('click', e => {
        // 每列獨立「刪除」：只清空該列內容，編號與 BSL / wafer extend 配對不變
        const c = e.target.closest('button[data-clear]');
        if(c){
            const rowNo = Number(c.getAttribute('data-clear')); const { idx, key } = rowOf(rowNo);
            if(!pairs[idx]) return;
            const item = pairs[idx][key].item;
            pairs[idx][key] = blankSide(); if(item) pairs[idx][key].item = item;
            renderPairs(); save();
            setStatus(`已清空編號 ${rowLabel(rowNo)}`);
            return;
        }
    });
    $('adderHeader').addEventListener('input', save);
    $('btnAddPair').addEventListener('click', () => { pairs.push(newPair()); _nextRow = rowNoOf(pairs.length - 1, 'bsl'); renderPairs(); save(); });
    $('btnClearAll').addEventListener('click', () => { if(!confirm('清除整張檢定表？')) return; pairs = [newPair(), newPair()]; renderPairs(); save(); });

    // 搜尋結果 → 依列編號填入（4.）：每列右側下拉選列編號（BSL 或 wafer extend），
    // 按「加入檢定」就把該列搜尋結果（本次搜尋區間的 N / AVG / STDEVA）寫進那一列；
    // 填完所有下拉自動跳到下一列。要用不同區間時，改上方日期重新搜尋再加入即可。
    let _nextRow = 1;   // 下拉預設的列編號
    function rowOptions(selected){
        const total = pairs.length * 2;
        return Array.from({ length: total }, (_, k) => `<option value="${k + 1}"${String(k + 1) === String(selected) ? ' selected' : ''}>${rowLabel(k + 1)}</option>`).join('');
    }
    function refreshRowSelects(){
        const total = pairs.length * 2;
        if(!(_nextRow >= 1 && _nextRow <= total)) _nextRow = 1;
        document.querySelectorAll('#resBody select.rowsel').forEach(s => { s.innerHTML = rowOptions(_nextRow); });
    }
    function fillRow(i){
        const r = _results[i]; if(!r) return;
        const sel = $('resBody').querySelector(`select.rowsel[data-i="${i}"]`);
        let rowNo = Number(sel && sel.value); const total = pairs.length * 2;
        if(!(rowNo >= 1 && rowNo <= total)) rowNo = 1;
        const { idx, key } = rowOf(rowNo);
        const side = pairs[idx][key];
        const a = r.adj;   // 明細內有排除點 → 用前端重算的值
        side.x = a ? (a.avg == null ? '' : fmt(a.avg)) : (r.AVG == null ? '' : fmt(r.AVG));
        side.s = a ? (a.sd == null ? '' : fmt(a.sd)) : (r.STDEV == null ? '' : fmt(r.STDEV));
        side.n = a ? String(a.n) : (r.N == null ? '0' : String(r.N));
        side.cid = String(r.CHART_ID || '');
        side.src = `${r.PROCESSUNIT || ''} ${_range.start}~${_range.end} ${prodLabel(_range.prod)}`.trim() + (a ? `（排除 ${a.excluded} 點）` : '');
        _nextRow = rowNo < total ? rowNo + 1 : rowNo;
        renderPairs(); save();
        const tr = $('tbodyPairs').querySelector(`tr[data-row="${rowNo}"]`);
        if(tr){ tr.classList.add('flash'); setTimeout(() => tr.classList.remove('flash'), 1300); }
        const rr = $('resBody').querySelector(`tr[data-i="${i}"]`); if(rr) rr.classList.add('added');
        setStatus(`CHART_ID ${r.CHART_ID}（${_range.start}~${_range.end}，${prodLabel(_range.prod)}，N=${side.n}${a ? '，已排除 ' + a.excluded + ' 點' : ''}）已填入編號 ${rowLabel(rowNo)}` + (_nextRow !== rowNo ? `；下一列：${rowLabel(_nextRow)}` : ''));
    }
    $('resBody').addEventListener('click', e => {
        const a = e.target.closest('button[data-add]'); if(a){ fillRow(Number(a.getAttribute('data-add'))); return; }
        const x = e.target.closest('button[data-ex]'); if(x){ togglePoint(Number(x.closest('tr.vals').getAttribute('data-vi')), Number(x.getAttribute('data-ex'))); return; }
        const rs = e.target.closest('button[data-restore]'); if(rs){ restorePoints(Number(rs.getAttribute('data-restore'))); return; }
        const t = e.target.closest('button[data-trend]'); if(t){ toggleTrend(Number(t.getAttribute('data-trend')), t); return; }
        const mm = e.target.closest('button[data-match]'); if(mm){ toggleMatch(Number(mm.getAttribute('data-match')), mm); return; }
        const v = e.target.closest('button[data-vals]'); if(v){ toggleValues(Number(v.getAttribute('data-vals')), v); }
    });

    // 複製檢定表（TSV，可直接貼到 Excel）
    $('btnCopy').addEventListener('click', () => {
        const head = ['編號','Item','PU','CHART_ID', $('adderHeader').value || 'ADDER','σ','/X2-X1//σ1','≦1','σ2^2/σ1^2','(σ2^2/σ1^2)<2','檢定結果'];
        const lines = [head.join('\t')];
        pairs.forEach((p, i) => {
            const ext = $('tbodyPairs').querySelector(`tr[data-idx="${i}"][data-side="bsl"]`);   // 結果格在 BSL 列
            const g = c => ext ? ext.querySelector(c).textContent : '';
            lines.push([rowNoOf(i, 'bsl'), p.bsl.item || 'BSL', p.bsl.pu, p.bsl.cid, p.bsl.x, p.bsl.s, '', '', '', '', ''].join('\t'));
            lines.push([rowNoOf(i, 'ext'), p.ext.item || 'wafer extend', p.ext.pu, p.ext.cid, p.ext.x, p.ext.s, g('.z'), g('.zOK'), g('.r'), g('.rOK'), g('.verdict')].join('\t'));
        });
        const text = lines.join('\n');
        const done = () => setStatus('檢定表已複製到剪貼簿');
        if(navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(text).then(done, () => { legacyCopy(text); done(); });
        else { legacyCopy(text); done(); }
    });
    function legacyCopy(text){ const ta=document.createElement('textarea'); ta.value=text; ta.style.position='fixed'; ta.style.opacity='0'; document.body.appendChild(ta); ta.select(); try{ document.execCommand('copy'); }catch(e){} document.body.removeChild(ta); }

    // ===== 初始化 =====
    document.querySelectorAll('.quick button').forEach(b => b.addEventListener('click', () => setQuick(Number(b.getAttribute('data-days')))));
    $('btnSearch').addEventListener('click', doSearch);
    ['qCid','qName','qPu'].forEach(id => $(id).addEventListener('keydown', e => { if(e.key === 'Enter') doSearch(); }));
    setQuick(30);
    load(); renderPairs();
})();
</script>
</body>
</html>
