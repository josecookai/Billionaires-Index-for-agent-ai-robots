const fmtUsdB = (b) => `${b.toFixed(2)}B`;
const fmtChg = (v) => (v >= 0 ? `+${v.toFixed(2)}B` : `${v.toFixed(2)}B`);
const clsChg = (v) => (v > 0 ? "good" : v < 0 ? "bad" : "neutral");

function enrichForDisplay(entity, idx) {
  const rank = idx + 1;
  const chg1d = entity.chg1d ?? (((rank % 7) - 3) * 0.15);
  const ytd = entity.ytd ?? (((rank % 9) - 4) * 0.55);
  const chg1dPct = entity.chg1dPct ?? ((chg1d / Math.max(0.01, entity.snw)) * 100);
  const ytdPct = entity.ytdPct ?? ((ytd / Math.max(0.01, entity.snw)) * 100);

  const spark =
    entity.spark ??
    (() => {
      const out = [];
      const base = entity.snw;
      for (let i = 0; i < 10; i++) {
        const drift = (i / 9) * (chg1d * 2);
        const wobble = Math.sin((i + rank) * 0.9) * 0.25;
        out.push(Math.max(0.01, base * (0.86 + i * 0.015) + drift + wobble));
      }
      return out;
    })();

  return { ...entity, chg1d, ytd, chg1dPct, ytdPct, spark };
}

function sparkPath(values, width = 320, height = 84, pad = 10) {
  if (!values?.length) return "";
  const min = Math.min(...values);
  const max = Math.max(...values);
  const span = Math.max(1e-9, max - min);
  const step = (width - pad * 2) / (values.length - 1);
  const points = values.map((v, i) => {
    const x = pad + i * step;
    const y = pad + (height - pad * 2) * (1 - (v - min) / span);
    return [x, y];
  });
  return points.map((p, i) => `${i ? "L" : "M"}${p[0].toFixed(1)},${p[1].toFixed(1)}`).join(" ");
}

function setTicker() {
  const el = document.querySelector("[data-ticker]");
  if (!el) return;
  const a = [];
  const top = [...window.DEMO.universe].sort((x, y) => y.snw - x.snw).map((e, i) => enrichForDisplay(e, i));
  for (const e of top.slice(0, 5)) {
    a.push(`${e.name.toUpperCase()} ${fmtUsdB(e.snw)} ${fmtChg(e.chg1d)} (${e.chg1dPct.toFixed(2)}%)`);
  }
  el.textContent = a.join("  •  ");
}

function openCmdPalette() {
  const b = document.querySelector("#cmdPalette");
  if (!b) return;
  b.style.display = "flex";
  const input = b.querySelector("input");
  input?.focus();
  input.value = "";
}

function closeCmdPalette() {
  const b = document.querySelector("#cmdPalette");
  if (!b) return;
  b.style.display = "none";
}

function routeCmd(cmdRaw) {
  const cmd = (cmdRaw || "").trim().toLowerCase();
  if (!cmd) return;
  if (cmd === "help" || cmd === "?") {
    window.location.href = "./help.html";
    return;
  }
  if (cmd === "index" || cmd === "snw") {
    window.location.href = "./index.html";
    return;
  }
  if (cmd.startsWith("open ")) {
    const q = cmd.slice(5).trim();
    const match = window.DEMO.universe.find((e) => e.id.toLowerCase() === q || e.name.toLowerCase().includes(q));
    if (match) {
      window.location.href = `./entity.html?id=${encodeURIComponent(match.id)}`;
      return;
    }
  }
  if (cmd.startsWith("find ")) {
    const q = cmd.slice(5).trim();
    const url = new URL(window.location.href);
    url.searchParams.set("q", q);
    window.location.href = url.toString();
    return;
  }
}

function bindTopCmd() {
  const input = document.querySelector("[data-cmd-input]");
  if (!input) return;
  input.placeholder = "Cmd: index | open <id/name> | find <text> | help";
  input.addEventListener("keydown", (e) => {
    if (e.key === "Enter") {
      routeCmd(input.value);
      input.value = "";
    }
  });
}

