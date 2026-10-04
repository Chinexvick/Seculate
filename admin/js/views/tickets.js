import { rpc } from "../core/api.js";
import { esc, pill, userLink, copyBtn, dt, ago, modal, toast, fail, avatar, UUID, label } from "../core/ui.js";
import { listPage } from "../core/list.js";

export default function tickets(el, ctx, arg) {
  listPage(el, {
    title: "Support tickets", sub: "Every ticket shows who the customer is. Click their name or email to open their full profile.", search: "Search customer name, email or subject", exportName: "tickets",
    filters: [
      { key: "status", label: "Status", value: "", options: [["", "Any status"], ["open", "Open"], ["pending", "Pending"], ["escalated", "Escalated"], ["closed", "Closed"]] },
    ],
    fetch: ({ q, f, offset, limit }) => rpc("admin_list_tickets", { p_status: f.status, p_q: q, p_limit: limit, p_offset: offset }),
    columns: [
      { h: "Customer", cell: (t) => `<div>${userLink(t.user_id, t.user_name || "Unnamed user")}</div><div class="mut small nowrap">${esc(t.user_email)}${copyBtn(t.user_email)}</div>`, csv: (t) => `${t.user_name || ""} <${t.user_email}>` },
      { h: "Subject", cell: (t) => `<b>${esc(t.subject)}</b><div class="mut small">${esc(label(t.category))} · ${t.messages} message${t.messages === 1 ? "" : "s"}</div>`, csv: (t) => t.subject },
      { h: "Priority", cell: (t) => pill(t.priority), csv: (t) => t.priority },
      { h: "Status", cell: (t) => pill(t.status), csv: (t) => t.status },
      { h: "Assigned", cell: (t) => esc(t.assignee || "—"), csv: (t) => t.assignee },
      { h: "Updated", cell: (t) => `<span class="mut">${esc(ago(t.updated_at))}</span>`, csv: (t) => t.updated_at },
    ],
    onRow: (t, reload) => open(t.id, ctx, reload),
  });
  if (UUID.test(arg || "")) open(arg, ctx, () => {});
}

async function open(id, ctx, reload) {
  let d; try { d = await rpc("admin_ticket_detail", { p_ticket: id }); } catch (e) { return fail(e); }
  const t = d.ticket, u = d.user || {};
  const closed = t.status === "closed";
  const m = modal(`<h2>${esc(t.subject)}</h2>
    <div class="cust"><div class="who2">${avatar(u.avatar_url, u.name, 44)}<div><b>${userLink(u.id, u.name || "Unnamed user")}</b>${pill(u.account_status)}<div class="mut small">${esc(u.email)}${copyBtn(u.email)}${u.phone ? ` · ${esc(u.phone)}${copyBtn(u.phone)}` : ""}</div><div class="mut small">Member since ${esc(dt(u.joined))} · ${esc(label(u.verification_status))}</div></div></div>
      <a class="btn sec sm" href="#/users/${esc(u.id)}" data-x>Open full profile</a></div>
    ${d.transaction ? `<p class="mut">About deal: <b>${esc(d.transaction.title)}</b> · ${esc(label(d.transaction.state))}</p>` : ""}
    <div class="chat">${(d.messages || []).map((x) => `<div class="msg ${x.is_staff ? (x.internal ? "internal" : "staff") : ""}"><b>${esc(x.is_staff ? (x.internal ? "Internal note" : x.sender || "Support") : u.name || "Customer")}</b> <span class="mut small">${dt(x.created_at)}</span><br>${esc(x.body)}</div>`).join("") || '<p class="mut pad">No messages yet.</p>'}</div>
    <div class="grid2c"><div><label for="ts">Status</label><select id="ts">${["open", "pending", "escalated", "closed"].map((s) => `<option ${s === t.status ? "selected" : ""}>${s}</option>`).join("")}</select></div>
    <div><label for="tp">Priority</label><select id="tp">${["low", "normal", "high", "urgent"].map((s) => `<option ${s === t.priority ? "selected" : ""}>${s}</option>`).join("")}</select></div></div>
    <label for="trep">Reply</label><textarea id="trep" maxlength="2000" placeholder="${closed ? "Reopen the ticket to reply." : "Write your reply"}"></textarea>
    <label class="chk"><input type="checkbox" id="tint"> Internal note (the customer won't see it)</label><p class="err" role="alert"></p>
    <div class="row end"><button class="btn sec" data-x>Close</button><button class="btn ghost" id="tsave">Save status</button><button class="btn" id="tsend">Send reply</button></div>`, { wide: true });
  m.querySelectorAll("a[data-x]").forEach((a) => a.addEventListener("click", () => m.close()));
  const body = () => m.querySelector("#trep").value.trim();
  m.querySelector("#tsend").addEventListener("click", async () => {
    if (!body()) return (m.querySelector(".err").textContent = "Write a reply first.");
    try { await rpc("staff_reply_ticket", { p_ticket: t.id, p_body: body(), p_internal: m.querySelector("#tint").checked }); m.close(); toast("Reply sent."); reload(); open(id, ctx, reload); } catch (e) { fail(e); }
  });
  m.querySelector("#tsave").addEventListener("click", async () => {
    try { await rpc("staff_update_ticket", { p_ticket: t.id, p_status: m.querySelector("#ts").value, p_assign: null, p_priority: m.querySelector("#tp").value }); m.close(); toast("Saved."); reload(); } catch (e) { fail(e); }
  });
}
