import { esc, ngn, num } from "./ui.js";

const nice = (max) => { if (max <= 4) return 4; const p = Math.pow(10, Math.floor(Math.log10(max))); const n = max / p; return (n <= 1 ? 1 : n <= 2 ? 2 : n <= 5 ? 5 : 10) * p; };
const compact = (v, money) => { const a = Math.abs(v); const s = a >= 1e6 ? (v / 1e6).toFixed(1).replace(/\.0$/, "") + "M" : a >= 1e3 ? (v / 1e3).toFixed(1).replace(/\.0$/, "") + "k" : String(Math.round(v * 10) / 10); return money ? "₦" + s : s; };
const dayLabel = (d) => new Date(d + "T12:00:00").toLocaleDateString("en-NG", { day: "numeric", month: "short" });

// Area/line chart. points: [{day:'2026-10-01', value:3}]
export function lineChart(points, { money = false, color = "#00A62B", id = "c" + Math.random().toString(36).slice(2, 7) } = {}) {
  const W = 460, H = 190, L = 46, R = 10, T = 10, B = 24;
  const pts = (points || []).map((p) => ({ d: p.day, v: Number(p.value) || 0 }));
  if (!pts.length) return `<p class="mut pad">No data for this period.</p>`;
  const total = pts.reduce((a, p) => a + p.v, 0);
  const top = nice(Math.max(...pts.map((p) => p.v), 1));
  const x = (i) => L + (pts.length === 1 ? (W - L - R) / 2 : (i * (W - L - R)) / (pts.length - 1));
  const y = (v) => T + (1 - v / top) * (H - T - B);
  const line = pts.map((p, i) => `${i ? "L" : "M"}${x(i).toFixed(1)},${y(p.v).toFixed(1)}`).join("");
  const area = `${line}L${x(pts.length - 1).toFixed(1)},${H - B}L${x(0).toFixed(1)},${H - B}Z`;
  const grid = [0, 1, 2, 3, 4].map((g) => { const v = (top * g) / 4; return `<line x1="${L}" x2="${W - R}" y1="${y(v)}" y2="${y(v)}" class="gl"/><text x="${L - 6}" y="${y(v) + 4}" text-anchor="end" class="gt">${compact(v, money)}</text>`; }).join("");
  const xl = [0, Math.floor((pts.length - 1) / 2), pts.length - 1].filter((v, i, a) => a.indexOf(v) === i).map((i) => `<text x="${x(i)}" y="${H - 6}" text-anchor="${i === 0 ? "start" : i === pts.length - 1 ? "end" : "middle"}" class="gt">${dayLabel(pts[i].d)}</text>`).join("");
  const hit = pts.map((p, i) => `<g><rect x="${x(i) - (W - L - R) / pts.length / 2}" y="${T}" width="${(W - L - R) / pts.length}" height="${H - T - B}" fill="transparent"><title>${esc(dayLabel(p.d))}: ${money ? ngn(p.v) : num(p.v)}</title></rect>${pts.length <= 45 && p.v ? `<circle cx="${x(i)}" cy="${y(p.v)}" r="3" fill="${color}"/>` : ""}</g>`).join("");
  return `<svg class="chart" viewBox="0 0 ${W} ${H}" role="img" aria-label="Chart, total ${money ? ngn(total) : num(total)}"><defs><linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${color}" stop-opacity=".28"/><stop offset="1" stop-color="${color}" stop-opacity="0"/></linearGradient></defs>${grid}${xl}<path d="${area}" fill="url(#${id})"/><path d="${line}" fill="none" stroke="${color}" stroke-width="2.2" stroke-linejoin="round" stroke-linecap="round"/>${hit}</svg>`;
}
export const sum = (points) => (points || []).reduce((a, p) => a + (Number(p.value) || 0), 0);

// Horizontal bars for breakdowns. items: [{label, value}]
export function hbars(items, { money = false } = {}) {
  const list = (items || []).filter((i) => Number(i.value) > 0);
  if (!list.length) return `<p class="mut pad">Nothing to show yet.</p>`;
  const max = Math.max(...list.map((i) => Number(i.value)));
  const tot = list.reduce((a, i) => a + Number(i.value), 0);
  return `<div class="hb">${list.map((i) => `<div class="hbr"><span class="hbl" title="${esc(i.label)}">${esc(String(i.label ?? "—").replaceAll("_", " "))}</span><span class="hbt"><i style="width:${Math.max(3, (Number(i.value) / max) * 100)}%"></i></span><span class="hbv">${money ? ngn(i.value) : num(i.value)} <small>${Math.round((Number(i.value) / tot) * 100)}%</small></span></div>`).join("")}</div>`;
}