function bindShortcuts() {
  window.addEventListener("keydown", (e) => {
    const isMac = navigator.platform.toLowerCase().includes("mac");
    const mod = isMac ? e.metaKey : e.ctrlKey;
    if (mod && e.key.toLowerCase() === "k") {
      e.preventDefault();
      openCmdPalette();
    }
    if (!e.altKey && !e.metaKey && !e.ctrlKey && !e.shiftKey) {
      const k = e.key.toLowerCase();
      if (k === "i") window.location.href = "./index.html";
      if (k === "?") window.location.href = "./help.html";
    }
    if (e.key === "Escape") {
      closeCmdPalette();
    }
  });
}

function fillRightbar(entity) {
  const rb = document.querySelector("[data-rightbar]");
  if (!rb) return;
  const name = rb.querySelector("[data-rb-name]");
  const type = rb.querySelector("[data-rb-type]");
  const snw = rb.querySelector("[data-rb-snw]");
  const chg = rb.querySelector("[data-rb-chg]");
  const ytd = rb.querySelector("[data-rb-ytd]");
  const tags = rb.querySelector("[data-rb-tags]");
  const spark = rb.querySelector("[data-rb-spark]");

  name.textContent = entity.name;
  type.textContent = `${entity.type.toUpperCase()} • ${entity.country}`;
  snw.textContent = fmtUsdB(entity.snw);
  chg.textContent = `${fmtChg(entity.chg1d)} (${entity.chg1dPct.toFixed(2)}%)`;
  chg.className = `v chg ${clsChg(entity.chg1d)}`;
  ytd.textContent = `${fmtChg(entity.ytd)} (${entity.ytdPct.toFixed(2)}%)`;
  ytd.className = `v chg ${clsChg(entity.ytd)}`;
  tags.textContent = entity.tags.join(", ");

  const d = sparkPath(entity.spark);
  spark.innerHTML = `
    <svg viewBox="0 0 320 84" preserveAspectRatio="none" aria-label="SNW sparkline">
      <path d="${d}" fill="none" stroke="rgba(255,176,0,.85)" stroke-width="2"/>
      <path d="${d} L310,74 L10,74 Z" fill="rgba(255,176,0,.08)" stroke="none"/>
    </svg>
  `;
}

