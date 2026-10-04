import { rpc, publicUrl } from "../core/api.js";
import { $, $$, esc, ngn, num, dt, dd, ago, pill, avatar, fullName, userLink, copyBtn, kv, table, empty, ask, modal, toast, fail, label, stars, icon, short, UUID } from "../core/ui.js";
import { csvRows, download, stamp, safeName, logExport, printPage } from "../core/export.js";

const PLANS = [["on_code", "On Code (free)"], ["active", "Active"], ["hustler", "Hustler"], ["top_lender", "Top Lender"]];

export default async function userProfile(el, ctx, id) {
  if (!UUID.test(id)) throw new Error("That isn't a valid user link.");
  const d = await rpc("admin_user_360", { p_user: id });
  const p = d.profile, a = d.access, s = d.stats, name = fullName(p);
  const tabs = [["profile", "Profile"], ["activity", "Activity"], ["market", "Listings & deals"], a.payments && ["money", "Money & plan"], ["reviews", "Reviews"], ["safety", "Safety"], ["support", "Support"], a.chats && ["chats", "Chats"], a.notes && ["notes", "Notes & staff log"]].filter(Boolean);
  const avatarUrl = p.avatar_url ? publicUrl("avatars", p.avatar_url) : "";
  const plan = d.plan ? `${esc(d.plan.plan_name)}${d.plan.current_period_end ? ` · until ${dd(d.plan.current_period_end)}` : ""}` : "On Code (free)";
  const bad = ["suspended", "banned"].includes(p.account_status);

  el.innerHTML = `<a class="back" href="#/users">${icon("back")} All users</a>
  <article class="cv" id="cv">
    <header class="cvh">
      ${avatar(avatarUrl, name, 96)}
      <div class="cvi">
        <div class="row"><h2>${esc(name)}</h2>${pill(p.account_status)}${pill(p.verification_status)}${d.plan ? pill(d.plan.plan_id, "") : pill("on_code", "n")}</div>
        <div class="contact"><span>${icon("shield", 15)} ${esc(p.email)}${copyBtn(p.email)}</span>${p.phone ? `<span>${esc(p.phone)}${copyBtn(p.phone)}${p.phone_verified ? ' <span class="mut small">verified</span>' : ""}</span>` : ""}${p.city ? `<span>${esc([p.city, p.country].filter(Boolean).join(", "))}</span>` : ""}</div>
        <div class="mut small">Joined ${dt(p.created_at)} · last seen ${esc(ago(p.last_seen_at))} · ID <code>${esc(short(p.id))}</code>${copyBtn(p.id)}</div>
        ${bad ? `<div class="alertbar">This account is ${esc(label(p.account_status))}.</div>` : ""}
      </div>
      <div class="cva noprint">
        ${a.moderate ? `<button class="btn red sm" id="a-mod">${bad ? "Review suspension" : "Suspend or ban"}</button>` : ""}
        ${a.notify ? `<button class="btn sec sm" id="a-msg">Message user</button>` : ""}
        ${a.plans ? `<button class="btn sec sm" id="a-plan">Give a plan</button>` : ""}
        <button class="btn ghost sm" id="a-csv">${icon("down")} CSV</button>
        <button class="btn ghost sm" id="a-pdf">${icon("print")} PDF</button>
      </div>
    </header>
    <div class="cards kpis">
      <div class="card"><div class="l">Listings</div><div class="v">${num(s.listings_live)}<small> / ${num(s.listings_total)}</small></div></div>
      <div class="card"><div class="l">Errands posted</div><div class="v">${num(s.tasks_posted)}</div></div>
      <div class="card"><div class="l">Deals</div><div class="v">${num(s.tx_as_borrower + s.tx_as_lender)}</div><div class="mut small">${s.tx_as_borrower} borrowing · ${s.tx_as_lender} lending</div></div>
      <div class="card"><div class="l">Deal value</div><div class="v">${ngn(s.tx_value)}</div></div>
      ${a.payments ? `<div class="card"><div class="l">Paid to Seculate</div><div class="v">${ngn(s.paid_total)}</div></div>` : ""}
      <div class="card"><div class="l">Rating</div><div class="v">${p.rating_count ? Number(p.rating_avg).toFixed(1) : "—"}</div><div class="mut small">${num(p.rating_count)} reviews</div></div>
      <div class="card ${s.violations ? "alert" : ""}"><div class="l">Violations</div><div class="v">${num(s.violations)}</div></div>
      <div class="card ${s.reports_against ? "alert" : ""}"><div class="l">Reports against</div><div class="v">${num(s.reports_against)}</div></div>
    </div>
    <nav class="tabs noprint" role="tablist">${tabs.map(([k, l], i) => `<button role="tab" data-t="${k}" class="${i ? "" : "on"}" aria-selected="${!i}">${esc(l)}</button>`).join("")}</nav>
    <div id="panes">${tabs.map(([k, l], i) => `<section class="pane ${i ? "" : "on"}" data-p="${k}" role="tabpanel" aria-label="${esc(l)}"><h3 class="print-h">${esc(l)}</h3>${pane(k, d, ctx)}</section>`).join("")}</div>
    <footer class="printmeta">Seculate staff report · prepared by ${esc(ctx.email)} on ${esc(dt(new Date()))} · confidential, for support and compliance use only.</footer>
  </article>`;

  // tabs
  $$("[data-t]", el).forEach((b) => b.addEventListener("click", () => {
    $$("[data-t]", el).forEach((x) => { x.classList.toggle("on", x === b); x.setAttribute("aria-selected", x === b); });
    $$(".pane", el).forEach((x) => x.classList.toggle("on", x.dataset.p === b.dataset.t));
  }));

  // actions
  $("#a-mod", el)?.addEventListener("click", async () => {
    const v = await ask({ title: `Account action for ${name}`, intro: "The reason is shown to the member and saved in the audit log.", confirm: "Apply", danger: true, fields: [
      { label: "Action", type: "select", options: [["suspend", "Suspend"], ["ban", "Ban"], ["extend", "Extend suspension"], ["lift", "Lift suspension or ban"]] },
      { label: "Days (suspend or extend)", type: "number", value: 7 }, { label: "Reason", required: true, max: 500 }] });
    if (!v) return;
    try { await rpc("staff_decide_suspension", { p_user: id, p_decision: v[0], p_reason: v[2], p_days: Number(v[1]) || null }); toast("Done."); userProfile(el, ctx, id); } catch (e) { fail(e); }
  });
  $("#a-msg", el)?.addEventListener("click", async () => {
    const v = await ask({ title: `Message ${name}`, intro: "Sent as an in-app notification.", confirm: "Send", fields: [{ label: "Title", type: "text", max: 80, required: true }, { label: "Message", max: 500, required: true }] });
    if (!v) return; try { await rpc("admin_notify_user", { p_user: id, p_title: v[0], p_body: v[1] }); toast("Message sent."); } catch (e) { fail(e); }
  });
  $("#a-plan", el)?.addEventListener("click", async () => {
    const v = await ask({ title: `Give ${name} a plan`, intro: "Replaces their current plan without a payment. Recorded in the audit log.", confirm: "Give plan", fields: [{ label: "Plan", type: "select", options: PLANS }, { label: "Days", type: "number", value: 30 }, { label: "Reason", required: true, max: 300 }] });
    if (!v) return; try { await rpc("admin_grant_plan", { p_user: id, p_plan: v[0], p_days: Number(v[1]) || 30, p_reason: v[2] }); toast("Plan updated."); userProfile(el, ctx, id); } catch (e) { fail(e); }
  });
  $("#a-csv", el).addEventListener("click", async () => { download(`seculate-user-${safeName(name)}-${stamp()}.csv`, userCsv(d, name)); await logExport("user", short(id), "csv"); toast("CSV downloaded."); });
  $("#a-pdf", el).addEventListener("click", () => printPage(`Seculate user report - ${name}`, "user", short(id)));

  // chat history (reason required, audited)
  const chatBtn = $("#load-chats", el);
  chatBtn?.addEventListener("click", async () => {
    const v = await ask({ title: "Open chat history", intro: "Reading private messages needs a reason. It is saved in the audit log with your name.", confirm: "Open", fields: [{ label: "Reason", required: true, max: 300, placeholder: "e.g. Support ticket #123, user reported harassment" }] });
    if (!v) return;
    try {
      const list = await rpc("admin_user_conversations", { p_user: id, p_reason: v[0] });
      $("#chat-list", el).innerHTML = list.length ? list.map((c) => `<div class="conv"><div><b>${esc((c.members || []).filter((m) => m.id !== id).map((m) => m.name || "Unknown").join(", ") || "Conversation")}</b>${c.listing_title ? ` <span class="mut">· ${esc(c.listing_title)}</span>` : ""}<div class="mut small">${num(c.messages)} messages${c.flagged ? ` · <span class="bad">${c.flagged} flagged</span>` : ""} · last ${esc(ago(c.last_message_at))}</div></div><button class="btn sm sec" data-conv="${c.id}">Read</button></div>`).join("") : empty("No conversations.");
      chatBtn.hidden = true;
      $$("[data-conv]", el).forEach((b) => b.addEventListener("click", async () => {
        const c = list.find((x) => x.id === b.dataset.conv); const who = Object.fromEntries((c.members || []).map((m) => [m.id, m.name || "Unknown"]));
        try {
          const msgs = await rpc("staff_read_conversation", { p_conv: c.id, p_reason: v[0] });
          modal(`<h2>${esc((c.members || []).map((m) => m.name).join(" & "))}</h2><div class="chat">${(msgs || []).map((m) => `<div class="msg ${m.sender_id === id ? "me" : ""} ${m.flagged ? "flag" : ""}"><b>${esc(who[m.sender_id] || "Unknown")}</b> <span class="mut small">${dt(m.created_at)}</span><br>${esc(m.body || (m.attachment_path ? "[attachment]" : ""))}</div>`).join("") || empty("No messages.")}</div><div class="row end"><button class="btn sec" data-x>Close</button></div>`, { wide: true });
        } catch (e) { fail(e); }
      }));
    } catch (e) { fail(e); }
  });

  // notes
  $("#add-note", el)?.addEventListener("click", async () => {
    const box = $("#note-body", el), body = box.value.trim(); if (!body) return toast("Write a note first.", "bad");
    try { await rpc("admin_add_note", { p_user: id, p_body: body }); toast("Note saved."); userProfile(el, ctx, id); } catch (e) { fail(e); }
  });
}

