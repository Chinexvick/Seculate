import { sb, rpc, db } from "../core/api.js";
import { $, esc, dt, pill, table, toast, fail, UUID, short } from "../core/ui.js";

export default async function compliance(el, ctx) {
  const ex = ctx.can("exports.create") || ctx.can("audit.read") ? await db(sb.from("compliance_exports").select("*").order("created_at", { ascending: false }).limit(100)) : [];
  el.innerHTML = `<div class="top"><div><h2>Compliance & retention</h2><p>Lawful data requests and retained account snapshots. Everything here is recorded.</p></div></div>
  ${ctx.can("exports.create") ? `<div class="panel narrow"><h3>Request a legal data export</h3><p class="mut">For lawful requests only. A case reference and reason are required. Exports expire after 7 days.</p>
    <label for="eu">Member ID</label><input id="eu" autocomplete="off" placeholder="Paste the member ID from their profile"><label for="er">Reference (court order or case number)</label><input id="er" autocomplete="off"><label for="ere">Reason</label><textarea id="ere" maxlength="500"></textarea><div class="row end"><button class="btn" id="eg">Create request</button></div></div>` : ""}
  ${ctx.can("users.read_sensitive") ? `<div class="panel narrow"><h3>View a retained (deleted) account snapshot</h3><label for="ru">Member ID</label><input id="ru" autocomplete="off"><label for="rr">Reason</label><input id="rr" autocomplete="off"><div class="row end"><button class="btn sec" id="rv">View snapshot</button></div><pre id="rs" hidden></pre></div>` : ""}
  <h3>Export requests</h3>` + table(["Created", "Member", "Reference", "Status", "Expires"], (ex || []).map((e) => ({ cells: [dt(e.created_at), `<code>${esc(short(e.target_user))}</code>`, esc(e.reference), pill(e.status), dt(e.expires_at)] })), { empty: "No export requests." });
  $("#eg", el)?.addEventListener("click", async () => {
    const u = $("#eu", el).value.trim(); if (!UUID.test(u)) return toast("Paste a valid member ID.", "bad");
    try { await rpc("request_compliance_export", { p_user: u, p_reference: $("#er", el).value.trim(), p_reason: $("#ere", el).value.trim() }); toast("Export requested."); compliance(el, ctx); } catch (e) { fail(e); }
  });
  $("#rv", el)?.addEventListener("click", async () => {
    const u = $("#ru", el).value.trim(); if (!UUID.test(u)) return toast("Paste a valid member ID.", "bad");
    try { const s = await rpc("staff_view_retained", { p_user: u, p_reason: $("#rr", el).value.trim() }); const p = $("#rs", el); p.hidden = false; p.textContent = JSON.stringify(s, null, 2); } catch (e) { fail(e); }
  });
}
