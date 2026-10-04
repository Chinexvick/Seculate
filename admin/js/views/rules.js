import { sb, db } from "../core/api.js";
import { $, esc, ask, toast, fail, table } from "../core/ui.js";

export default async function rules(el) {
  const [rs, set] = await Promise.all([db(sb.from("prohibited_rules").select("*").order("severity", { ascending: false })), db(sb.from("app_settings").select("*").order("key"))]);
  el.innerHTML = `<div class="top"><div><h2>Rules & settings</h2><p>Words and patterns the safety filter reacts to, and the app's switches.</p></div><button class="btn" id="newrule">Add rule</button></div><h3>Prohibited content rules</h3>` +
    table(["Label", "Pattern", "Severity", "Action", "Applies to", "Active", ""], (rs || []).map((r) => ({ cells: [esc(r.label), `<code>${esc(r.pattern)}</code>`, r.severity, esc(r.action), esc(Array.isArray(r.applies_to) ? r.applies_to.join(", ") : r.applies_to), r.is_active ? '<span class="pill">Yes</span>' : '<span class="pill n">No</span>', `<button class="btn sm sec" data-rt="${r.id}">${r.is_active ? "Disable" : "Enable"}</button>`] }))) +
    `<h3>App settings</h3>` + table(["Setting", "Value", "What it does", ""], (set || []).map((s) => ({ cells: [`<code>${esc(s.key)}</code>`, `<code>${esc(JSON.stringify(s.value))}</code>`, esc(s.description), `<button class="btn sm sec" data-sk="${esc(s.key)}">Edit</button>`] })));
  el.querySelectorAll("[data-rt]").forEach((b) => b.addEventListener("click", async () => { const r = rs.find((x) => x.id === b.dataset.rt); try { await db(sb.from("prohibited_rules").update({ is_active: !r.is_active }).eq("id", r.id)); rules(el); } catch (e) { fail(e); } }));
  el.querySelectorAll("[data-sk]").forEach((b) => b.addEventListener("click", async () => {
    const s = set.find((x) => x.key === b.dataset.sk);
    const v = await ask({ title: `Edit ${s.key}`, intro: `Current value: ${JSON.stringify(s.value)}`, confirm: "Save", fields: [{ label: "New value (true, false, a number, or \"text\")", type: "text", required: true }] }); if (!v) return;
    let val; try { val = JSON.parse(v[0]); } catch { return toast('Value must be valid, e.g. true, 5 or "text".', "bad"); }
    try { await db(sb.from("app_settings").update({ value: val, updated_at: new Date().toISOString() }).eq("key", s.key)); toast("Saved."); rules(el); } catch (e) { fail(e); }
  }));
  $("#newrule", el).addEventListener("click", async () => {
    const v = await ask({ title: "New prohibited rule", confirm: "Add rule", fields: [{ label: "Label", type: "text", required: true }, { label: "Pattern (case-insensitive regular expression)", type: "text", required: true }, { label: "Severity (1 to 100)", type: "number", value: 50 }, { label: "Action", type: "select", options: ["flag", "block"] }] }); if (!v) return;
    try { new RegExp(v[1]); } catch { return toast("That pattern isn't valid.", "bad"); }
    try { await db(sb.from("prohibited_rules").insert({ label: v[0], pattern: v[1], severity: Math.min(100, Math.max(1, Number(v[2]) || 50)), action: v[3], applies_to: ["chat", "listing"], is_active: true })); toast("Rule added."); rules(el); } catch (e) { fail(e); }
  });
}
