import { rpc } from "../core/api.js";
import { $, esc, ask, toast, fail, table, dd, pill } from "../core/ui.js";

export default function verifications(el) {
  async function load() {
    let rows, ev = [];
    try { rows = await rpc("admin_pending_verifications"); } catch (e) { el.innerHTML = `<div class="panel err">${esc(e.message)}</div>`; return; }
    try { ev = await rpc("admin_prembly_events"); } catch { /* needs audit.read */ }
    el.innerHTML = `<div class="top"><div><h2>Identity checks</h2><p>ID and face scans waiting for a person to review.</p></div></div>
    ${table(["Submitted", "Member", "Name on ID", "Status", ""], rows.map((v) => ({ cells: [dd(v.created_at), esc(v.email || ""), esc(v.verified_name || ""), pill(v.status), `<button class="btn sm" data-a="${esc(v.id)}">Approve</button> <button class="btn ghost sm" data-r="${esc(v.id)}">Reject</button>`] })), { empty: "Nothing waiting for review." })}
    <h3 style="margin-top:20px">Recent provider events</h3>
    ${table(["When", "Event", "Status"], ev.map((e) => ({ cells: [dd(e.created_at), esc(e.event || ""), esc(e.status || "")] })), { empty: "No events yet." })}`;
    el.querySelectorAll("[data-a]").forEach((b) => b.addEventListener("click", async () => {
      try { await rpc("admin_decide_verification", { p_id: b.dataset.a, p_approve: true, p_reason: null }); toast("Approved. The member was notified."); load(); } catch (e) { fail(e); }
    }));
    el.querySelectorAll("[data-r]").forEach((b) => b.addEventListener("click", async () => {
      const v = await ask({ title: "Reject this check", confirm: "Reject", fields: [{ label: "Reason shown to the member", required: true }] });
      if (!v) return;
      try { await rpc("admin_decide_verification", { p_id: b.dataset.r, p_approve: false, p_reason: v[0] }); toast("Rejected. The member was notified."); load(); } catch (e) { fail(e); }
    }));
  }
  load();
}
