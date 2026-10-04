import { rpc } from "../core/api.js";
import { $, esc, ngn, num, pill, userLink, dd } from "../core/ui.js";
import { listPage } from "../core/list.js";

export default function subscriptions(el) {
  el.innerHTML = `<div class="top"><div><h2>Plans & subscribers</h2><p>What each plan earns and who is on it.</p></div></div><div id="plans" class="cards plans"></div><h3>Subscribers</h3><div id="subs"></div>`;
  listPage($("#subs", el), {
    search: "Search subscriber name or email", exportName: "subscribers",
    filters: [{ key: "status", label: "Status", value: "active", options: [["", "Any status"], ["active", "Active"], ["grace", "Grace period"], ["past_due", "Past due"], ["pending", "Pending"], ["cancelled", "Cancelled"], ["expired", "Expired"]] }],
    fetch: async ({ q, f, offset, limit }) => {
      const r = await rpc("admin_list_subscriptions", { p_status: f.status, p_q: q, p_limit: limit, p_offset: offset });
      $("#plans", el).innerHTML = (r.plans || []).map((p) => `<div class="card"><div class="l">${esc(p.emoji || "")} ${esc(p.name)} · ${p.price ? ngn(p.price) : "Free"}</div><div class="v">${num(p.subscribers)}</div><div class="mut small">active subscribers · ${ngn(p.revenue)} earned</div><div class="mut small">${num(p.item_limit)} posts/month · ${num(p.days)}-day listings</div></div>`).join("");
      return r;
    },
    columns: [
      { h: "Subscriber", cell: (s) => `${userLink(s.user_id, s.user_name)}<div class="mut small">${esc(s.user_email)}</div>`, csv: (s) => `${s.user_name} <${s.user_email}>` },
      { h: "Plan", cell: (s) => pill(s.plan_id, "n"), csv: (s) => s.plan_id },
      { h: "Status", cell: (s) => pill(s.status), csv: (s) => s.status },
      { h: "From", cell: (s) => dd(s.current_period_start), csv: (s) => s.current_period_start },
      { h: "Until", cell: (s) => dd(s.current_period_end), csv: (s) => s.current_period_end },
      { h: "How", cell: (s) => (s.payment_ref === "staff_grant" ? "Given by staff" : "Paid"), csv: (s) => s.payment_ref },
    ],
  });
}
