import { rpc } from "../core/api.js";
import { esc, pill, userLink, dd, ask, toast, fail, stars } from "../core/ui.js";
import { listPage } from "../core/list.js";

export default function reviews(el, ctx) {
  listPage(el, {
    title: "Reviews", sub: "Hide reviews that break the rules. Hiding needs a reason and is recorded.", search: "Search review text or member name", exportName: "reviews",
    filters: [{ key: "status", label: "Status", options: [["", "Any status"], ["published", "Published"], ["flagged", "Flagged"], ["hidden", "Hidden"]] }],
    fetch: ({ q, f, offset, limit }) => rpc("admin_list_reviews", { p_status: f.status, p_q: q, p_limit: limit, p_offset: offset }),
    columns: [
      { h: "From", cell: (r) => userLink(r.reviewer_id, r.reviewer), csv: (r) => r.reviewer },
      { h: "About", cell: (r) => userLink(r.reviewee_id, r.reviewee), csv: (r) => r.reviewee },
      { h: "Rating", cell: (r) => `<span class="star">${stars(r.rating)}</span>`, csv: (r) => r.rating },
      { h: "Review", cell: (r) => `${esc(r.body || "—")}${r.deal ? `<div class="mut small">Deal: ${esc(r.deal)}</div>` : ""}`, csv: (r) => r.body },
      { h: "Status", cell: (r) => pill(r.status), csv: (r) => r.status },
      { h: "Date", cell: (r) => dd(r.created_at), csv: (r) => r.created_at },
      { h: "", cell: (r) => (ctx.can("reviews.moderate") ? (r.status === "hidden" ? `<button class="btn sm sec" data-r="${r.id}" data-a="restore">Restore</button>` : `<button class="btn sm red" data-r="${r.id}" data-a="hide">Hide</button>`) : "") },
    ],
    after: (res, rows, reload) => res.querySelectorAll("[data-r]").forEach((b) => b.addEventListener("click", async () => {
      let note = "";
      if (b.dataset.a === "hide") { const v = await ask({ title: "Hide this review", intro: "It disappears from the app and the member's rating.", confirm: "Hide review", danger: true, fields: [{ label: "Reason", required: true, max: 300 }] }); if (!v) return; note = v[0]; }
      try { await rpc("admin_moderate_review", { p_id: b.dataset.r, p_action: b.dataset.a, p_note: note }); toast(b.dataset.a === "hide" ? "Review hidden." : "Review restored."); reload(); } catch (e) { fail(e); }
    })),
  });
}
