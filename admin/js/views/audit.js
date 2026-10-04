import { sb, db, people } from "../core/api.js";
import { $, esc, dt, table, userLink, label } from "../core/ui.js";
import { exportTable } from "../core/export.js";
import { debounce } from "../core/ui.js";

export default async function audit(el) {
  const data = await db(sb.from("audit_logs").select("*").order("created_at", { ascending: false }).limit(500));
  const who = await people(data.map((a) => a.actor_id));
  const actions = [...new Set(data.map((a) => a.action))].sort();
  el.innerHTML = `<div class="top"><div><h2>Audit log</h2><p>Newest 500 entries. Entries can't be edited or deleted.</p></div></div>
    <div class="toolbar"><div class="sbox"><input id="aq" type="search" autocomplete="off" placeholder="Filter by person, action or reason"></div><select id="af"><option value="">All actions</option>${actions.map((a) => `<option>${esc(a)}</option>`).join("")}</select><button class="btn ghost sm" id="acsv">Export CSV</button></div><div id="alist"></div>`;
  let shown = data;
  const draw = () => {
    const q = $("#aq", el).value.trim().toLowerCase(), f = $("#af", el).value;
    shown = data.filter((a) => (!f || a.action === f) && (!q || `${who(a.actor_id).name} ${who(a.actor_id).email} ${a.action} ${a.reason || ""} ${a.target_type} ${a.target_id}`.toLowerCase().includes(q)));
    $("#alist", el).innerHTML = table(["When", "Who", "Role", "Action", "Target", "Reason"], shown.map((a) => ({ cells: [dt(a.created_at), a.actor_id ? `${userLink(a.actor_id, who(a.actor_id).name)}<div class="mut small">${esc(who(a.actor_id).email)}</div>` : "System", esc(label(a.actor_role || "system")), `<code>${esc(a.action)}</code>`, `${esc(a.target_type)} ${a.target_type === "user" ? userLink(a.target_id, "open") : `<span class="mut">${esc(String(a.target_id || "").slice(0, 8))}</span>`}`, esc(a.reason)] })), { empty: "No matching entries." });
  };
  $("#aq", el).addEventListener("input", debounce(draw, 200)); $("#af", el).addEventListener("change", draw);
  $("#acsv", el).addEventListener("click", () => exportTable("audit-log", ["When", "Who", "Email", "Role", "Action", "Target type", "Target", "Reason"], shown.map((a) => [a.created_at, who(a.actor_id).name, who(a.actor_id).email, a.actor_role, a.action, a.target_type, a.target_id, a.reason])));
  draw();
}
