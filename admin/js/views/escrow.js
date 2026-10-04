import { rpc, sb } from "../core/api.js";
import { $, esc, ngn, pill, userLink, dt, dd, ask, toast, fail, table, label } from "../core/ui.js";
import { listPage } from "../core/list.js";

export default async function escrow(el, ctx) {
  el.innerHTML = `<div class="top"><div><h2>Escrow & payments</h2><p>Funds held for deals, release approvals and every payment taken.</p></div></div><div id="rel"></div><h3>Payments</h3><div id="pay"></div>`;
  async function queue() {
    const r = await rpc("admin_list_transactions", { p_state: "release_pending", p_q: "", p_limit: 100, p_offset: 0 });
    $("#rel", el).innerHTML = `<h3>Waiting for release approval (${r.total})</h3>` + table(["Deal", "Borrower / buyer", "Lender / seller", "Amount", "Deposit", "Since", ""], r.rows.map((t) => ({ cells: [`<b>${esc(t.title)}</b>`, userLink(t.payer_id, t.payer_name), userLink(t.payee_id, t.payee_name), ngn(t.amount), ngn(t.collateral), dt(t.state_changed_at),
      ctx.can("escrow.release") ? `<button class="btn sm" data-a="${t.id}">Approve</button> <button class="btn sm sec" data-s="${t.id}">Settle with provider</button>` : ""] })), { empty: "Nothing is waiting for release." });
    el.querySelectorAll("[data-a]").forEach((b) => b.addEventListener("click", async () => {
      const v = await ask({ title: "Approve release", intro: "Approving lets the funds be paid out to the lender. The note is saved in the audit log.", confirm: "Approve", fields: [{ label: "Note", required: true }] }); if (!v) return;
      try { await rpc("approve_release", { p_tx: b.dataset.a, p_note: v[0] }); toast("Release approved. Now settle with the provider."); queue(); } catch (e) { fail(e); }
    }));
    el.querySelectorAll("[data-s]").forEach((b) => b.addEventListener("click", async () => {
      const v = await ask({ title: "Settle with escrow provider", intro: "This moves real money.", confirm: "Settle", danger: true, fields: [{ label: "Type SETTLE to continue", type: "text", required: true }] });
      if (!v || v[0] !== "SETTLE") return;
      const { data, error } = await sb.functions.invoke("escrow-settle", { body: { transaction_id: b.dataset.s } });
      if (error) return fail(new Error((await error.context?.json?.().catch(() => null))?.error || error.message));
      toast(data?.message || "Settlement requested."); queue();
    }));
  }
  const tasks = [queue()];
  if (ctx.can("payments.read")) listPage($("#pay", el), {
    search: "Search reference, member name or email", exportName: "payments",
    filters: [
      { key: "status", label: "Status", options: [["", "Any status"], ["successful", "Successful"], ["pending", "Pending"], ["failed", "Failed"], ["abandoned", "Abandoned"], ["refunded", "Refunded"]] },
      { key: "purpose", label: "For", options: [["", "Any purpose"], ["subscription", "Plan"], ["escrow", "Escrow"]] },
    ],
    fetch: ({ q, f, offset, limit }) => rpc("admin_list_payments", { p_status: f.status, p_purpose: f.purpose, p_q: q, p_limit: limit, p_offset: offset }),
    columns: [
      { h: "When", cell: (p) => dt(p.created_at), csv: (p) => p.created_at },
      { h: "Member", cell: (p) => `${userLink(p.user_id, p.user_name)}<div class="mut small">${esc(p.user_email)}</div>`, csv: (p) => `${p.user_name} <${p.user_email}>` },
      { h: "For", cell: (p) => esc(label(p.purpose)) + (p.plan_id ? ` <span class="mut">· ${esc(label(p.plan_id))}</span>` : ""), csv: (p) => p.purpose },
      { h: "Amount", cell: (p) => ngn(p.amount), csv: (p) => p.amount },
      { h: "Status", cell: (p) => pill(p.status), csv: (p) => p.status },
      { h: "Reference", cell: (p) => `<code>${esc(p.tx_ref)}</code>`, csv: (p) => p.tx_ref },
    ],
  });
  await Promise.all(tasks).catch((e) => { $("#rel", el).innerHTML = `<div class="panel err">${esc(e.message)}</div>`; });
  void dd;
}