function pane(k, d, ctx) {
  const p = d.profile, a = d.access, au = d.auth || {}, s = d.stats;
  const money = (v) => ngn(v);
  const trow = (cols, rows, emptyText) => table(cols, rows, { empty: emptyText });
  switch (k) {
    case "profile": return `<div class="grid2">
      <div class="panel"><h3>Personal</h3>${kv([["Full name", esc(fullName(p))], ["Gender", esc(p.sex)], a.sensitive && ["Date of birth", p.birthday ? dd(p.birthday) : ""], ["Language", esc(p.language)], ["Bio", esc(p.bio)], ["Country", esc(p.country)], ["City", esc(p.city)], a.sensitive && ["Address", esc(p.address)]])}</div>
      <div class="panel"><h3>Account</h3>${kv([["Email", `${esc(p.email)} ${au.email_confirmed_at ? '<span class="mut small">confirmed</span>' : '<span class="bad small">not confirmed</span>'}`], ["Phone", esc(p.phone)], ["Joined", dt(p.created_at)], ["Last seen in app", dt(p.last_seen_at)], ["Last sign-in", dt(au.last_sign_in_at)], ["Sign-in method", esc((au.providers || []).join(", "))], ["Status", pill(p.account_status)], ["Member ID", `<code>${esc(p.id)}</code>${copyBtn(p.id)}`]])}</div>
      <div class="panel"><h3>Business</h3>${p.business_name || p.business_about || p.business_link ? kv([["Business name", esc(p.business_name)], ["About", esc(p.business_about)], ["Link", esc(p.business_link)]]) : empty("No business details.")}</div>
      <div class="panel"><h3>Identity checks</h3>${trow(["Date", "Document", "Provider", "Result", "Name on ID"], (d.verification || []).map((v) => ({ cells: [dt(v.created_at), esc(label(v.doc_type)), esc(v.provider), pill(v.status), esc(v.verified_name || "—") + (v.id_last4 ? ` <span class="mut">···${esc(v.id_last4)}</span>` : "")] })), "No identity checks yet.")}</div>
      <div class="panel"><h3>Devices</h3>${(d.devices || []).length ? (d.devices || []).map((x) => `<div class="li">${esc(x.platform || "Device")} <span class="mut">since ${dd(x.since)}</span></div>`).join("") : empty("No devices registered for notifications.")}</div>
      <div class="panel"><h3>Community</h3>${kv([["Conversations", num(s.conversations)], ["Messages sent", num(s.messages_sent)], ["Flagged messages", s.flagged_messages ? `<b class="bad">${num(s.flagged_messages)}</b>` : "0"], ["Blocked by others", num(s.blocked_by)], ["Has blocked", num(s.blocking)], ["Unread notifications", num(s.unread_notifications)]])}</div></div>`;
    case "activity": return `<div class="panel">${(d.timeline || []).length ? `<ol class="tl">${d.timeline.map((e) => `<li class="k-${esc(e.kind)}"><time>${dt(e.ts)}</time><span>${esc(e.label)}</span></li>`).join("")}</ol>` : empty("No activity yet.")}</div>`;
    case "market": return `<h3>Listings (${(d.listings || []).length})</h3>${trow(["Title", "Type", "Category", "Price/day", "Rating", "Status", "Posted"], (d.listings || []).map((l) => ({ cells: [esc(l.title), esc(l.kind), esc(l.category_label), money(l.price_per_day), l.rating_count ? `${Number(l.rating_avg).toFixed(1)} (${l.rating_count})` : "—", pill(l.status), dd(l.created_at)] })), "No listings.")}
      <h3>Errands (${(d.tasks || []).length})</h3>${trow(["Title", "Category", "Offer", "Agreed", "Status", "Posted"], (d.tasks || []).map((t) => ({ cells: [esc(t.title), esc(t.category_label), money(t.proposed_price), t.agreed_price ? money(t.agreed_price) : "—", pill(t.status), dd(t.created_at)] })), "No errands.")}
      <h3>Deals (${(d.transactions || []).length})</h3>${trow(["Deal", "Role", "Other person", "Amount", "Deposit", "Stage", "Date"], (d.transactions || []).map((t) => ({ cells: [esc(t.title), esc(t.role), userLink(t.other_id, t.other_party), money(t.amount), money(t.collateral), pill(t.state), dd(t.created_at)] })), "No deals.")}`;
    case "money": return `<h3>Plan</h3><div class="panel">${d.plan ? kv([["Current plan", esc(d.plan.plan_name)], ["Status", pill(d.plan.status)], ["Started", dd(d.plan.current_period_start)], ["Renews or ends", dd(d.plan.current_period_end)]]) : empty("On the free On Code plan.")}</div>
      <h3>Plan history</h3>${trow(["Plan", "Status", "From", "To", "How"], (d.subscriptions || []).map((x) => ({ cells: [esc(x.plan_name), pill(x.status), dd(x.current_period_start), dd(x.current_period_end), esc(x.payment_ref === "staff_grant" ? "Given by staff" : "Paid")] })), "No plan history.")}
      <h3>Payments</h3>${trow(["Date", "For", "Plan", "Amount", "Status", "Reference"], (d.payments || []).map((x) => ({ cells: [dt(x.created_at), esc(label(x.purpose)), esc(x.plan_id || "—"), money(x.amount), pill(x.status), `<code>${esc(x.tx_ref)}</code>`] })), "No payments.")}`;
    case "reviews": return `<h3>Reviews received (${(d.reviews_received || []).length})</h3>${trow(["From", "Rating", "Review", "Status", "Date"], (d.reviews_received || []).map((r) => ({ cells: [userLink(r.reviewer_id, r.reviewer), `<span class="star">${stars(r.rating)}</span>`, esc(r.body || "—"), pill(r.status), dd(r.created_at)] })), "No reviews received.")}
      <h3>Reviews written (${(d.reviews_given || []).length})</h3>${trow(["About", "Rating", "Review", "Status", "Date"], (d.reviews_given || []).map((r) => ({ cells: [userLink(r.reviewee_id, r.reviewee), `<span class="star">${stars(r.rating)}</span>`, esc(r.body || "—"), pill(r.status), dd(r.created_at)] })), "No reviews written.")}`;
    case "safety": return `<h3>Reports against this member (${(d.reports_against || []).length})</h3>${trow(["Reported by", "Reason", "Details", "Status", "Date"], (d.reports_against || []).map((r) => ({ cells: [userLink(r.reporter_id, r.reporter), esc(r.reason), esc(r.details || "—"), pill(r.status), dd(r.created_at)] })), "No reports against this member.")}
      <h3>Reports they filed (${(d.reports_filed || []).length})</h3>${trow(["About", "Reason", "Status", "Date"], (d.reports_filed || []).map((r) => ({ cells: [esc(r.target_type), esc(r.reason), pill(r.status), dd(r.created_at)] })), "None.")}
      <h3>Violations (${(d.violations || []).length})</h3>${trow(["Date", "Source", "Severity", "Note"], (d.violations || []).map((v) => ({ cells: [dt(v.created_at), esc(v.source), esc(v.severity), esc(v.note || "—")] })), "No violations.")}
      <h3>Suspensions and bans</h3>${trow(["Date", "Type", "Status", "Reason", "Ends"], (d.suspensions || []).map((v) => ({ cells: [dt(v.created_at), esc(v.kind), pill(v.status), esc(v.reason || "—"), v.ends_at ? dd(v.ends_at) : "—"] })), "None.")}
      <h3>Disputes</h3>${trow(["Deal", "Amount", "Status", "Reason", "Opened"], (d.disputes || []).map((x) => ({ cells: [esc(x.title), money(x.amount), pill(x.status), esc((x.reason || "").slice(0, 100)), dd(x.created_at)] })), "No disputes.")}`;
    case "support": return `<h3>Support tickets (${(d.tickets || []).length})</h3>${trow(["Opened", "Subject", "Type", "Priority", "Status", ""], (d.tickets || []).map((t) => ({ cells: [dt(t.created_at), esc(t.subject), esc(t.category), pill(t.priority), pill(t.status), ctx.can("tickets.manage") ? `<a class="btn sm sec noprint" href="#/tickets/${t.id}">Open</a>` : ""] })), "No tickets.")}`;
    case "chats": return `<div class="panel"><h3>Chat history</h3><p class="mut">${num(s.conversations)} conversations · ${num(s.messages_sent)} messages sent. Opening chats needs a reason and is saved in the audit log.</p><button class="btn noprint" id="load-chats">Open chat history</button><div id="chat-list"></div></div>`;
    case "notes": return `<div class="panel noprint"><h3>Add a private note</h3><label for="note-body" class="sr">Note</label><textarea id="note-body" maxlength="2000" placeholder="Only staff can see this. Add context for the next person who helps this customer."></textarea><div class="row end"><button class="btn" id="add-note">Save note</button></div></div>
      <h3>Notes</h3>${(d.notes || []).length ? d.notes.map((n) => `<div class="note"><div class="mut small">${esc(n.author || "Staff")} · ${dt(n.created_at)}</div>${esc(n.body)}</div>`).join("") : empty("No notes yet.")}
      <h3>Staff actions on this member</h3>${trow(["Date", "Role", "Action", "Reason"], (d.staff_actions || []).map((x) => ({ cells: [dt(x.created_at), esc(label(x.actor_role)), `<code>${esc(x.action)}</code>`, esc(x.reason || "—")] })), "No staff actions yet.")}`;
  }
  return "";
}

