export const $ = (s, r = document) => r.querySelector(s);
export const $$ = (s, r = document) => [...r.querySelectorAll(s)];
export const esc = (v) => String(v ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
export const ngn = (n) => "₦" + Number(n || 0).toLocaleString("en-NG");
export const num = (n) => Number(n || 0).toLocaleString("en-NG");
const TZ = "Africa/Lagos";
export const dt = (s) => (s ? new Date(s).toLocaleString("en-NG", { dateStyle: "medium", timeStyle: "short", timeZone: TZ }) : "—");
export const dd = (s) => (s ? new Date(s).toLocaleDateString("en-NG", { dateStyle: "medium", timeZone: TZ }) : "—");
export function ago(s) {
  if (!s) return "never";
  const m = Math.floor((Date.now() - new Date(s)) / 60000);
  if (m < 1) return "just now"; if (m < 60) return `${m} min ago`;
  const h = Math.floor(m / 60); if (h < 24) return `${h} hr ago`;
  const d = Math.floor(h / 24); if (d < 30) return `${d} day${d > 1 ? "s" : ""} ago`;
  return dd(s);
}
export const short = (id) => String(id || "").slice(0, 8);
export const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
export const fullName = (p) => [p?.first_name, p?.last_name].filter(Boolean).join(" ").trim() || "Unnamed user";
export const label = (s) => String(s ?? "—").replaceAll("_", " ");
export const stars = (n) => "★".repeat(Math.round(n || 0)) + "☆".repeat(5 - Math.round(n || 0));

const GOOD = /^(active|verified|live|successful|released|resolved|published|actioned|approved|confirmed|completed|paid|open_ok)$/i;
const BAD = /^(suspended|banned|rejected|failed|flagged|hidden|expired|cancelled|past_due|disputed|refunded|abandoned|removed|urgent|high)$/i;
const WARN = /^(pending|pending_review|open|reviewing|grace|escrow_held|release_pending|requested|changes_requested|escalated|under_review|return_pending|normal)$/i;
export function pill(s, tone) {
  const t = tone ?? (GOOD.test(s) ? "" : BAD.test(s) ? "r" : WARN.test(s) ? "a" : "n");
  return `<span class="pill ${t}">${esc(label(s))}</span>`;
}

export function initials(name) { return (String(name || "?").trim().split(/\s+/).slice(0, 2).map((w) => w[0]).join("") || "?").toUpperCase(); }
export function avatar(url, name, size = 40) {
  const s = `style="width:${size}px;height:${size}px;font-size:${Math.round(size * 0.38)}px"`;
  return url ? `<img class="av" ${s} src="${esc(url)}" alt="" loading="lazy" referrerpolicy="no-referrer">` : `<span class="av ph" ${s} aria-hidden="true">${esc(initials(name))}</span>`;
}
export const userLink = (id, text) => (UUID.test(id || "") ? `<a class="ulink" href="#/users/${id}">${esc(text || "Open profile")}</a>` : esc(text || "—"));
export const copyBtn = (text) => (text ? `<button class="copy" type="button" data-copy="${esc(text)}" title="Copy" aria-label="Copy">${icon("copy")}</button>` : "");

const P = {
  copy: '<rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15V6a2 2 0 0 1 2-2h9"/>',
  down: '<path d="M12 4v11m0 0 4-4m-4 4-4-4M5 20h14"/>',
  print: '<path d="M7 9V3h10v6M7 17H5a2 2 0 0 1-2-2v-4a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v4a2 2 0 0 1-2 2h-2"/><rect x="7" y="14" width="10" height="7" rx="1"/>',
  back: '<path d="M15 6l-6 6 6 6"/>', bell: '<path d="M18 16v-5a6 6 0 1 0-12 0v5l-2 2h16l-2-2ZM10 21h4"/>',
  shield: '<path d="M12 3 4 6v6c0 4.5 3.2 8 8 9 4.8-1 8-4.5 8-9V6l-8-3Z"/>', note: '<path d="M5 4h14v12l-5 4H5Z"/><path d="M14 20v-4h5M8 9h8M8 13h4"/>',
  star: '<path d="m12 3 2.6 5.6 6 .7-4.5 4.1 1.2 6L12 16.4 6.7 19.4l1.2-6L3.4 9.3l6-.7L12 3Z"/>',
};
export function icon(n, size = 16) { return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${P[n] || ""}</svg>`; }

export function toast(m, kind = "") {
  const t = $("#toast"); if (!t) return;
  t.textContent = m; t.className = kind; t.style.display = "block";
  clearTimeout(toast.t); toast.t = setTimeout(() => (t.style.display = "none"), 4200);
}
export const fail = (e) => toast(e?.message || String(e), "bad");

export function debounce(fn, ms = 300) { let t; return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); }; }

export function modal(html, { wide = false } = {}) {
  const m = document.createElement("div"); m.className = "modal"; m.setAttribute("role", "dialog"); m.setAttribute("aria-modal", "true");
  m.innerHTML = `<div class="${wide ? "wide" : ""}">${html}</div>`;
  const close = () => { m.remove(); document.removeEventListener("keydown", onKey); };
  const onKey = (e) => { if (e.key === "Escape") close(); };
  m.addEventListener("mousedown", (e) => { if (e.target === m) close(); });
  document.addEventListener("keydown", onKey);
  document.body.appendChild(m);
  m.close = close; m.querySelectorAll("[data-x]").forEach((b) => b.addEventListener("click", close));
  const first = m.querySelector("input,textarea,select"); if (first) setTimeout(() => first.focus(), 30);
  return m;
}
export function ask({ title, intro = "", fields = [], confirm = "Confirm", danger = false }) {
  return new Promise((res) => {
    const field = (f, i) => `<label for="ask${i}">${esc(f.label)}</label>${
      f.type === "select" ? `<select id="ask${i}" data-i="${i}">${f.options.map((o) => { const [v, l] = Array.isArray(o) ? o : [o, o]; return `<option value="${esc(v)}">${esc(l)}</option>`; }).join("")}</select>`
      : f.type === "number" ? `<input id="ask${i}" data-i="${i}" type="number" inputmode="numeric" value="${esc(f.value ?? "")}">`
      : f.type === "text" ? `<input id="ask${i}" data-i="${i}" type="text" maxlength="${f.max || 200}" placeholder="${esc(f.placeholder || "")}">`
      : `<textarea id="ask${i}" data-i="${i}" maxlength="${f.max || 1000}" placeholder="${esc(f.placeholder || "")}"></textarea>`}`;
    const m = modal(`<h2>${esc(title)}</h2>${intro ? `<p class="mut">${esc(intro)}</p>` : ""}${fields.map(field).join("")}
      <p class="err" role="alert"></p>
      <div class="row end"><button class="btn sec" type="button" data-x>Cancel</button><button class="btn ${danger ? "red" : ""}" type="button" data-ok>${esc(confirm)}</button></div>`);
    let done = false; const finish = (v) => { if (done) return; done = true; m.close(); res(v); };
    m.querySelectorAll("[data-x]").forEach((b) => b.addEventListener("click", () => finish(null)));
    m.querySelector("[data-ok]").addEventListener("click", () => {
      const v = fields.map((_, i) => m.querySelector(`[data-i="${i}"]`).value.trim());
      const bad = fields.findIndex((f, i) => f.required && !v[i]);
      if (bad >= 0) { m.querySelector(".err").textContent = `${fields[bad].label} is required.`; return; }
      finish(v);
    });
  });
}

export function table(cols, rows, { empty = "Nothing here yet." } = {}) {
  return `<div class="tw"><div class="scroll"><table><thead><tr>${cols.map((c) => `<th scope="col">${esc(c)}</th>`).join("")}</tr></thead><tbody>${
    rows.length ? rows.map((r) => `<tr ${r.attr || ""}>${r.cells.map((c, i) => `<td data-l="${esc(cols[i] || "")}">${c}</td>`).join("")}</tr>`).join("")
      : `<tr><td class="empty" data-l="" colspan="${cols.length}">${esc(empty)}</td></tr>`}</tbody></table></div></div>`;
}
export const kv = (pairs) => `<dl class="kvl">${pairs.filter((p) => p).map(([k, v]) => `<div><dt>${esc(k)}</dt><dd>${v === undefined || v === null || v === "" ? '<span class="mut">—</span>' : v}</dd></div>`).join("")}</dl>`;
export const empty = (t) => `<p class="mut pad">${esc(t)}</p>`;
