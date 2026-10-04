import { rpc } from "../core/api.js";
import { esc, pill, userLink, dt, ask, toast, fail, label } from "../core/ui.js";
import { listPage } from "../core/list.js";

export default function reports(el) {
  listPage(el, {
    title: "Reports", sub: "What members flagged. Open the reported member to see their full history before you decide.", exportName: "reports", pageSize: 25,
    filters: [{ key: "status", label: "Status", value: "open", options: [["", "Any status"], ["open", "Open"], ["reviewing", "Reviewing"], ["actioned", "Actioned"], ["dismissed", "Dismissed"]] }],
    fetch: async ({ f, offset, limit }) => { const r = await rpc("admin_list_reports", { p_status: f.status, p_limit: limit + 1, p_offset: offset }); const rows = r.rows || []; const more = rows.length > limit; return { rows: rows.slice(0, limit), more, total: offset + Math.min(rows.length, limit) + (more ? 1 : 0) }; },
    columns: [
      { h: "When", cell: (r) => dt(r.created_at), csv: (r) => r.created_at },
      { h: "Reported by", cell: (r) => `${userLink(r.reporter_id, r.reporter)}<div class="mut small">${esc(r.reporter_email)}</div>`, csv: (r) => `${r.reporter} <${r.reporter_email}>` },
      { h: "About", cell: (r) => `<span class="pill n">${esc(r.target_type)}</span> ${esc(r.target_label || "")}${r.target_user ? `<div>${userLink(r.target_user, "Open member")}</div>` : ""}`, csv: (r) => `${r.target_type}: ${r.target_label || r.target_id}` },
      { h: "Reason", cell: (r) => `<b>${esc(label(r.reason))}</b><div class="mut small">${esc(r.details || "")}</div>`, csv: (r) => `${r.reason} ${r.details || ""}` },
      { h: "Status", cell: (r) => pill(r.status), csv: (r) => r.status },
      { h: "", cell: (r) => (["open", "reviewing"].includes(r.status) ? `<button class="btn sm sec" data-r="${r.id}" data-s="reviewing">Reviewing</button> <button class="btn sm" data-r="${r.id}" data-s="actioned">Actioned</button> <button class="btn sm ghost" data-r="${r.id}" data-s="dismissed">Dismiss</button>` : "") },
    ],
    after: (res, rows, reload) => res.querySelectorAll("[data-r]").forEach((b) => b.addEventListener("click", async () => {
      const v = await ask({ title: `Mark report as ${b.dataset.s}`, confirm: "Save", fields: [{ label: "Note (saved in the audit log)", required: b.dataset.s !== "reviewing", max: 300 }] }); if (!v) return;
      try { await rpc("admin_handle_report", { p_id: b.dataset.r, p_status: b.dataset.s, p_note: v[0] }); toast("Saved."); reload(); } catch (e) { fail(e); }
    })),
  });
}
