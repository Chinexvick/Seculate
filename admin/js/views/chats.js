import { sb, rpc, db, people } from "../core/api.js";
import { $, esc, dt, ask, modal, toast, fail, table, userLink, short } from "../core/ui.js";

export default async function chats(el, ctx) {
  const flags = await db(sb.from("message_flags").select("*").eq("status", "open").order("created_at", { ascending: false }).limit(100));
  const who = await people((flags || []).map((f) => f.user_id));
  el.innerHTML = `<div class="top"><div><h2>Chat flags</h2><p>Messages the safety filter caught. Reading the full chat needs a reason and is recorded.</p></div></div>` +
    table(["When", "Member", "Score", "Matched", "Excerpt", ""], (flags || []).map((f) => ({ cells: [dt(f.created_at), `${userLink(f.user_id, who(f.user_id).name)}<div class="mut small">${esc(who(f.user_id).email)}</div>`, f.score, esc(Array.isArray(f.hits) ? f.hits.join(", ") : JSON.stringify(f.hits)), esc(f.excerpt), 
      `${ctx.can("chats.review") ? `<button class="btn sm sec" data-c="${f.conversation_id}">Read chat</button> <button class="btn sm" data-fd="${f.id}">Dismiss</button>` : ""}`] })), { empty: "No flagged messages. Nice and quiet." });
  el.querySelectorAll("[data-c]").forEach((b) => b.addEventListener("click", async () => {
    const v = await ask({ title: "Read conversation", intro: "The reason is saved in the audit log with your name.", confirm: "Read", fields: [{ label: "Reason", required: true, max: 300 }] }); if (!v) return;
    try {
      const msgs = await rpc("staff_read_conversation", { p_conv: b.dataset.c, p_reason: v[0] }); const w = await people(msgs.map((m) => m.sender_id));
      modal(`<h2>Conversation</h2><div class="chat">${msgs.map((m) => `<div class="msg ${m.flagged ? "flag" : ""}"><b>${esc(w(m.sender_id).name)}</b> <span class="mut small">${dt(m.created_at)}</span><br>${esc(m.body || (m.attachment_path ? "[attachment]" : ""))}</div>`).join("") || '<p class="mut pad">No messages.</p>'}</div><div class="row end"><button class="btn sec" data-x>Close</button></div>`, { wide: true });
    } catch (e) { fail(e); }
  }));
  el.querySelectorAll("[data-fd]").forEach((b) => b.addEventListener("click", async () => {
    try { await db(sb.from("message_flags").update({ status: "dismissed", reviewed_at: new Date().toISOString() }).eq("id", b.dataset.fd)); toast("Dismissed."); chats(el, ctx); } catch (e) { fail(e); }
  }));
  void $; void short;
}
