import { sb, rpc, db, people } from "../core/api.js";
import { esc, ngn, pill, userLink, dt, modal, ask, toast, fail, table, label } from "../core/ui.js";

const CLOSED = /^(RESOLVED|REFUNDED|RELEASED|CLOSED)$/;
export default async function disputes(el, ctx) {
  const data = await db(sb.from("disputes").select("*, transactions(title,amount,collateral,state,payer_id,payee_id)").order("created_at", { ascending: false }).limit(200));
  const who = await people(data.flatMap((d) => [d.transactions?.payer_id, d.transactions?.payee_id, d.opened_by]));
  el.innerHTML = `<div class="top"><div><h2>Disputes</h2><p>Open cases are listed first. Opening a case shows the evidence and the deal timeline.</p></div></div>` +
    table(["Opened", "Deal", "Opened by", "Between", "Amount", "Status", ""], [...data].sort((a, b) => CLOSED.test(a.status) - CLOSED.test(b.status)).map((d) => ({ cells: [dt(d.created_at), `<b>${esc(d.transactions?.title)}</b>`, userLink(d.opened_by, who(d.opened_by).name), `${userLink(d.transactions?.payer_id, who(d.transactions?.payer_id).name)} & ${userLink(d.transactions?.payee_id, who(d.transactions?.payee_id).name)}`, ngn(d.transactions?.amount), pill(label(d.status), CLOSED.test(d.status) ? "" : "a"), `<button class="btn sm sec" data-d="${d.id}">Open</button>`] })), { empty: "No disputes." });
  el.querySelectorAll("[data-d]").forEach((b) => b.addEventListener("click", () => detail(data.find((x) => x.id === b.dataset.d), ctx, () => disputes(el, ctx))));
}

async function detail(d, ctx, reload) {
  const [ev, ts, cr] = await Promise.all([
    db(sb.from("dispute_evidence").select("*").eq("dispute_id", d.id)).catch(() => []),
    db(sb.from("transaction_events").select("*").eq("transaction_id", d.transaction_id).order("created_at")).catch(() => []),
    db(sb.from("condition_reports").select("*").eq("transaction_id", d.transaction_id)).catch(() => [])]);
  const open = !CLOSED.test(d.status);
  const m = modal(`<h2>Dispute · ${esc(d.transactions?.title)}</h2><p>${esc(d.reason)}</p>
    <div class="cards"><div class="card"><div class="l">Amount</div><div class="v">${ngn(d.transactions?.amount)}</div></div><div class="card"><div class="l">Deposit</div><div class="v">${ngn(d.transactions?.collateral)}</div></div></div>
    <h3>Condition reports (${cr.length})</h3>${cr.map((c) => `<div class="msg">${esc(c.phase)} · ${esc(c.condition)}: ${esc(c.notes)}</div>`).join("") || '<p class="mut">None.</p>'}
    <h3>Evidence (${ev.length})</h3>${ev.map((e) => `<div class="msg">${esc(e.note)} ${(e.paths || []).length ? `<span class="mut">(${e.paths.length} file${e.paths.length > 1 ? "s" : ""})</span>` : ""}</div>`).join("") || '<p class="mut">None.</p>'}
    <h3>Timeline</h3><div class="chat">${ts.map((t) => `<div class="msg">${dt(t.created_at)} · ${esc(label(t.from_state || ""))} → <b>${esc(label(t.to_state || t.state || ""))}</b> ${esc(t.note || "")}</div>`).join("")}</div>
    ${open && ctx.can("disputes.resolve") ? `<label for="o">Outcome</label><select id="o"><option value="under_review">Mark under review</option><option value="waiting_user">Waiting for a member</option><option value="waiting_other">Waiting for the other party</option><option value="escalate">Escalate</option><option value="release">Release funds to the lender</option><option value="refund">Refund the borrower</option><option value="close">Close (no money moves)</option></select>
      <label for="n">Resolution note (sent to both people and saved in the audit log)</label><textarea id="n" maxlength="1000"></textarea><p class="err" role="alert"></p>
      <div class="row end"><button class="btn sec" data-x>Close</button><button class="btn" id="ok">Apply</button></div>` : `<div class="row end"><button class="btn sec" data-x>Close</button></div>`}`, { wide: true });
  m.querySelector("#ok")?.addEventListener("click", async () => {
    const o = m.querySelector("#o").value, note = m.querySelector("#n").value.trim();
    if (!note) return (m.querySelector(".err").textContent = "Add a resolution note.");
    if (["release", "refund"].includes(o)) { const v = await ask({ title: `Confirm: ${o} the funds`, intro: "This moves money and can't be undone.", confirm: "Yes, continue", danger: true, fields: [] }); if (!v) return; }
    try { await rpc("resolve_dispute", { p_dispute: d.id, p_outcome: o, p_note: note }); m.close(); toast("Dispute updated."); reload(); } catch (e) { fail(e); }
  });
}
