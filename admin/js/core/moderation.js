import { rpc, publicUrl } from "./api.js";
import { esc, modal, toast, fail, kv, pill, userLink, label } from "./ui.js";


export function gallery(bucket, paths) {
  const list = (paths || []).filter(Boolean);
  return list.length ? `<div class="gal">${list.map((p) => `<a href="${esc(publicUrl(bucket, p))}" target="_blank" rel="noopener noreferrer"><img src="${esc(publicUrl(bucket, p))}" alt="" loading="lazy" referrerpolicy="no-referrer"></a>`).join("")}</div>` : `<p class="mut">No photos.</p>`;
}

// Shared review screen for listings and errands: full details, owner link, decision with a note.
// Which actions make sense for the current status. Approve publishes the post straight away (listing -> live, errand -> open).
function actionsFor(status) {
  const publish = ["approve", "Approve and publish", "ok"];
  if (["pending_review", "changes_requested", "rejected", "draft"].includes(status)) return [publish, ["request_changes", "Ask for changes", "sec"], ["reject", "Reject", "bad"]];
  if (status === "suspended") return [["approve", "Reinstate", "ok"], ["remove", "Remove", "bad"]];
  if (["live", "open", "reserved", "unavailable"].includes(status)) return [["suspend", "Suspend", "sec"], ["remove", "Remove", "bad"]];
  return [["remove", "Remove", "bad"]];
}
const DONE = { approve: "Approved. It is now live and the member was notified.", request_changes: "Sent back for changes. The member was notified.", reject: "Rejected. The member was notified.", suspend: "Suspended.", remove: "Removed." };

// Shared review screen for listings and errands: full details, owner link, one button per decision.
export function reviewModal({ title, rows, images, bucket, fn, ownerId, ownerName, ownerEmail, id, risk, canDecide, after, status }) {
  const acts = actionsFor(status);
  const m = modal(`<h2>${esc(title)}</h2>
    <div class="owner">${userLink(ownerId, ownerName)} <span class="mut">${esc(ownerEmail || "")}</span></div>
    ${risk != null ? `<p>Risk score: ${pill(risk, risk >= 50 ? "r" : risk >= 25 ? "a" : "")}</p>` : ""}
    ${gallery(bucket, images)}${kv(rows)}
    ${canDecide ? `<label for="dn">Note to the member (required for anything except approving)</label><textarea id="dn" maxlength="500"></textarea><p class="err" role="alert"></p>` : ""}
    <div class="row end"><button class="btn sec" data-x>Close</button>${canDecide ? acts.map(([v, l, c]) => `<button class="btn ${c === "ok" ? "" : c === "bad" ? "red" : "sec"}" data-dec="${v}">${l}</button>`).join("") : ""}</div>`, { wide: true });
  m.querySelectorAll("[data-dec]").forEach((btn) => btn.addEventListener("click", async () => {
    const decision = btn.dataset.dec, note = m.querySelector("#dn").value.trim();
    if (decision !== "approve" && !note) { m.querySelector(".err").textContent = "Add a short note so the member knows why."; return; }
    m.querySelectorAll("[data-dec]").forEach((b) => (b.disabled = true));
    try { await rpc(fn, { p_id: id, p_decision: decision, p_note: note || null }); m.close(); toast(DONE[decision] || "Done."); after?.(); }
    catch (e) { m.querySelectorAll("[data-dec]").forEach((b) => (b.disabled = false)); fail(e); }
  }));
  return m;
}
export { label };
