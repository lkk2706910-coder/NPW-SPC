<%@ Page Language="C#" AutoEventWireup="true" Inherits="NPW_Inspection" CodeFile="NPW_inspection_tool.aspx.cs" EnableSessionState="false" %>
<!DOCTYPE html>
<html lang="zh-Hant">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>TF2/T_EQ1 NPW inspection tool</title>
    <style>
        :root { --bd: 2px solid #000; --accent: #1976d2; }
        * { box-sizing: border-box; }
        body { margin: 0; background: #f3f6fa; font-family: Arial, "Microsoft JhengHei", "PingFang TC", sans-serif; color: #111; font-size: 14px; }
        .wrap { max-width: 1500px; margin: 0 auto; padding: 14px 16px 60px; }
        h1 { font-size: 20px; margin: 0 0 12px; }
        .card { background: #fff; border: 1px solid #d6dbe3; border-radius: 8px; padding: 12px 14px; margin-bottom: 14px; }
        .card h2 { font-size: 15px; margin: 0 0 10px; color: #0f4aa8; }
        .toolbar { display: flex; gap: 10px; align-items: flex-end; flex-wrap: wrap; }
        .field { display: flex; flex-direction: column; gap: 3px; font-size: 12px; color: #555; }
        .field input, .field select { padding: 6px 8px; border: 1px solid #b8c0cc; border-radius: 6px; font: inherit; font-size: 13px; min-width: 150px; }
        .field input[type=date] { min-width: 150px; }
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
        .res-wrap { overflow-x: auto; }
        table.res { border-collapse: collapse; width: 100%; background: #fff; }
        table.res th, table.res td { border: 1px solid #222; padding: 4px 6px; font-size: 12px; white-space: nowrap; }
        table.res th { background: #e9f0ff; font-weight: 700; position: sticky; top: 0; }
        table.res td.num { text-align: right; font-variant-numeric: tabular-nums; }
        table.res td.c { text-align: center; }
        table.res tr.vals td { background: #fafafa; white-space: normal; }
        table.res tr.added td { background: #fff8d6; }
        .valbox { max-height: 220px; overflow: auto; font-size: 11px; }
        .valbox table { border-collapse: collapse; }
        .valbox td, .valbox th { border: 1px solid #ccc; padding: 2px 6px; }
        .target { display: inline-flex; align-items: center; gap: 6px; font-size: 12px; margin-left: auto; }
        .target select { padding: 4px 6px; border: 1px solid var(--accent); border-radius: 6px; color: var(--accent); font-weight: 700; }

        /* 檢定表格（PCRB，沿用檢定機器人） */
        .pcrb-wrap { overflow-x: auto; }
        table.pcrb { border-collapse: collapse; width: 100%; table-layout: auto; }
        table.pcrb th, table.pcrb td { border: var(--bd); padding: 6px 8px; text-align: center; vertical-align: middle; }
        table.pcrb thead th { background: #fff6a5; font-weight: 700; }
        table.pcrb td.no { background: #e9f0ff; font-weight: 700; font-size: 16px; }
        table.pcrb td.item { background: #f3c19b; }
        table.pcrb td.item.green { background: #b9f0b7; }
        table.pcrb td.pu { background: #c9f6c9; text-align: left; min-width: 260px; }
        table.pcrb td.result { background: #9fc6ff; font-variant-numeric: tabular-nums; }
        table.pcrb td.verdict { font-weight: 700; }
        table.pcrb td.verdict.pass { background: #b9f0b7; color: #0a5c0a; }
        table.pcrb td.verdict.fail { background: #ffb3b3; color: #a00; }
        table.pcrb td.muted { color: rgba(0,0,0,.55); }
        table.pcrb input.cell { width: 100%; border: 0; outline: none; background: transparent; font: inherit; text-align: inherit; }
        table.pcrb input.num { text-align: right; font-variant-numeric: tabular-nums; }
        table.pcrb .meta { display: block; font-size: 11px; color: #555; font-weight: 400; }
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
            <label class="field">Chart_name<input id="qName" type="text" placeholder="包含文字，例 5.5K PA" autocomplete="off" /></label>
            <label class="field">機台（PROCESSUNIT）<input id="qPu" type="text" placeholder="包含文字，例 SACVD-B10" autocomplete="off" /></label>
            <label class="field">開始日期<input id="qStart" type="date" /></label>
            <label class="field">結束日期<input id="qEnd" type="date" /></label>
            <span class="quick">
                <button type="button" class="btn ghost small" data-days="7">近 7 天</button>
                <button type="button" class="btn ghost small" data-days="30">近 30 天</button>
                <button type="button" class="btn ghost small" data-days="90">近 90 天</button>
            </span>
            <button type="button" class="btn" id="btnSearch">搜尋</button>
            <span class="status" id="qStatus"></span>
        </div>
        <div class="hint" style="margin-top:6px;">Chart_ID / Chart_name / 機台 至少填一項（可組合）；時間區間依 UPDATE_TIME，結束日含當天，最長 400 天。每張 chart 只顯示一列：N = 筆數、AVG = MEAN_VALUE 平均、STDEVA = 樣本標準差（Excel STDEV.S / STDEVA）。</div>
    </div>

    <!-- 2. 搜尋結果 -->
    <div class="card">
        <div class="toolbar" style="margin-bottom:8px;">
            <h2 style="margin:0;">搜尋結果 <small id="resInfo" class="hint"></small></h2>
            <span class="target">加入到編號 <select id="targetNo"></select><span class="hint">（按列上的「BSL」或「wafer extend」填入該編號）</span></span>
        </div>
        <div class="res-wrap">
            <table class="res" id="resTable">
                <thead>
                    <tr>
                        <th>加入</th><th>CHART_ID</th><th>CHART_NAME</th><th>機台</th><th>Type</th>
                        <th>N</th><th>AVG</th><th>STDEVA</th><th>Min</th><th>Max</th><th>首筆</th><th>末筆</th><th>明細</th>
                    </tr>
                </thead>
                <tbody id="resBody"><tr><td colspan="13" class="hint">尚未搜尋</td></tr></tbody>
            </table>
        </div>
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
                        <th>N</th>
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
            <button type="button" class="btn ghost" id="btnAddPair">＋ 新增編號</button>
            <button type="button" class="btn ghost" id="btnCopy">複製檢定表</button>
            <button type="button" class="btn danger" id="btnClearAll">全部清除</button>
            <span class="hint">X / σ 可手動修改；/X2-X1//σ1 ≦ 1 且 σ2²/σ1² &lt; 2 才算 PASS。內容會自動保存在此瀏覽器。</span>
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
    let _range = { start:'', end:'' };
    function setQuick(days){
        const end = new Date(); const start = new Date(); start.setDate(end.getDate() - days + 1);
        $('qStart').value = ymd(start); $('qEnd').value = ymd(end);
    }
    function setStatus(t, err){ const s=$('qStatus'); s.textContent=t||''; s.className='status'+(err?' err':''); }

    async function doSearch(){
        const cid = $('qCid').value.trim(), cname = $('qName').value.trim(), pu = $('qPu').value.trim();
        if(!cid && !cname && !pu){ setStatus('請至少填 Chart_ID / Chart_name / 機台 其中一項', true); return; }
        if(!$('qEnd').value) $('qEnd').value = ymd(new Date());
        if(!$('qStart').value){ const d=new Date($('qEnd').value+'T00:00:00'); d.setDate(d.getDate()-29); $('qStart').value=ymd(d); }
        const qs = new URLSearchParams({ op:'search', start:$('qStart').value, end:$('qEnd').value });
        if(cid) qs.set('cid', cid); if(cname) qs.set('cname', cname); if(pu) qs.set('pu', pu);
        $('btnSearch').disabled = true; setStatus('查詢中…');
        try{
            const res = await fetch(PAGE + '?' + qs.toString(), { cache:'no-store' });
            const data = await res.json();
            if(!data.ok) throw new Error(data.error || ('HTTP ' + res.status));
            _results = data.rows || [];
            _range = { start:data.start, end:data.end };
            renderResults();
            setStatus('完成：' + _results.length + ' 張 chart' + (data.truncated ? '（已達上限，請縮小條件）' : ''));
        }catch(e){
            _results = []; renderResults();
            setStatus('查詢失敗：' + e.message, true);
        }finally{ $('btnSearch').disabled = false; }
    }

    function renderResults(){
        const tb = $('resBody');
        $('resInfo').textContent = _results.length ? `（${_range.start} ~ ${_range.end}，${_results.length} 張 chart）` : '';
        if(!_results.length){ tb.innerHTML = '<tr><td colspan="13" class="hint">無資料</td></tr>'; return; }
        let html = '';
        _results.forEach((r, i) => {
            html += `<tr data-i="${i}">
                <td class="c"><button type="button" class="btn small" data-add="bsl" data-i="${i}" title="填入目前編號的 BSL（X1、σ1）">BSL</button>
                    <button type="button" class="btn small ghost" data-add="ext" data-i="${i}" title="填入目前編號的 wafer extend（X2、σ2）">wafer extend</button></td>
                <td>${esc(r.CHART_ID)}</td><td>${esc(r.CHART_NAME)}</td><td>${esc(r.PROCESSUNIT)}</td><td class="c">${esc(r.CHART_TYPE)}</td>
                <td class="num">${esc(r.N)}</td><td class="num">${fmt(r.AVG)}</td><td class="num">${r.STDEV == null ? '—' : fmt(r.STDEV)}</td>
                <td class="num">${fmt(r.MIN)}</td><td class="num">${fmt(r.MAX)}</td>
                <td>${esc(r.FIRST_TIME)}</td><td>${esc(r.LAST_TIME)}</td>
                <td class="c"><button type="button" class="btn small ghost" data-vals="${i}">明細</button></td>
            </tr>`;
        });
        tb.innerHTML = html;
    }

    // 明細：列出區間內每一筆 MEAN_VALUE（可對照 AVG / STDEVA）
    async function toggleValues(i, btn){
        const tr = btn.closest('tr'); const next = tr.nextElementSibling;
        if(next && next.classList.contains('vals')){ next.remove(); btn.textContent='明細'; return; }
        const r = _results[i]; btn.disabled = true;
        try{
            const qs = new URLSearchParams({ op:'values', cid:r.CHART_ID, start:_range.start, end:_range.end });
            const res = await fetch(PAGE + '?' + qs.toString(), { cache:'no-store' });
            const data = await res.json();
            if(!data.ok) throw new Error(data.error || ('HTTP ' + res.status));
            const rows = data.rows || [];
            const vals = rows.map(x => Number(x.mean)).filter(Number.isFinite);
            const n = vals.length, avg = n ? vals.reduce((s,v)=>s+v,0)/n : NaN;
            const sd = n >= 2 ? Math.sqrt(vals.reduce((s,v)=>s+(v-avg)*(v-avg),0)/(n-1)) : NaN;
            let inner = `<div class="hint">共 ${n} 筆；前端重算 AVG = ${fmt(avg)}、STDEVA = ${Number.isFinite(sd)?fmt(sd):'—'}</div><div class="valbox"><table><tr><th>#</th><th>UPDATE_TIME</th><th>CHART_SEQ</th><th>MEAN_VALUE</th><th>LOT</th><th>WAFER</th></tr>`;
            rows.forEach((x, k) => { inner += `<tr><td>${k+1}</td><td>${esc(x.d)}</td><td>${esc(x.seq)}</td><td style="text-align:right">${esc(x.mean)}</td><td>${esc(x.lot)}</td><td>${esc(x.wafer)}</td></tr>`; });
            inner += '</table></div>';
            const vr = document.createElement('tr'); vr.className = 'vals';
            vr.innerHTML = `<td colspan="13">${inner}</td>`;
            tr.after(vr); btn.textContent = '收合';
        }catch(e){ alert('明細載入失敗：' + e.message); }
        finally{ btn.disabled = false; }
    }

    // ===== 3/4/5. 檢定表（PCRB）=====
    // 每個編號兩列：BSL（X1、σ1）與 wafer extend（X2、σ2）；公式沿用檢定機器人：
    //   Z = |X2-X1| / σ1（≦1 為 Y）、R = σ2^2 / σ1^2（<2 為 Y）；兩者皆 Y 才 PASS
    const STORE_KEY = 'npwInspect.pairs.v1';
    let pairs = [];   // {no, bsl:{pu,x,s,n,cid,src}, ext:{pu,x,s,n,cid,src}}

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
        const metaHtml = side.cid ? `<span class="meta">CHART_ID ${esc(side.cid)}${side.src ? '　' + esc(side.src) : ''}</span>` : '';
        let cells = `
            <td class="item${isExt ? ' green' : ''}"><input class="cell" data-f="item" value="${esc(label)}" aria-label="Item"></td>
            <td class="pu"><input class="cell" data-f="pu" value="${esc(side.pu)}" placeholder="PU / Chart name" aria-label="PU">${metaHtml}</td>
            <td><input class="cell num" data-f="x" type="number" step="any" value="${esc(side.x)}" placeholder="${isExt ? 'X2' : 'X1'}" aria-label="X"></td>
            <td><input class="cell num" data-f="s" type="number" step="any" value="${esc(side.s)}" placeholder="${isExt ? 'σ2' : 'σ1'}" aria-label="σ"></td>
            <td class="muted">${esc(side.n)}</td>`;
        if(isExt){
            cells += `<td class="result z">—</td><td class="result zOK">—</td><td class="result r">—</td><td class="result rOK">—</td><td class="verdict">—</td>`;
        }else{
            cells += `<td class="muted">—</td><td class="muted">—</td><td class="muted">—</td><td class="muted">—</td><td class="muted">—</td>`;
        }
        return `<tr data-idx="${idx}" data-side="${key}">${isExt ? '' : `<td class="no" rowspan="2">${idx + 1}</td>`}${cells}${isExt ? '' : `<td rowspan="2"><button type="button" class="btn small danger" data-del="${idx}">刪除</button></td>`}</tr>`;
    }

    function renderPairs(){
        const tb = $('tbodyPairs');
        tb.innerHTML = pairs.map((p, i) => sideRow(i, 'bsl', p.bsl, p.bsl.item || 'BSL') + sideRow(i, 'ext', p.ext, p.ext.item || 'wafer extend')).join('');
        const sel = $('targetNo'); const cur = sel.value;
        sel.innerHTML = pairs.map((p, i) => `<option value="${i}">${i + 1}</option>`).join('');
        if(cur !== '' && Number(cur) < pairs.length) sel.value = cur;
        recalcAll();
    }

    function recalcAll(){
        let pass = 0, fail = 0;
        pairs.forEach((p, i) => {
            const X1 = parseFloat(p.bsl.x), S1 = parseFloat(p.bsl.s), X2 = parseFloat(p.ext.x), S2 = parseFloat(p.ext.s);
            const row = $('tbodyPairs').querySelector(`tr[data-idx="${i}"][data-side="ext"]`);
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
        recalcAll(); save();
    });
    $('tbodyPairs').addEventListener('click', e => {
        const b = e.target.closest('button[data-del]'); if(!b) return;
        const idx = Number(b.getAttribute('data-del'));
        if(!confirm('刪除編號 ' + (idx + 1) + '？')) return;
        pairs.splice(idx, 1); if(!pairs.length) pairs.push(newPair());
        renderPairs(); save();
    });
    $('adderHeader').addEventListener('input', save);
    $('btnAddPair').addEventListener('click', () => { pairs.push(newPair()); renderPairs(); save(); $('targetNo').value = String(pairs.length - 1); });
    $('btnClearAll').addEventListener('click', () => { if(!confirm('清除整張檢定表？')) return; pairs = [newPair(), newPair()]; renderPairs(); save(); });

    // 搜尋結果 → 填入編號（4.）
    function addToPair(i, which){
        const r = _results[i]; if(!r) return;
        let idx = Number($('targetNo').value); if(!(idx >= 0 && idx < pairs.length)) idx = 0;
        const side = pairs[idx][which];
        side.pu = String(r.CHART_NAME || '');
        side.x = r.AVG == null ? '' : fmt(r.AVG);
        side.s = r.STDEV == null ? '' : fmt(r.STDEV);
        side.n = r.N == null ? '' : String(r.N);
        side.cid = String(r.CHART_ID || '');
        side.src = `${r.PROCESSUNIT || ''} ${_range.start}~${_range.end}`.trim();
        renderPairs(); save();
        const tr = $('tbodyPairs').querySelector(`tr[data-idx="${idx}"][data-side="${which}"]`);
        if(tr){ tr.classList.add('flash'); setTimeout(() => tr.classList.remove('flash'), 1300); }
        const rr = $('resBody').querySelector(`tr[data-i="${i}"]`); if(rr) rr.classList.add('added');
        setStatus(`已將 CHART_ID ${r.CHART_ID} 填入編號 ${idx + 1} 的 ${which === 'bsl' ? 'BSL' : 'wafer extend'}`);
    }
    $('resBody').addEventListener('click', e => {
        const a = e.target.closest('button[data-add]'); if(a){ addToPair(Number(a.getAttribute('data-i')), a.getAttribute('data-add')); return; }
        const v = e.target.closest('button[data-vals]'); if(v){ toggleValues(Number(v.getAttribute('data-vals')), v); }
    });

    // 複製檢定表（TSV，可直接貼到 Excel）
    $('btnCopy').addEventListener('click', () => {
        const head = ['編號','Item','PU','CHART_ID', $('adderHeader').value || 'ADDER','σ','N','/X2-X1//σ1','≦1','σ2^2/σ1^2','(σ2^2/σ1^2)<2','檢定結果'];
        const lines = [head.join('\t')];
        pairs.forEach((p, i) => {
            const ext = $('tbodyPairs').querySelector(`tr[data-idx="${i}"][data-side="ext"]`);
            const g = c => ext ? ext.querySelector(c).textContent : '';
            lines.push([i+1, p.bsl.item || 'BSL', p.bsl.pu, p.bsl.cid, p.bsl.x, p.bsl.s, p.bsl.n, '', '', '', '', ''].join('\t'));
            lines.push([i+1, p.ext.item || 'wafer extend', p.ext.pu, p.ext.cid, p.ext.x, p.ext.s, p.ext.n, g('.z'), g('.zOK'), g('.r'), g('.rOK'), g('.verdict')].join('\t'));
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
