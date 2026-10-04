import { esc, $, debounce, table, fail, num } from "./ui.js";
import { exportTable } from "./export.js";

// A reusable searchable, filterable, paged list. The search box is created once and never re-rendered,
// so typing, pasting and mobile keyboards all behave normally.
export function listPage(root, cfg) {
  const limit = cfg.pageSize || 25;
  const st = { q: cfg.q || "", f: {}, offset: 0, total: 0, rows: [], seq: 0 };
  (cfg.filters || []).forEach((f) => (st.f[f.key] = f.value ?? ""));
  root.innerHTML = `${cfg.title ? `<div class="top"><div><h2>${esc(cfg.title)}</h2>${cfg.sub ? `<p>${esc(cfg.sub)}</p>` : ""}</div><div class="row">${cfg.actions || ""}</div></div>` : ""}
    <div class="toolbar">${cfg.search ? `<div class="sbox"><input id="lq" type="search" inputmode="search" autocomplete="off" autocapitalize="off" spellcheck="false" placeholder="${esc(cfg.search)}" value="${esc(st.q)}" aria-label="Search"></div>` : ""}
      ${(cfg.filters || []).map((f) => `<select data-f="${f.key}" aria-label="${esc(f.label)}">${f.options.map(([v, l]) => `<option value="${esc(v)}" ${v === (f.value ?? "") ? "selected" : ""}>${esc(l)}</option>`).join("")}</select>`).join("")}
      <button class="btn ghost sm" type="button" id="lcsv">Export CSV</button></div>
    <div class="mut sumline" id="lsum" aria-live="polite"></div><div id="lres"></div><div id="lpg" class="pager"></div>`;
  const res = $("#lres", root), sum = $("#lsum", root), pg = $("#lpg", root);

  async function load() {
    const my = ++st.seq; res.classList.add("busy");
    try {
      const r = await cfg.fetch({ q: st.q, f: st.f, offset: st.offset, limit });
      if (my !== st.seq) return;
      st.rows = r.rows || []; st.total = r.total ?? st.rows.length; res.classList.remove("busy");
      res.innerHTML = (cfg.before ? cfg.before(r) : "") + table(cfg.columns.map((c) => c.h), st.rows.map((row) => ({ attr: cfg.onRow ? `class="click" tabindex="0"` : "", cells: cfg.columns.map((c) => c.cell(row)) })), { empty: cfg.empty || "No results. Try a different search or filter." });
      const from = st.total ? st.offset + 1 : 0, to = Math.min(st.offset + limit, st.total);
      sum.textContent = st.total ? `Showing ${num(from)}–${num(to)}${r.more ? "" : ` of ${num(st.total)}`}` : "";
      pg.innerHTML = st.total > limit ? `<button class="btn ghost sm" id="pp" ${st.offset ? "" : "disabled"}>Previous</button><span class="mut">Page ${Math.floor(st.offset / limit) + 1} of ${Math.ceil(st.total / limit)}</span><button class="btn ghost sm" id="pn" ${to >= st.total ? "disabled" : ""}>Next</button>` : "";
      $("#pp", pg)?.addEventListener("click", () => { st.offset = Math.max(0, st.offset - limit); load(); window.scrollTo({ top: 0 }); });
      $("#pn", pg)?.addEventListener("click", () => { st.offset += limit; load(); window.scrollTo({ top: 0 }); });
      if (cfg.onRow) [...res.querySelectorAll("tbody tr.click")].forEach((tr, i) => {
        const go = (e) => { if (e.target.closest("a,button,input,select,textarea")) return; cfg.onRow(st.rows[i], load); };
        tr.addEventListener("click", go); tr.addEventListener("keydown", (e) => { if (e.key === "Enter") go(e); });
      });
      cfg.after?.(res, st.rows, load);
    } catch (e) { res.classList.remove("busy"); res.innerHTML = `<div class="panel err">${esc(e.message)}</div>`; }
  }
  const soon = debounce(() => { st.offset = 0; load(); }, 280);
  const q = $("#lq", root);
  if (q) {
    q.addEventListener("input", () => { st.q = q.value.trim(); soon(); });
    q.addEventListener("keydown", (e) => { if (e.key === "Enter") { st.q = q.value.trim(); st.offset = 0; load(); } });
  }
  root.querySelectorAll("select[data-f]").forEach((s) => s.addEventListener("change", () => { st.f[s.dataset.f] = s.value; st.offset = 0; load(); }));
  $("#lcsv", root).addEventListener("click", async () => {
    try {
      const rows = []; let off = 0, total = Infinity;
      while (off < total && rows.length < 2000) { const r = await cfg.fetch({ q: st.q, f: st.f, offset: off, limit: 100 }); total = r.total ?? (r.rows || []).length; if (!(r.rows || []).length) break; rows.push(...r.rows); off += 100; }
      await exportTable(cfg.exportName || cfg.title || "list", cfg.columns.filter((c) => c.csv).map((c) => c.h), rows.map((r) => cfg.columns.filter((c) => c.csv).map((c) => c.csv(r))));
    } catch (e) { fail(e); }
  });
  load();
  return { reload: load };
}
