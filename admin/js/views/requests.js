import { rpc } from "../core/api.js";
import { esc, ngn, pill, dd } from "../core/ui.js";
import { listPage } from "../core/list.js";
import { reviewModal } from "../core/moderation.js";

export default function requests(el, ctx) {
  listPage(el, {
    title: "Item requests", sub: "Things members want to borrow. Approving shows the request to lenders nearby for 7 days.", search: "Search title, member name or email", exportName: "item-requests",
    filters: [{ key: "status", label: "Status", value: "pending_review", options: [["", "Any status"], ["pending_review", "Waiting for review"], ["open", "Approved (open)"], ["matched", "Matched"], ["expired", "Expired"], ["changes_requested", "Changes requested"], ["rejected", "Rejected"], ["cancelled", "Cancelled"]] }],
    fetch: async ({ q, f, offset, limit }) => {
      const all = await rpc("admin_list_requests", { p_status: f.status || null });
      const needle = (q || "").toLowerCase();
      const rows = (all || []).filter((r) => !needle || `${r.title} ${r.requester}`.toLowerCase().includes(needle));
      return { rows: rows.slice(offset, offset + limit), total: rows.length };
    },
    columns: [
      { h: "Request", cell: (r) => `<b>${esc(r.title)}</b><div class="mut small">${esc(r.area || "")}</div>`, csv: (r) => r.title },
      { h: "Member", cell: (r) => esc(r.requester), csv: (r) => r.requester },
      { h: "Budget", cell: (r) => (Number(r.budget_ngn) ? ngn(r.budget_ngn) : "—"), csv: (r) => r.budget_ngn },
      { h: "Offers", cell: (r) => esc(r.bids), csv: (r) => r.bids },
      { h: "Status", cell: (r) => pill(r.status), csv: (r) => r.status },
      { h: "Posted", cell: (r) => dd(r.created_at), csv: (r) => r.created_at },
    ],
    onRow: (r, reload) => reviewModal({
      title: r.title, bucket: "task-images", images: [], fn: "moderate_request", id: r.id, ownerId: r.user_id, ownerName: r.requester, ownerEmail: "",
      canDecide: ctx.can("requests.moderate"), status: r.status, after: reload,
      rows: [["Budget", Number(r.budget_ngn) ? ngn(r.budget_ngn) : ""], ["Days needed", esc(r.duration_days)], ["Needed from", dd(r.needed_from)], ["Radius", `${esc(r.radius_km)} km`], ["Area", esc(r.area)], ["Description", esc(r.description)], ["Offers", esc(r.bids)], ["Status", pill(r.status)], ["Expires", dd(r.expires_at)], ["Last review note", esc(r.review_note)], ["Posted", dd(r.created_at)]],
    }),
  });
}
