import { rpc } from "../core/api.js";
import { $, esc, table, dd } from "../core/ui.js";

export default function certificates(el) {
  el.innerHTML = `<div class="top"><div><h2>Agreement certificates</h2><p>Issued when a deal is paid. Search by certificate number.</p></div></div>
  <input id="cq" placeholder="Certificate number" aria-label="Certificate number"><div id="cl"></div>`;
  const load = async () => {
    const rows = await rpc("admin_list_certificates", { p_q: $("#cq", el).value.trim() });
    $("#cl", el).innerHTML = table(["Number", "Issued", "Version", "Item", "Deal"], rows.map((c) => ({ cells: [esc(c.certificate_number), dd(c.issued_at), esc(c.version), esc(c.snapshot?.item_name || c.snapshot?.item || ""), `<a href="#/deals/${esc(c.transaction_id)}">Open deal</a>`] })), { empty: "No certificates found." });
  };
  let t; $("#cq", el).addEventListener("input", () => { clearTimeout(t); t = setTimeout(load, 300); });
  load();
}