function renderIndex() {
  const table = document.querySelector("[data-index-table]");
  if (!table) return;

  const url = new URL(window.location.href);
  const q = (url.searchParams.get("q") || "").trim().toLowerCase();
  const t = (url.searchParams.get("type") || "").trim().toLowerCase();

  let rows = [...window.DEMO.universe].sort((a, b) => b.snw - a.snw).map((e, i) => enrichForDisplay(e, i));
  if (t) rows = rows.filter((e) => e.type === t);
  if (q) rows = rows.filter((e) => e.name.toLowerCase().includes(q) || e.id.toLowerCase().includes(q) || e.tags.join(" ").toLowerCase().includes(q));

  const tbody = table.querySelector("tbody");
  tbody.innerHTML = "";
  rows.forEach((e, idx) => {
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td>
        <div class="rowTitle">
          <div class="name"><a href="./entity.html?id=${encodeURIComponent(e.id)}">${String(idx + 1).padStart(3, "0")}  ${e.name}</a></div>
          <div class="meta">${e.id} • ${e.type.toUpperCase()} • ${e.category ?? "—"} • ${e.tags.slice(0,2).join(", ")}</div>
        </div>
      </td>
      <td>${fmtUsdB(e.snw)}</td>
      <td class="chg ${clsChg(e.chg1d)}">${fmtChg(e.chg1d)}</td>
      <td class="chg ${clsChg(e.chg1d)}">${e.chg1dPct.toFixed(2)}%</td>
      <td class="chg ${clsChg(e.ytd)}">${fmtChg(e.ytd)}</td>
      <td class="chg ${clsChg(e.ytd)}">${e.ytdPct.toFixed(2)}%</td>
      <td><span class="badge"><span class="dot ${e.chg1d > 0 ? "good" : e.chg1d < 0 ? "bad" : "neutral"}"></span>${e.type}</span></td>
    `;
    tr.addEventListener("mouseenter", () => fillRightbar(e));
    tbody.appendChild(tr);
  });

  const right = rows[0] || window.DEMO.universe[0];
  if (right) fillRightbar(right);

  const filterType = document.querySelector("[data-filter-type]");
  if (filterType) {
    filterType.value = t;
    filterType.addEventListener("change", () => {
      const u = new URL(window.location.href);
      const val = filterType.value;
      if (val) u.searchParams.set("type", val);
      else u.searchParams.delete("type");
      window.location.href = u.toString();
    });
  }
}

function renderEntity() {
  const root = document.querySelector("[data-entity-root]");
  if (!root) return;
  const url = new URL(window.location.href);
  const id = url.searchParams.get("id") || "E-001";
  const base = window.DEMO.universe.find((x) => x.id === id) || window.DEMO.universe[0];
  const idx = Math.max(0, window.DEMO.universe.findIndex((x) => x.id === base.id));
  const e = enrichForDisplay(base, idx);

  root.querySelector("[data-entity-name]").textContent = e.name;
  root.querySelector("[data-entity-meta]").textContent = `${e.id} • ${e.type.toUpperCase()} • ${e.category ?? "—"} • asOf ${window.DEMO.asOf}`;
  root.querySelector("[data-entity-snw]").textContent = fmtUsdB(e.snw);

  const chg = root.querySelector("[data-entity-chg]");
  chg.textContent = `${fmtChg(e.chg1d)} (${e.chg1dPct.toFixed(2)}%)`;
  chg.className = `pill chg ${clsChg(e.chg1d)}`;

  const ytd = root.querySelector("[data-entity-ytd]");
  ytd.textContent = `YTD ${fmtChg(e.ytd)} (${e.ytdPct.toFixed(2)}%)`;
  ytd.className = `pill chg ${clsChg(e.ytd)}`;

  const spark = root.querySelector("[data-entity-spark]");
  const d = sparkPath(e.spark, 600, 140, 12);
  spark.innerHTML = `
    <svg viewBox="0 0 600 140" preserveAspectRatio="none" aria-label="SNW history">
      <path d="${d}" fill="none" stroke="rgba(100,181,255,.85)" stroke-width="2.2"/>
      <path d="${d} L588,128 L12,128 Z" fill="rgba(100,181,255,.08)" stroke="none"/>
    </svg>
  `;

  const comp = root.querySelector("[data-entity-components]");
  const c = e.components;
  comp.innerHTML = `
    <tr><td>V_compute</td><td>${fmtUsdB(c.v_compute)}</td><td class="subtitle">GPU/CPU + power contracts</td></tr>
    <tr><td>V_phys</td><td>${fmtUsdB(c.v_phys)}</td><td class="subtitle">book value (depreciated)</td></tr>
    <tr><td>gamma</td><td>${c.gamma.toFixed(2)}</td><td class="subtitle">hardware depreciation factor</td></tr>
    <tr><td>V_econ</td><td>${fmtUsdB(c.v_econ)}</td><td class="subtitle">annualized econ throughput</td></tr>
    <tr><td>mu</td><td>${c.mu.toFixed(2)}</td><td class="subtitle">industry multiple</td></tr>
    <tr><td>V_crypto</td><td>${fmtUsdB(c.v_crypto)}</td><td class="subtitle">on-chain liquidity</td></tr>
    <tr><td>V_data</td><td>${fmtUsdB(c.v_data || 0)}</td><td class="subtitle">optional data sovereignty</td></tr>
  `;
}

function mountPalette() {
  const b = document.querySelector("#cmdPalette");
  if (!b) return;
  b.addEventListener("click", (e) => {
    if (e.target === b) closeCmdPalette();
  });
  const input = b.querySelector("input");
  input?.addEventListener("keydown", (e) => {
    if (e.key === "Enter") {
      routeCmd(input.value);
      closeCmdPalette();
    }
  });
  const close = b.querySelector("[data-close]");
  close?.addEventListener("click", closeCmdPalette);
}

function init() {
  if (!window.DEMO) {
    // no-op: data.js not loaded
    return;
  }
  bindTopCmd();
  bindShortcuts();
  mountPalette();
  renderIndex();
  renderEntity();
  setTicker();
}

init();
