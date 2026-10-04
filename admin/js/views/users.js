import { rpc } from "../core/api.js";
import { esc, pill, avatar, fullName, userLink, copyBtn, ago, dd, num } from "../core/ui.js";
import { listPage } from "../core/list.js";

export default async function users(el, ctx, arg) {
  if (arg) { const m = await import("./user.js"); return m.default(el, ctx, arg); }
  listPage(el, {
    title: "Users", sub: "Search by name, email, phone or ID. Paste an email to jump straight to a customer. Click anyone to open their full profile.",
    search: "Search name, email, phone or ID", exportName: "users", pageSize: 25,
    filters: [
      { key: "status", label: "Status", options: [["", "Any status"], ["active", "Active"], ["warned", "Warned"], ["restricted", "Restricted"], ["suspended", "Suspended"], ["banned", "Banned"], ["deactivated", "Deactivated"]] },
      { key: "ver", label: "Verification", options: [["", "Any verification"], ["verified", "Verified"], ["pending", "Pending"], ["unverified", "Not verified"], ["rejected", "Rejected"]] },
      { key: "plan", label: "Plan", options: [["", "Any plan"], ["on_code", "On Code (free)"], ["active", "Active"], ["hustler", "Hustler"], ["top_lender", "Top Lender"]] },
      { key: "sort", label: "Sort", options: [["newest", "Newest first"], ["oldest", "Oldest first"], ["active", "Recently active"], ["violations", "Most violations"]] },
    ],
    fetch: ({ q, f, offset, limit }) => rpc("admin_user_search", { p_q: q, p_status: f.status, p_verification: f.ver, p_plan: f.plan, p_sort: f.sort || "newest", p_limit: limit, p_offset: offset }),
    columns: [
      { h: "Member", cell: (u) => `<div class="who2">${avatar(u.avatar_url, fullName(u), 36)}<div>${userLink(u.id, fullName(u))}<div class="mut small">Joined ${dd(u.created_at)}</div></div></div>`, csv: fullName },
      { h: "Email", cell: (u) => `<span class="nowrap">${userLink(u.id, u.email)}${copyBtn(u.email)}</span>`, csv: (u) => u.email },
      { h: "Phone", cell: (u) => esc(u.phone || "—"), csv: (u) => u.phone },
      { h: "Plan", cell: (u) => pill(u.plan, u.plan === "on_code" ? "n" : ""), csv: (u) => u.plan },
      { h: "Verified", cell: (u) => pill(u.verification_status), csv: (u) => u.verification_status },
      { h: "Status", cell: (u) => pill(u.account_status), csv: (u) => u.account_status },
      { h: "Rating", cell: (u) => (u.rating_count ? `${Number(u.rating_avg).toFixed(1)} <span class="mut">(${u.rating_count})</span>` : '<span class="mut">—</span>'), csv: (u) => u.rating_avg },
      { h: "Deals", cell: (u) => num(u.completed_transactions), csv: (u) => u.completed_transactions },
      { h: "Violations", cell: (u) => (u.violation_count ? `<b class="bad">${u.violation_count}</b>` : "0"), csv: (u) => u.violation_count },
      { h: "Last seen", cell: (u) => `<span class="mut">${esc(ago(u.last_seen_at))}</span>`, csv: (u) => u.last_seen_at },
      { h: "Joined", cell: (u) => dd(u.created_at), csv: (u) => u.created_at },
    ],
    onRow: (u) => { location.hash = `#/users/${u.id}`; },
  });
}
