import { rpc } from "../core/api.js";
import { $, esc, ngn, num, pill, userLink, dd, ask, toast, fail } from "../core/ui.js";
import { listPage } from "../core/list.js";

export default function subscriptions(el) {
  let plans = [];
  const editPlan = async (p) => {
    const v = await ask({ title: p ? "Edit plan" : "Add plan", confirm: "Save", fields: [
      { label: "Name", type: "text", value: p?.name ?? "", required: true }, { label: "Emoji", type: "text", value: p?.emoji ?? "" },
      { label: "Price per month (₦, 0 = free)", type: "number", value: p?.price ?? 0, required: true },
      { label: "Item posts per month (blank = unlimited)", type: "number", value: p?.item_limit ?? "" },
      { label: "Listing duration (days)", type: "number", value: p?.days ?? 30, required: true },
      { label: "Perks (one per line)", value: (p?.features || []).join("\n") }] });
    if (!v) return;
    try {
      await rpc("admin_save_plan", { p_id: p?.id ?? null, p_name: v[0], p_emoji: v[1], p_price: +v[2], p_limit: v[3] === "" ? null : +v[3], p_days: +v[4], p_features: v[5].split("\n").map((x) => x.trim()).filter(Boolean), p_sort: 0, p_active: true });
      toast("Saved."); location.reload();
    } catch (e) { fail(e); }
  };
  const removePlan = async (id) => {
    const v = await ask({ title: "Remove this plan?", confirm: "Remove", fields: [] });
    if (!v) return;
    try { const n = await rpc("admin_delete_plan", { p_id: id }); toast(`Removed. ${n} subscriber(s) moved to the free plan.`); location.reload(); } catch (e) { fail(e); }
  };
  el.innerHTML = `<div class="top"><div><h2>Plans & subscribers</h2><p>What each plan earns and who is on it.</p></div><div class="row"><button class="btn" id="addplan">Add plan</button></div></div><div id="plans" class="cards plans"></div><h3>Subscribers</h3><div id="subs"></div>`;
  $("#addplan", el).addEventListener("click", () => editPlan(null));
  listPage($("#subs", el), {
    search: "Search subscriber name or email", exportName: "subscribers",
    filters: [{ key: "status", label: "Status", value: "active", options: [["", "Any status"], ["active", "Active"], ["grace", "Grace period"], ["past_due", "Past due"], ["pending", "Pending"], ["cancelled", "Cancelled"], ["expired", "Expired"]] }],
    fetch: async ({ q, f, offset, limit }) => {
      const r = await rpc("admin_list_subscriptions", { p_status: f.status, p_q: q, p_limit: limit, p_offset: offset });
      $("#plans", el).innerHTML = (r.plans || []).map((p) => `<div class="card"><div class="l">${esc(p.emoji || "")} ${esc(p.name)} · ${p.price ? ngn(p.price) : "Free"}</div><div class="v">${num(p.subscribers)}</div><div class="mut small">active subscribers · ${ngn(p.revenue)} earned</div><div class="mut small">${num(p.item_limit)} posts/month · ${num(p.days)}-day listings</div><div class="row" style="margin-top:8px"><button class="btn ghost sm" data-ep="${esc(p.id)}">Edit</button><button class="btn ghost sm" data-dp="${esc(p.id)}">Remove</button></div></div>`).join("");
      plans = r.plans || [];
      $("#plans", el).querySelectorAll("[data-ep]").forEach((b) => b.addEventListener("click", () => editPlan(plans.find((x) => String(x.id) === b.dataset.ep))));
      $("#plans", el).querySelectorAll("[data-dp]").forEach((b) => b.addEventListener("click", () => removePlan(b.dataset.dp)));
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
