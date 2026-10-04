import { rpc } from "../core/api.js";
import { $, esc, ngn, num, fail } from "../core/ui.js";
import { lineChart, hbars, sum } from "../core/charts.js";
import { exportTable } from "../core/export.js";

export default async function analytics(el) {
  let days = 30, data = null;
  el.innerHTML = `<div class="top"><div><h2>Analytics</h2><p>How the marketplace is growing and where money moves.</p></div><div class="row"><div class="seg" id="rng">${[7, 30, 90, 365].map((d) => `<button data-d="${d}" class="${d === days ? "on" : ""}">${d === 365 ? "1 year" : d + " days"}</button>`).join("")}</div><button class="btn ghost sm" id="csv">Export CSV</button></div></div><div id="body"></div>`;
  const body = $("#body", el);
  async function draw() {
    body.classList.add("busy");
    try {
      data = await rpc("admin_analytics", { p_days: days }); const t = data.totals, s = data.series, b = data.breakdowns;
      const k = (l, v, sub = "") => `<div class="card"><div class="l">${l}</div><div class="v">${v}</div>${sub ? `<div class="mut small">${sub}</div>` : ""}</div>`;
      const ch = (title, pts, money, color) => `<div class="panel"><div class="chh"><h3>${title}</h3><b>${money ? ngn(sum(pts)) : num(sum(pts))}</b></div>${lineChart(pts, { money, color })}</div>`;
      body.innerHTML = `<div class="cards">${k("Deal volume", ngn(t.gmv), "completed deals")}${k("New members", num(t.new_users))}${k("Plan revenue", ngn(t.plan_revenue))}${k("Dispute rate", (t.dispute_rate ?? 0) + "%", "disputes per deal")}${k("Average rating", t.avg_rating ?? "—")}</div>
      <div class="grid2" style="margin-top:16px">${ch("New members", s.users, false, "#00A62B")}${ch("New listings", s.listings, false, "#7C3AED")}${ch("Deals started", s.transactions, false, "#2563EB")}${ch("Plan revenue", s.revenue, true, "#B26B00")}${ch("Disputes opened", s.disputes, false, "#D4080C")}${ch("Reports filed", s.reports, false, "#DB2777")}</div>
      <div class="grid2"><div class="panel"><h3>Live listings by category</h3>${hbars(b.listings_by_category)}</div><div class="panel"><h3>Members by city</h3>${hbars(b.users_by_city)}</div>
      <div class="panel"><h3>Deals by stage</h3>${hbars(b.transactions_by_state)}</div><div class="panel"><h3>Identity verification</h3>${hbars(b.users_by_verification)}</div>
      <div class="panel"><h3>Active plans</h3>${hbars(b.users_by_plan)}</div><div class="panel"><h3>Reports by reason</h3>${hbars(b.reports_by_reason)}</div></div>`;
    } catch (e) { body.innerHTML = `<div class="panel err">${esc(e.message)}</div>`; }
    body.classList.remove("busy");
  }
  el.querySelectorAll("#rng button").forEach((x) => x.addEventListener("click", () => { days = Number(x.dataset.d); el.querySelectorAll("#rng button").forEach((y) => y.classList.toggle("on", y === x)); draw(); }));
  $("#csv", el).addEventListener("click", async () => {
    if (!data) return;
    try { const names = Object.keys(data.series); const rows = data.series[names[0]].map((p, i) => [p.day, ...names.map((n) => data.series[n][i]?.value ?? 0)]); await exportTable(`analytics-${days}d`, ["Day", ...names], rows); } catch (e) { fail(e); }
  });
  await draw();
}
