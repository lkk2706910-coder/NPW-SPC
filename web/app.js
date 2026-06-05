/* NPW-SPC 資料分析儀表板前端邏輯 */
(function () {
  "use strict";

  const statusEl = document.getElementById("status");
  const dashboard = document.getElementById("dashboard");
  const sourceLabel = document.getElementById("sourceLabel");
  const updatedLabel = document.getElementById("updatedLabel");

  let state = {
    columns: [],   // [{ name, numeric }]
    rows: [],      // array of objects
  };
  let lineChart = null;
  let histChart = null;

  function setStatus(msg, isError) {
    statusEl.textContent = msg || "";
    statusEl.classList.toggle("error", !!isError);
  }

  // ---------- 載入資料 ----------

  async function loadFromManifest() {
    setStatus("正在讀取最新資料…");
    try {
      const mRes = await fetch("data/manifest.json", { cache: "no-store" });
      if (!mRes.ok) throw new Error("no manifest");
      const manifest = await mRes.json();
      const fileRes = await fetch("data/" + manifest.latest, { cache: "no-store" });
      if (!fileRes.ok) throw new Error("找不到資料檔 " + manifest.latest);

      sourceLabel.textContent = "資料來源：" + (manifest.sourceUrl || manifest.latest);
      if (manifest.downloadedAt) {
        updatedLabel.textContent =
          "更新時間：" + new Date(manifest.downloadedAt).toLocaleString("zh-TW");
      }

      if (/xlsx?$/i.test(manifest.type || manifest.latest)) {
        const buf = await fileRes.arrayBuffer();
        parseExcel(buf);
      } else {
        const text = await fileRes.text();
        parseDelimited(text, manifest.type === "tsv");
      }
    } catch (err) {
      setStatus(
        "尚無自動下載的資料（" + err.message + "）。" +
        "請先執行 scripts/download.py，或用右上角「手動上傳」載入檔案。",
        true
      );
    }
  }

  function handleUpload(file) {
    setStatus("讀取檔案：" + file.name + " …");
    sourceLabel.textContent = "資料來源：" + file.name + "（手動上傳）";
    updatedLabel.textContent = "";
    const name = file.name.toLowerCase();
    const reader = new FileReader();
    if (/\.xlsx?$/.test(name)) {
      reader.onload = (e) => parseExcel(e.target.result);
      reader.readAsArrayBuffer(file);
    } else {
      reader.onload = (e) => parseDelimited(e.target.result, name.endsWith(".tsv"));
      reader.readAsText(file);
    }
  }

  // ---------- 解析 ----------

  function parseDelimited(text, isTsv) {
    const result = Papa.parse(text, {
      header: true,
      dynamicTyping: false,
      skipEmptyLines: true,
      delimiter: isTsv ? "\t" : "",
    });
    ingest(result.data, result.meta.fields || []);
  }

  function parseExcel(arrayBuffer) {
    const wb = XLSX.read(arrayBuffer, { type: "array" });
    const sheet = wb.Sheets[wb.SheetNames[0]];
    const json = XLSX.utils.sheet_to_json(sheet, { defval: "" });
    const fields = json.length ? Object.keys(json[0]) : [];
    ingest(json, fields);
  }

  function ingest(rawRows, fields) {
    if (!rawRows || !rawRows.length) {
      setStatus("檔案沒有可分析的資料列。", true);
      return;
    }
    const columns = fields.map((name) => ({
      name,
      numeric: isNumericColumn(rawRows, name),
    }));
    state = { columns, rows: rawRows };
    render();
    setStatus("");
  }

  function isNumericColumn(rows, field) {
    let seen = 0, numeric = 0;
    for (const r of rows) {
      const v = r[field];
      if (v === "" || v === null || v === undefined) continue;
      seen++;
      if (typeof v === "number" || (!isNaN(parseFloat(v)) && isFinite(v))) numeric++;
      if (seen >= 30) break;
    }
    return seen > 0 && numeric / seen >= 0.8;
  }

  function num(v) {
    if (v === "" || v === null || v === undefined) return NaN;
    return typeof v === "number" ? v : parseFloat(v);
  }

  // ---------- 統計 ----------

  function columnStats(field) {
    const vals = state.rows.map((r) => num(r[field])).filter((v) => !isNaN(v));
    const n = vals.length;
    if (!n) return null;
    const sum = vals.reduce((a, b) => a + b, 0);
    const mean = sum / n;
    const variance = vals.reduce((a, b) => a + (b - mean) ** 2, 0) / n;
    const std = Math.sqrt(variance);
    const sorted = [...vals].sort((a, b) => a - b);
    const median = n % 2 ? sorted[(n - 1) / 2] : (sorted[n / 2 - 1] + sorted[n / 2]) / 2;
    return {
      n,
      mean,
      std,
      min: sorted[0],
      max: sorted[n - 1],
      median,
    };
  }

  const fmt = (v) =>
    Math.abs(v) >= 1000 || (v !== 0 && Math.abs(v) < 0.01)
      ? v.toExponential(2)
      : v.toFixed(2);

  // ---------- 渲染 ----------

  function render() {
    dashboard.hidden = false;
    const numericCols = state.columns.filter((c) => c.numeric);

    renderCards(numericCols);
    renderStatsTable(numericCols);
    renderPreview();
    setupSelectors(numericCols);
  }

  function renderCards(numericCols) {
    const cards = [
      { label: "資料列數", value: state.rows.length.toLocaleString() },
      { label: "欄位數", value: state.columns.length },
      { label: "數值欄位", value: numericCols.length },
    ];
    document.getElementById("summaryCards").innerHTML = cards
      .map((c) => `<div class="card"><div class="label">${c.label}</div><div class="value">${c.value}</div></div>`)
      .join("");
  }

  function renderStatsTable(numericCols) {
    const head = ["欄位", "筆數", "平均", "標準差", "最小", "中位數", "最大"];
    const rows = numericCols.map((c) => {
      const s = columnStats(c.name);
      if (!s) return "";
      return `<tr><td>${esc(c.name)}</td><td>${s.n}</td><td>${fmt(s.mean)}</td><td>${fmt(s.std)}</td><td>${fmt(s.min)}</td><td>${fmt(s.median)}</td><td>${fmt(s.max)}</td></tr>`;
    });
    document.getElementById("statsTable").innerHTML =
      `<thead><tr>${head.map((h) => `<th>${h}</th>`).join("")}</tr></thead><tbody>${rows.join("")}</tbody>`;
  }

  function renderPreview() {
    const cols = state.columns.map((c) => c.name);
    const head = `<thead><tr>${cols.map((c) => `<th>${esc(c)}</th>`).join("")}</tr></thead>`;
    const body = state.rows
      .slice(0, 50)
      .map((r) => `<tr>${cols.map((c) => `<td>${esc(r[c])}</td>`).join("")}</tr>`)
      .join("");
    document.getElementById("previewTable").innerHTML = head + `<tbody>${body}</tbody>`;
  }

  function setupSelectors(numericCols) {
    const xSel = document.getElementById("xAxisSelect");
    const ySel = document.getElementById("ySeriesSelect");
    const hSel = document.getElementById("histSelect");

    // X 軸：所有欄位皆可（含序號）
    const xOptions = [`<option value="__index__">（資料列序號）</option>`]
      .concat(state.columns.map((c) => `<option value="${esc(c.name)}">${esc(c.name)}</option>`));
    xSel.innerHTML = xOptions.join("");

    const numOpts = numericCols.map((c) => `<option value="${esc(c.name)}">${esc(c.name)}</option>`).join("");
    ySel.innerHTML = numOpts;
    hSel.innerHTML = numOpts;

    xSel.onchange = drawLine;
    ySel.onchange = drawLine;
    hSel.onchange = drawHist;

    drawLine();
    drawHist();
  }

  function drawLine() {
    const yField = document.getElementById("ySeriesSelect").value;
    const xField = document.getElementById("xAxisSelect").value;
    if (!yField) return;

    const yVals = state.rows.map((r) => num(r[yField]));
    const labels =
      xField === "__index__"
        ? state.rows.map((_, i) => i + 1)
        : state.rows.map((r) => r[xField]);

    const stats = columnStats(yField);
    const datasets = [
      {
        label: yField,
        data: yVals,
        borderColor: "#38bdf8",
        backgroundColor: "rgba(56,189,248,0.15)",
        borderWidth: 1.5,
        pointRadius: 2,
        tension: 0.15,
        spanGaps: true,
      },
    ];
    // 加上平均線參考
    if (stats) {
      datasets.push({
        label: "平均",
        data: yVals.map(() => stats.mean),
        borderColor: "#f59e0b",
        borderDash: [6, 4],
        borderWidth: 1,
        pointRadius: 0,
      });
    }

    if (lineChart) lineChart.destroy();
    lineChart = new Chart(document.getElementById("lineChart"), {
      type: "line",
      data: { labels, datasets },
      options: baseChartOptions(),
    });
  }

  function drawHist() {
    const field = document.getElementById("histSelect").value;
    if (!field) return;
    const vals = state.rows.map((r) => num(r[field])).filter((v) => !isNaN(v));
    if (!vals.length) return;

    const min = Math.min(...vals);
    const max = Math.max(...vals);
    const binCount = Math.min(20, Math.max(5, Math.ceil(Math.sqrt(vals.length))));
    const width = (max - min) / binCount || 1;
    const bins = new Array(binCount).fill(0);
    for (const v of vals) {
      let idx = Math.floor((v - min) / width);
      if (idx >= binCount) idx = binCount - 1;
      if (idx < 0) idx = 0;
      bins[idx]++;
    }
    const labels = bins.map((_, i) => fmt(min + i * width));

    if (histChart) histChart.destroy();
    histChart = new Chart(document.getElementById("histChart"), {
      type: "bar",
      data: {
        labels,
        datasets: [
          {
            label: "次數",
            data: bins,
            backgroundColor: "rgba(56,189,248,0.6)",
            borderColor: "#38bdf8",
            borderWidth: 1,
          },
        ],
      },
      options: baseChartOptions(),
    });
  }

  function baseChartOptions() {
    const grid = { color: "rgba(148,163,184,0.15)" };
    const ticks = { color: "#94a3b8", maxTicksLimit: 12 };
    return {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { labels: { color: "#e2e8f0" } } },
      scales: {
        x: { grid, ticks },
        y: { grid, ticks: { color: "#94a3b8" } },
      },
    };
  }

  function esc(v) {
    if (v === null || v === undefined) return "";
    return String(v)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;");
  }

  // ---------- 事件 ----------

  document.getElementById("reloadBtn").addEventListener("click", loadFromManifest);
  document.getElementById("fileInput").addEventListener("change", (e) => {
    if (e.target.files[0]) handleUpload(e.target.files[0]);
  });

  loadFromManifest();
})();
