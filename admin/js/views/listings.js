import { rpc } from "../core/api.js";
import { esc, ngn, pill, userLink, dd, label, num, avatar } from "../core/ui.js";
import { listPage } from "../core/list.js";
import { reviewModal } from "../core/moderation.js";
import { publicUrl } from "../core/api.js";

export default function listings(el, ctx) {
  listPage(el, {
    title: "Listings & services", sub: "Items and services members post. Anything waiting for review is shown first.", search: "Search title, owner name or owner email", exportName: "listings",
    filters: [
      { key: "kind", label: "Type", options: [["", "Items and services"], ["item", "Items"], ["service", "Services"]] },
      { key: "status", label: "Status", value: "pending_review", options: [["", "Any status"], ["pending_review", "Waiting for review"], ["live", "Approved (live)"], ["reserved", "Reserved"], ["changes_requested", "Changes requested"], ["rejected", "Rejected"], ["suspended", "Suspended"], ["archived", "Archived"]] },
    ],
    fetch: ({ q, f, offset, limit }) => rpc("admin_list_listings", { p_kind: f.kind, p_status: f.status, p_q: q, p_limit: limit, p_offset: offset }),
    columns: [
      { h: "Listing", cell: (l) => `<div class="who2">${l.images?.[0] ? `<img class="thumb" src="${esc(publicUrl("listing-images", l.images[0]))}" alt="" loading="lazy" referrerpolicy="no-referrer">` : `<span class="thumb ph"></span>`}<div><b>${esc(l.title)}</b><div class="mut small">${esc(l.category_label || "")} · ${esc(l.kind)}</div></div></div>`, csv: (l) => l.title },
      { h: "Owner", cell: (l) => `${userLink(l.owner_id, l.owner_name)}<div class="mut small">${esc(l.owner_email)}</div>`, csv: (l) => `${l.owner_name} <${l.owner_email}>` },
      { h: "Price/day", cell: (l) => ngn(l.price_per_day), csv: (l) => l.price_per_day },
      { h: "Risk", cell: (l) => (l.risk_score != null ? pill(l.risk_score, l.risk_score >= 50 ? "r" : l.risk_score >= 25 ? "a" : "") : "—"), csv: (l) => l.risk_score },
      { h: "Status", cell: (l) => pill(l.status), csv: (l) => l.status },
      { h: "Submitted", cell: (l) => dd(l.submitted_at || l.created_at), csv: (l) => l.submitted_at || l.created_at },
    ],
    onRow: (l, reload) => reviewModal({
      title: l.title, bucket: "listing-images", images: l.images, fn: "moderate_listing", id: l.id, ownerId: l.owner_id, ownerName: l.owner_name, ownerEmail: l.owner_email, risk: l.risk_score,
      canDecide: ctx.can("listings.moderate"), status: l.status, after: reload,
      rows: [["Type", esc(l.kind)], ["Category", esc([l.category_label, l.sub_category].filter(Boolean).join(" › "))], ["Price per day", ngn(l.price_per_day)], ["Deposit", ngn(l.collateral)], ["Stock", num(l.stock)], ["Lending period", esc(l.lending_period)], ["Availability", esc(l.availability)], ["Delivery", esc(label(l.delivery_option))], ["Location", esc(l.location_label)], ["Description", esc(l.description)], ["Features", esc(Array.isArray(l.features) ? l.features.join(", ") : l.features)], ["Status", pill(l.status)], ["Last review note", esc(l.review_note)], ["Rating", l.rating_count ? `${Number(l.rating_avg).toFixed(1)} (${l.rating_count})` : ""], ["Posted", dd(l.created_at)], ["Expires", dd(l.expires_at)]],
    }),
  });
}
