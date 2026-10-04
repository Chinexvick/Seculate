import { rpc } from "../core/api.js";
import { esc, ngn, num, table, pill, dd } from "../core/ui.js";

export default async function wallet(el) {
  const d = await rpc("admin_wallet_overview");
  el.innerHTML = `<div class="top"><div><h2>Wallet</h2><p>Money members hold in their wallets, top-ups and bank withdrawals.</p></div></div>
  <div class="cards">
    <div class="card"><div class="l">Held in wallets</div><div class="v">${ngn(d.held)}</div></div>
    <div class="card"><div class="l">Top-ups, 30 days</div><div class="v">${ngn(d.topups_30d)}</div></div>
    <div class="card"><div class="l">Withdrawn, 30 days</div><div class="v">${ngn(d.withdrawn_30d)}</div></div>
    <div class="card"><div class="l">Withdrawals in progress</div><div class="v">${num(d.withdrawals_pending)}</div></div></div>
  <h3>Withdrawals</h3>
  ${table(["When", "Member", "Amount", "Fee", "Bank", "Status"], (d.withdrawals || []).map((w) => ({ cells: [dd(w.created_at), esc(w.email || ""), ngn(w.amount), ngn(w.fee), `${esc(w.bank_name || "")}<div class="mut small">${esc(w.account_name || "")}</div>`, pill(w.status) + (w.failure_reason ? `<div class="mut small">${esc(w.failure_reason)}</div>` : "")] })), { empty: "No withdrawals yet." })}
  <h3 style="margin-top:20px">Recent wallet activity</h3>
  ${table(["When", "Member", "Type", "Amount", "Balance after", "Note"], (d.ledger || []).map((l) => ({ cells: [dd(l.created_at), esc(l.email || ""), esc(l.entry_type), ngn(l.delta), ngn(l.balance_after), esc(l.note || "")] })), { empty: "No wallet activity yet." })}`;
}
