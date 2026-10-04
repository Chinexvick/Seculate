import { rpc } from "../core/api.js";
import { $, esc, ngn, num } from "../core/ui.js";
import { lineChart, sum } from "../core/charts.js";

export default async function overview(el, ctx) {
  const o = (await rpc("admin_overview")) || {};
  ctx.counts = o;
  const h = Number(new Intl.DateTimeFormat("en-GB", { hour: "numeric", hour12: false, timeZone: "Africa/Lagos" }).format(new Date()));
  const greet = h < 12 ? "Good morning" : h < 17 ? "Good afternoon" : "Good evening";
  const link = (label, v, href, tone = "") => `<a class="card ${Number(v) > 0 ? tone : ""}" href="${href}"><div class="l">${esc(label)}</div><div class="v">${num(v)}</div></a>`;
  const stat = (label, v) => `<div class="card"><div class="l">${esc(label)}</div><div class="v">${v}</div></div>`;
  const can = ctx.can("analytics.read");
  el.innerHTML = `<div class="top"><div><h2>${greet}</h2><p>Here's what needs you today.</p></div></div>
  <section class="hero"><div><small>Held in escrow right now</small><div class="big">${ngn(o.escrow_held)}</div><small>${num(o.transactions_active)} active deals · ${ngn(o.transaction_volume)} completed volume</small></div>
    <div class="side"><div><b>${num(o.users_total)}</b><span>Members</span></div><div><b>${num(o.users_new_today)}</b><span>Joined today</span></div><div><b>${ngn(o.revenue_30d)}</b><span>Plan revenue, 30 days</span></div><div><b>${num(o.users_verified)}</b><span>Verified</span></div></div></section>
  <h3>Needs attention</h3><div class="cards">
    ${link("Listings to review", o.listings_pending, "#/listings", "todo")}${link("Errands to review", o.tasks_pending, "#/tasks", "todo")}${link("Open disputes", o.disputes_open, "#/disputes", "alert")}
    ${link("Releases waiting", o.release_pending, "#/escrow", "alert")}${link("Flagged chats", o.flagged_chats, "#/chats", "alert")}${link("Open reports", o.reports_open, "#/reports", "todo")}
    ${link("Flagged reviews", o.reviews_flagged, "#/reviews", "todo")}${link("Open tickets", o.tickets_open, "#/tickets", "todo")}</div>
  ${can ? `<div class="top" style="margin-top:22px"><h3 style="margin:0">Trends</h3><div class="seg" id="rng"><button data-d="7">7 days</button><button data-d="30" class="on">30 days</button><button data-d="90">90 days</button></div></div><div class="grid3" id="trend"></div>` : ""}
  <h3>Marketplace</h3><div class="cards">
    ${stat("Live items", num(o.listings_live))}${stat("Live services", num(o.services_live))}${stat("Open errands", num(o.tasks_open))}${stat("Deals, all time", num(o.transactions_total))}
    ${stat("Active this week", num(o.users_active_7d))}${stat("New this week", num(o.users_new_7d))}${stat("Suspended or banned", num(o.users_suspended))}${stat("Average rating", o.avg_rating ?? "—")}
    ${stat("Payments ok", num(o.payments_ok))}${stat("Payments failed", num(o.payments_failed))}${stat("Plan revenue, all time", ngn(o.subscription_revenue))}</div>
  <h3>Active plans</h3><div class="panel row">${Object.entries(o.subs_by_plan || {}).map(([k, v]) => `<span class="pill n">${esc(k.replaceAll("_", " "))}</span> <b>${num(v)}</b>`).join("&nbsp;&nbsp;") || '<span class="mut">No paid plans yet.</span>'}</div>`;
  if (!can) return;
  const draw = async (days) => {
    const box = $("#trend", el); box.classList.add("busy");
    try {
      const a = await rpc("admin_analytics", { p_days: days });
      const s = a.series;
      const card = (t, pts, money, color) => `<div class="panel"><div class="chh"><h3>${t}</h3><b>${money ? ngn(sum(pts)) : num(sum(pts))}</b></div>${lineChart(pts, { money, color })}</div>`;
      box.innerHTML = card("New members", s.users, false, "#00A62B") + card("Deals started", s.transactions, false, "#2563EB") + card("Plan revenue", s.revenue, true, "#B26B00");
    } catch (e) { box.innerHTML = `<div class="panel err">${esc(e.message)}</div>`; }
    box.classList.remove("busy");
  };
  $$r(el, "#rng button").forEach((b) => b.addEventListener("click", () => { $$r(el, "#rng button").forEach((x) => x.classList.toggle("on", x === b)); draw(Number(b.dataset.d)); }));
  draw(30);
}
const $$r = (r, s) => [...r.querySelectorAll(s)];
