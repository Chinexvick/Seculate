import { rpc, db, sb } from "../core/api.js";
import { esc, ngn, pill, userLink, dd, dt, modal, kv, label, num } from "../core/ui.js";
import { listPage } from "../core/list.js";

const STATES = ["requested", "accepted", "payment_pending", "escrow_held", "active", "return_pending", "confirmed", "release_pending", "released", "cancelled", "disputed", "refunded"];
export default function deals(el) {
  listPage(el, {
    title: "Deals", sub: "Every borrow, service and errand deal between members.", search: "Search deal title, reference or member name", exportName: "deals",
    filters: [{ key: "state", label: "Stage", options: [["", "Any stage"], ...STATES.map((s) => [s, label(s)])] }],
    fetch: ({ q, f, offset, limit }) => rpc("admin_list_transactions", { p_state: f.state, p_q: q, p_limit: limit, p_offset: offset }),
    columns: [
      { h: "Deal", cell: (t) => `<b>${esc(t.title)}</b><div class="mut small">${esc(label(t.kind))} · <code>${esc(t.tx_ref || "")}</code></div>`, csv: (t) => t.title },
      { h: "Borrower / buyer", cell: (t) => `${userLink(t.payer_id, t.payer_name)}<div class="mut small">${esc(t.payer_email)}</div>`, csv: (t) => `${t.payer_name} <${t.payer_email}>` },
      { h: "Lender / seller", cell: (t) => `${userLink(t.payee_id, t.payee_name)}<div class="mut small">${esc(t.payee_email)}</div>`, csv: (t) => `${t.payee_name} <${t.payee_email}>` },
      { h: "Amount", cell: (t) => ngn(t.amount), csv: (t) => t.amount },
      { h: "Deposit", cell: (t) => ngn(t.collateral), csv: (t) => t.collateral },
      { h: "Stage", cell: (t) => pill(t.state), csv: (t) => t.state },
      { h: "Escrow", cell: (t) => (t.escrow_status ? pill(t.escrow_status) : "—"), csv: (t) => t.escrow_status },
      { h: "Started", cell: (t) => dd(t.created_at), csv: (t) => t.created_at },
    ],
    onRow: async (t) => {
      const ev = await db(sb.from("transaction_events").select("*").eq("transaction_id", t.id).order("created_at")).catch(() => []);
      modal(`<h2>${esc(t.title)}</h2>${kv([["Stage", pill(t.state)], ["Escrow", t.escrow_status ? pill(t.escrow_status) : ""], ["Amount", ngn(t.amount)], ["Deposit", ngn(t.collateral)], ["Seculate fee", ngn(t.platform_fee)], ["Days", num(t.rental_days)], ["Start", dd(t.start_date)], ["Due", dd(t.due_date)], ["Borrower / buyer", `${userLink(t.payer_id, t.payer_name)} <span class="mut">${esc(t.payer_email)}</span>`], ["Lender / seller", `${userLink(t.payee_id, t.payee_name)} <span class="mut">${esc(t.payee_email)}</span>`], ["Reference", `<code>${esc(t.tx_ref)}</code>`], ["Started", dt(t.created_at)]])}
        <h3>Timeline</h3><div class="chat">${(ev || []).map((x) => `<div class="msg">${dt(x.created_at)} · ${esc(label(x.from_state || ""))} → <b>${esc(label(x.to_state || x.state || ""))}</b> ${esc(x.note || "")}</div>`).join("") || '<p class="mut pad">No events.</p>'}</div>
        <div class="row end"><button class="btn sec" data-x>Close</button></div>`, { wide: true });
    },
  });
}
