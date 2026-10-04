import { rpc, publicUrl } from "./api.js";
import { esc, modal, toast, fail, kv, pill, userLink, label } from "./ui.js";

const DECISIONS = [["approve", "Approve"], ["request_changes", "Ask for changes"], ["reject", "Reject"], ["suspend", "Suspend"], ["remove", "Remove"]];

export function gallery(bucket, paths) {
  const list = (paths || []).filter(Boolean);
  return list.length ? `<div class="gal">${list.map((p) => `<a href="${esc(publicUrl(bucket, p))}" target="_blank" rel="noopener noreferrer"><img src="${esc(publicUrl(bucket, p))}" alt="" loading="lazy" referrerpolicy="no-referrer"></a>`).join("")}</div>` : `<p class="mut">No photos.</p>`;
}

// Shared review screen for listings and errands: full details, owner link, decision with a note.
export function reviewModal({ title, rows, images, bucket, fn, ownerId, ownerName, ownerEmail, id, risk, canDecide, after }) {
  const m = modal(`<h2>${esc(title)}</h2>
    <div class="owner">${userLink(ownerId, ownerName)} <span class="mut">${esc(ownerEmail || "")}</span></div>
    ${risk != null ? `<p>Risk score: ${pill(risk, risk >= 50 ? "r" : risk >= 25 ? "a" : "")}</p>` : ""}
    ${gallery(bucket, images)}${kv(rows)}
    ${canDecide ? `<label for="dd">Decision</label><select id="dd">${DECISIONS.map(([v, l]) => `<option value="${v}">${l}</option>`).join("")}</select>
      <label for="dn">Note to the member (needed unless approving)</label><textarea id="dn" maxlength="500"></textarea><p class="err" role="alert"></p>` : ""}
    <div class="row end"><button class="btn sec" data-x>Close</button>${canDecide ? `<button class="btn" id="dok">Save decision</button>` : ""}</div>`, { wide: true });
  m.querySelector("#dok")?.addEventListener("click", async () => {
    const decision = m.querySelector("#dd").value, note = m.querySelector("#dn").value.trim();
    if (decision !== "approve" && !note) { m.querySelector(".err").textContent = "Add a short note so the member knows what to fix."; return; }
    try { await rpc(fn, { p_id: id, p_decision: decision, p_note: note || null }); m.close(); toast("Decision saved."); after?.(); } catch (e) { fail(e); }
  });
  return m;
}
export { label };
