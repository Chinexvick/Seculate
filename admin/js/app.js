import { sb, rpc } from "./core/api.js";
import { ensureSignedIn, loginView } from "./core/auth.js";
import { $, $$, esc, toast, fail, modal } from "./core/ui.js";
import { ICONS } from "./core/icons.js";

const root = $("#root");
const LOGO = "assets/logo-192.png";
const ctx = { access: null, email: "", userId: "", counts: {}, can: () => false };

// name, label, group, permission(s) needed, badge key. Order = sidebar order.
const NAV = [
  ["overview", "Overview", "", "analytics.read|users.read"],
  ["users", "Users", "People", "users.read"],
  ["listings", "Listings", "Marketplace", "listings.moderate", "listings_pending"],
  ["tasks", "Errands", "Marketplace", "tasks.moderate", "tasks_pending"],
  ["deals", "Deals", "Marketplace", "payments.read|disputes.read"],
  ["escrow", "Escrow & payments", "Money", "payments.read|escrow.release", "release_pending"],
  ["subscriptions", "Plans & subscribers", "Money", "payments.read|subscriptions.manage"],
  ["reports", "Reports", "Trust & safety", "reports.read|chats.review", "reports_open"],
  ["chats", "Chat flags", "Trust & safety", "chats.review", "flagged_chats"],
  ["reviews", "Reviews", "Trust & safety", "reviews.moderate", "reviews_flagged"],
  ["disputes", "Disputes", "Trust & safety", "disputes.read", "disputes_open"],
  ["tickets", "Support tickets", "Support", "tickets.manage", "tickets_open"],
  ["broadcast", "Announcements", "Support", "users.notify&settings.manage"],
  ["analytics", "Analytics", "Insights", "analytics.read"],
  ["categories", "Categories", "Platform", "settings.manage"],
  ["rules", "Rules & settings", "Platform", "settings.manage"],
  ["audit", "Audit log", "Platform", "audit.read"],
  ["compliance", "Compliance", "Platform", "exports.create|users.read_sensitive|audit.read"],
];
const PRIMARY = ["overview", "users", "tickets", "deals"];
const LOADERS = {
  overview: () => import("./views/overview.js"), users: () => import("./views/users.js"), listings: () => import("./views/listings.js"),
  tasks: () => import("./views/tasks.js"), deals: () => import("./views/deals.js"), escrow: () => import("./views/escrow.js"),
  subscriptions: () => import("./views/subscriptions.js"), reports: () => import("./views/reports.js"), chats: () => import("./views/chats.js"),
  reviews: () => import("./views/reviews.js"), disputes: () => import("./views/disputes.js"), tickets: () => import("./views/tickets.js"),
  broadcast: () => import("./views/broadcast.js"), analytics: () => import("./views/analytics.js"), categories: () => import("./views/categories.js"),
  rules: () => import("./views/rules.js"), audit: () => import("./views/audit.js"), compliance: () => import("./views/compliance.js"),
};
const allowed = (rule) => (rule.includes("&") ? rule.split("&").every(ctx.can) : rule.split("|").some(ctx.can));
let items = [];

function parseRoute() {
  const [, name = "overview", arg = ""] = (location.hash || "").split("/");
  return { name, arg: decodeURIComponent(arg.split("?")[0]) };
}

