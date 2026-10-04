import { rpc } from "../core/api.js";
import { $, esc, ask, toast, fail } from "../core/ui.js";

export default function broadcast(el) {
  el.innerHTML = `<div class="top"><div><h2>Announcements</h2><p>Send an in-app notification to a group of members. Limited to 3 a day and every send is recorded.</p></div></div>
  <div class="panel narrow"><label for="bt">Title</label><input id="bt" maxlength="80" autocomplete="off" placeholder="e.g. New feature: chat photos">
    <label for="bb">Message</label><textarea id="bb" maxlength="500" placeholder="Keep it short and clear."></textarea><div class="mut small"><span id="cnt">0</span>/500</div>
    <label for="ba">Who gets it</label><select id="ba"><option value="all">Every active member</option><option value="verified">Verified members</option><option value="plan:active">Active plan</option><option value="plan:hustler">Hustler plan</option><option value="plan:top_lender">Top Lender plan</option></select>
    <p class="err" role="alert"></p><div class="row end"><button class="btn" id="send">Send announcement</button></div></div>`;
  $("#bb", el).addEventListener("input", (e) => ($("#cnt", el).textContent = e.target.value.length));
  $("#send", el).addEventListener("click", async () => {
    const title = $("#bt", el).value.trim(), body = $("#bb", el).value.trim(), aud = $("#ba", el).value;
    if (title.length < 2 || body.length < 2) return ($(".err", el).textContent = "Add a title and a message.");
    $(".err", el).textContent = "";
    const ok = await ask({ title: "Send to everyone in this group?", intro: `"${title}" will go to: ${$("#ba", el).selectedOptions[0].text}. This can't be unsent.`, confirm: "Send now", fields: [] }); if (!ok) return;
    try { const n = await rpc("admin_broadcast", { p_title: title, p_body: body, p_audience: aud }); toast(`Sent to ${n} member${n === 1 ? "" : "s"}.`); $("#bt", el).value = ""; $("#bb", el).value = ""; $("#cnt", el).textContent = "0"; } catch (e) { fail(e); }
  });
  void esc;
}
