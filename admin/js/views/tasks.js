import { rpc } from "../core/api.js";
import { esc, ngn, pill, userLink, dd } from "../core/ui.js";
import { listPage } from "../core/list.js";
import { reviewModal } from "../core/moderation.js";

export default function tasks(el, ctx) {
  listPage(el, {
    title: "Errands", sub: "Jobs members post for others to do. Anything waiting for review is shown first.", search: "Search title, poster name or email", exportName: "errands",
    filters: [{ key: "status", label: "Status", value: "pending_review", options: [["", "Any status"], ["pending_review", "Waiting for review"], ["approved", "Approved"], ["open", "Open"], ["agreed", "Agreed"], ["in_progress", "In progress"], ["completed", "Completed"], ["cancelled", "Cancelled"], ["changes_requested", "Changes requested"], ["rejected", "Rejected"], ["suspended", "Suspended"]] }],
    fetch: ({ q, f, offset, limit }) => rpc("admin_list_tasks", { p_status: f.status, p_q: q, p_limit: limit, p_offset: offset }),
    columns: [
      { h: "Errand", cell: (t) => `<b>${esc(t.title)}</b><div class="mut small">${esc(t.category_label || "")}</div>`, csv: (t) => t.title },
      { h: "Posted by", cell: (t) => `${userLink(t.requester_id, t.requester_name)}<div class="mut small">${esc(t.requester_email)}</div>`, csv: (t) => `${t.requester_name} <${t.requester_email}>` },
      { h: "Offer", cell: (t) => ngn(t.proposed_price), csv: (t) => t.proposed_price },
      { h: "Risk", cell: (t) => (t.risk_score != null ? pill(t.risk_score, t.risk_score >= 50 ? "r" : t.risk_score >= 25 ? "a" : "") : "—"), csv: (t) => t.risk_score },
      { h: "Status", cell: (t) => pill(t.status), csv: (t) => t.status },
      { h: "Posted", cell: (t) => dd(t.created_at), csv: (t) => t.created_at },
    ],
    onRow: (t, reload) => reviewModal({
      title: t.title, bucket: "task-images", images: t.images, fn: "moderate_task", id: t.id, ownerId: t.requester_id, ownerName: t.requester_name, ownerEmail: t.requester_email, risk: t.risk_score,
      canDecide: ctx.can("tasks.moderate"), after: reload,
      rows: [["Category", esc(t.category_label)], ["Offer", ngn(t.proposed_price)], ["Agreed price", t.agreed_price ? ngn(t.agreed_price) : ""], ["Location", esc(t.location_label)], ["Needed by", dd(t.needed_by)], ["Description", esc(t.description)], ["Worker", esc(t.worker_name)], ["Status", pill(t.status)], ["Last review note", esc(t.review_note)], ["Posted", dd(t.created_at)]],
    }),
  });
}