function buildShell() {
  items = NAV.filter((n) => allowed(n[3]));
  const bd = (n) => (n[4] && Number(ctx.counts[n[4]]) ? `<span class="badge">${Number(ctx.counts[n[4]])}</span>` : "");
  const tabs = PRIMARY.map((k) => items.find((n) => n[0] === k)).filter(Boolean);
  let lastGroup = null;
  const side = items.map((n) => { const g = n[2] !== lastGroup && n[2] ? `<div class="grp">${esc(n[2])}</div>` : ""; lastGroup = n[2] || lastGroup; return `${g}<a href="#/${n[0]}" data-v="${n[0]}">${ICONS[n[0]]}<span>${esc(n[1])}</span>${bd(n)}</a>`; }).join("");
  const moreCount = items.filter((n) => !tabs.includes(n)).reduce((a, n) => a + (n[4] ? Number(ctx.counts[n[4]] || 0) : 0), 0);
  root.innerHTML = `<div class="app"><nav class="side" aria-label="Main"><div class="mark"><img src="${LOGO}" alt="">Seculate</div>${side}
    <div class="who"><b>${esc(ctx.access.role.replace("_", " "))}</b>${esc(ctx.email)}<a id="out" href="#" role="button">${ICONS.out}<span>Sign out</span></a></div></nav>
    <main id="main"><div class="mtop"><div class="mark"><img src="${LOGO}" alt="">Seculate</div><span class="pill n">${esc(ctx.access.role.replace("_", " "))}</span></div><div id="view"></div></main></div>
    <nav class="tabbar" aria-label="Main">${tabs.map((n) => `<a href="#/${n[0]}" data-v="${n[0]}">${ICONS[n[0]]}<span>${esc(n[1].split(" ")[0])}</span>${bd(n)}</a>`).join("")}
    <a id="more" href="#" role="button">${ICONS.more}<span>More</span>${moreCount ? `<span class="badge">${moreCount}</span>` : ""}</a></nav>`;
  const signOut = async (e) => { e?.preventDefault(); await sb.auth.signOut(); };
  $("#out").addEventListener("click", signOut);
  $("#more").addEventListener("click", (e) => {
    e.preventDefault();
    const m = modal(`<h2>Menu</h2><div class="menu">${items.filter((n) => !tabs.includes(n)).map((n) => `<a class="btn ghost" href="#/${n[0]}">${ICONS[n[0]]}<span>${esc(n[1])}</span>${bd(n)}</a>`).join("")}<a class="btn ghost out" href="#" id="mout">${ICONS.out}<span>Sign out</span></a></div>`);
    m.querySelectorAll("a[href^='#/']").forEach((a) => a.addEventListener("click", () => m.close()));
    m.querySelector("#mout").addEventListener("click", signOut);
  });
}
function markActive(name) {
  const nav = name === "user" ? "users" : name;
  $$("[data-v]").forEach((a) => { const on = a.dataset.v === nav; a.classList.toggle("on", on); if (on) a.setAttribute("aria-current", "page"); else a.removeAttribute("aria-current"); });
}

let seq = 0;
async function route() {
  if (!ctx.access) return;
  let { name, arg } = parseRoute();
  if (!LOADERS[name] || !items.find((n) => n[0] === name)) { name = items[0]?.[0] || "overview"; arg = ""; history.replaceState(null, "", `#/${name}`); }
  markActive(name); window.scrollTo(0, 0);
  const el = $("#view"); const my = ++seq;
  el.innerHTML = `<div class="skel"></div><div class="skel"></div><div class="skel"></div>`;
  try {
    const mod = await LOADERS[name]();
    if (my !== seq) return;
    el.innerHTML = ""; await mod.default(el, ctx, arg);
  } catch (e) { if (my === seq) el.innerHTML = `<div class="panel err" role="alert">${esc(e.message || e)}</div>`; }
}

async function refreshCounts() { try { ctx.counts = (await rpc("admin_overview")) || {}; } catch { /* keep old */ } }

// Sign out after 30 minutes without activity.
let idle; const IDLE_MS = 30 * 60 * 1000;
const bump = () => { clearTimeout(idle); idle = setTimeout(() => sb.auth.signOut(), IDLE_MS); };
["pointerdown", "keydown", "scroll", "touchstart"].forEach((ev) => window.addEventListener(ev, bump, { passive: true }));

// One delegated handler for every "copy" button.
document.addEventListener("click", async (e) => {
  const b = e.target.closest("[data-copy]"); if (!b) return;
  try { await navigator.clipboard.writeText(b.dataset.copy); toast("Copied."); } catch { toast("Couldn't copy. Select the text and copy it manually.", "bad"); }
});

async function start() {
  await ensureSignedIn(root, async ({ access, email, userId }) => {
    ctx.access = access; ctx.email = email; ctx.userId = userId;
    ctx.can = (p) => access.role === "super_admin" || (access.permissions || []).includes(p);
    await refreshCounts(); buildShell(); bump();
    if (!location.hash) history.replaceState(null, "", "#/" + (items[0]?.[0] || "overview"));
    route();
  });
}
window.addEventListener("hashchange", route);
function updateBadges() {
  items.forEach((n) => {
    if (!n[4]) return; const c = Number(ctx.counts[n[4]] || 0);
    $$(`[data-v="${n[0]}"]`).forEach((a) => { let b = a.querySelector(".badge"); if (c) { if (!b) { b = document.createElement("span"); b.className = "badge"; a.appendChild(b); } b.textContent = c; } else b?.remove(); });
  });
}
setInterval(async () => { if (ctx.access) { await refreshCounts(); updateBadges(); } }, 90000);
sb.auth.onAuthStateChange((ev) => { if (ev === "SIGNED_OUT") { ctx.access = null; clearTimeout(idle); loginView(root, start); } });
window.addEventListener("unhandledrejection", (e) => { fail(e.reason); });
start();
