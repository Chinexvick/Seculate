import { rpc } from "../core/api.js";
import { $, esc, num, ask, toast, fail, table } from "../core/ui.js";

export default async function categories(el) {
  const rows = await rpc("admin_list_categories");
  const parents = rows.filter((r) => !r.parent_id);
  el.innerHTML = `<div class="top"><div><h2>Categories</h2><p>What members can post under. Switch a category off to hide it from new posts. Existing posts stay.</p></div><button class="btn" id="add">Add category</button></div>` +
    ["item", "service", "task"].map((k) => `<h3>${{ item: "Items", service: "Services", task: "Errands" }[k]}</h3>` + table(["Category", "Parent", "Live listings", "Open errands", "Shown", ""], rows.filter((r) => r.kind === k).map((r) => ({ cells: [`<b>${esc(r.label)}</b>`, esc(r.parent_label || "—"), num(r.live_listings), num(r.open_tasks), r.is_active ? '<span class="pill">On</span>' : '<span class="pill n">Off</span>', `<button class="btn sm sec" data-t="${r.id}" data-on="${r.is_active}">${r.is_active ? "Switch off" : "Switch on"}</button> <button class="btn sm ghost" data-rn="${r.id}">Rename</button>`] })))).join("");
  el.querySelectorAll("[data-t]").forEach((b) => b.addEventListener("click", async () => { try { await rpc("admin_set_category", { p_id: b.dataset.t, p_active: b.dataset.on !== "true", p_label: null }); categories(el); } catch (e) { fail(e); } }));
  el.querySelectorAll("[data-rn]").forEach((b) => b.addEventListener("click", async () => {
    const v = await ask({ title: "Rename category", confirm: "Save", fields: [{ label: "New name", type: "text", required: true, max: 60 }] }); if (!v) return;
    try { await rpc("admin_set_category", { p_id: b.dataset.rn, p_active: null, p_label: v[0] }); categories(el); } catch (e) { fail(e); }
  }));
  $("#add", el).addEventListener("click", async () => {
    const v = await ask({ title: "Add a category", confirm: "Add", fields: [{ label: "Type", type: "select", options: [["item", "Items"], ["service", "Services"], ["task", "Errands"]] }, { label: "Under (optional)", type: "select", options: [["", "Top level"], ...parents.map((p) => [p.id, `${p.label} (${p.kind})`])] }, { label: "Name", type: "text", required: true, max: 60 }] }); if (!v) return;
    try { await rpc("admin_add_category", { p_kind: v[0], p_parent: v[1] || null, p_label: v[2] }); toast("Category added."); categories(el); } catch (e) { fail(e); }
  });
}