function userCsv(d, name) {
  const p = d.profile, s = d.stats, out = [];
  const block = (title, header, rows) => { out.push([title]); if (header) out.push(header); rows.forEach((r) => out.push(r)); out.push([]); };
  block("SECULATE USER REPORT", null, [["Name", name], ["Email", p.email], ["Phone", p.phone], ["Status", p.account_status], ["Verification", p.verification_status], ["City", p.city], ["Country", p.country], ["Joined", p.created_at], ["Last seen", p.last_seen_at], ["Member ID", p.id], ["Plan", d.plan?.plan_name || "On Code (free)"], ["Exported", new Date().toISOString()]]);
  block("SUMMARY", ["Measure", "Value"], Object.entries(s).filter(([, v]) => v !== null && v !== undefined).map(([k, v]) => [label(k), v]));
  block("ACTIVITY", ["When", "Type", "What"], (d.timeline || []).map((e) => [e.ts, e.kind, e.label]));
  block("LISTINGS", ["Title", "Type", "Category", "Price per day", "Status", "Posted"], (d.listings || []).map((l) => [l.title, l.kind, l.category_label, l.price_per_day, l.status, l.created_at]));
  block("ERRANDS", ["Title", "Category", "Offer", "Agreed", "Status", "Posted"], (d.tasks || []).map((t) => [t.title, t.category_label, t.proposed_price, t.agreed_price, t.status, t.created_at]));
  block("DEALS", ["Deal", "Role", "Other person", "Amount", "Deposit", "Stage", "Date"], (d.transactions || []).map((t) => [t.title, t.role, t.other_party, t.amount, t.collateral, t.state, t.created_at]));
  if (d.payments) block("PAYMENTS", ["Date", "For", "Plan", "Amount", "Status", "Reference"], d.payments.map((x) => [x.created_at, x.purpose, x.plan_id, x.amount, x.status, x.tx_ref]));
  block("REVIEWS RECEIVED", ["From", "Rating", "Review", "Status", "Date"], (d.reviews_received || []).map((r) => [r.reviewer, r.rating, r.body, r.status, r.created_at]));
  block("REVIEWS WRITTEN", ["About", "Rating", "Review", "Status", "Date"], (d.reviews_given || []).map((r) => [r.reviewee, r.rating, r.body, r.status, r.created_at]));
  block("REPORTS AGAINST", ["By", "Reason", "Details", "Status", "Date"], (d.reports_against || []).map((r) => [r.reporter, r.reason, r.details, r.status, r.created_at]));
  block("VIOLATIONS", ["Date", "Source", "Severity", "Note"], (d.violations || []).map((v) => [v.created_at, v.source, v.severity, v.note]));
  block("SUSPENSIONS", ["Date", "Type", "Status", "Reason"], (d.suspensions || []).map((v) => [v.created_at, v.kind, v.status, v.reason]));
  block("SUPPORT TICKETS", ["Opened", "Subject", "Type", "Priority", "Status"], (d.tickets || []).map((t) => [t.created_at, t.subject, t.category, t.priority, t.status]));
  return csvRows(out);
}
