import { rpc } from "../core/api.js";
import { $, esc, ngn, num, ask, toast, fail, table, pill } from "../core/ui.js";

export default function credits(el) {
  async function load() {
    let d;
    try { d = await rpc("admin_list_credit_bundles"); } catch (e) { el.innerHTML = `<div class="panel err">${esc(e.message)}</div>`; return; }
    const s = d.settings || {};
    el.innerHTML = `<div class="top"><div><h2>Credits</h2><p>Members spend credits to post an item request and to unlock one they want to bid on. Set what things cost and what is on sale.</p></div></div>
    <div class="panel narrow"><h3>What credits cost</h3>
      <label for="cs">Free credits for new members</label><input id="cs" type="number" min="0" value="${esc(s.signup_free ?? 0)}">
      <label for="cr">Credits to post a request</label><input id="cr" type="number" min="0" value="${esc(s.request_cost ?? 1)}">
      <label for="cu">Credits to unlock a request</label><input id="cu" type="number" min="0" value="${esc(s.unlock_cost ?? 1)}">
      <div class="row end"><button class="btn" id="save">Save costs</button></div></div>
    <div class="top"><div><h3>Bundles for sale</h3></div><div class="row"><button class="btn" id="add">Add bundle</button></div></div>
    ${table(["Credits", "Price", "Order", "Status", ""], (d.bundles || []).map((b) => ({ cells: [num(b.credits), ngn(b.price_ngn), num(b.sort_order), b.is_active ? pill("on sale", "") : pill("hidden", "n"), `<button class="btn ghost sm" data-e="${esc(b.id)}">Edit</button>`] })), { empty: "No bundles yet. Add one so members can buy credits." })}
    <div class="panel narrow" style="margin-top:20px"><h3>Give or take credits</h3>
      <label for="ge">Member email</label><input id="ge" type="email" autocomplete="off">
      <label for="gn">Credits (use a minus number to remove)</label><input id="gn" type="number" value="5">
      <label for="gr">Reason (recorded in the audit log)</label><input id="gr" maxlength="200">
      <div class="row end"><button class="btn" id="grant">Apply</button></div></div>`;
    $("#save", el).addEventListener("click", async () => {
      try { await rpc("admin_set_credit_settings", { p_signup: +$("#cs", el).value, p_unlock: +$("#cu", el).value, p_request: +$("#cr", el).value }); toast("Saved."); } catch (e) { fail(e); }
    });
    const edit = async (b) => {
      const v = await ask({ title: b ? "Edit bundle" : "Add bundle", confirm: "Save", fields: [
        { label: "Credits", type: "number", value: b?.credits ?? 5, required: true }, { label: "Price (₦)", type: "number", value: b?.price_ngn ?? 1000, required: true },
        { label: "Order (smaller shows first)", type: "number", value: b?.sort_order ?? 0 }, { label: "Status", type: "select", options: [["true", "On sale"], ["false", "Hidden"]] }] });
      if (!v) return;
      try { await rpc("admin_save_credit_bundle", { p_id: b?.id ?? null, p_credits: +v[0], p_price: +v[1], p_sort: +(v[2] || 0), p_active: v[3] === "true" }); toast("Saved."); load(); } catch (e) { fail(e); }
    };
    $("#add", el).addEventListener("click", () => edit(null));
    el.querySelectorAll("[data-e]").forEach((btn) => btn.addEventListener("click", () => edit((d.bundles || []).find((x) => x.id === btn.dataset.e))));
    $("#grant", el).addEventListener("click", async () => {
      try { const b = await rpc("admin_grant_credits", { p_email: $("#ge", el).value.trim(), p_credits: +$("#gn", el).value, p_reason: $("#gr", el).value.trim() }); toast(`Done. New balance: ${b}.`); $("#gr", el).value = ""; } catch (e) { fail(e); }
    });
  }
  load();
}
