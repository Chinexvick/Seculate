import { sb, rpc } from "./api.js";
import { $, esc } from "./ui.js";

const LOGO = "assets/logo-192.png";
const shellHtml = (inner) => `<div class="auth"><aside class="auth-art"><div class="mark on-dark"><span class="tile"><img src="${LOGO}" alt=""></span>Seculate</div>
  <div><h1>Run the marketplace with confidence.</h1><p>Look after members, settle escrow and resolve disputes in one place. Every action is recorded.</p></div>
  <small style="opacity:.7">Staff access only</small></aside>
  <section class="auth-form"><div class="auth-card">${inner}</div></section></div>`;
const brand = `<div class="mark"><img src="${LOGO}" alt="">Seculate Admin</div>`;

export function loginView(root, onDone, msg = "") {
  root.innerHTML = shellHtml(`<form id="lf" novalidate>${brand}<h1>Welcome back</h1><p class="mut">Sign in with your staff account.</p>
    <label for="e">Email</label><input id="e" name="email" type="email" autocomplete="username" autocapitalize="off" spellcheck="false" inputmode="email" required>
    <label for="p">Password</label><input id="p" name="password" type="password" autocomplete="current-password" required>
    <p class="err" role="alert">${esc(msg)}</p><button class="btn full" type="submit">Sign in</button></form>`);
  let busy = false;
  $("#lf").addEventListener("submit", async (ev) => {
    ev.preventDefault(); if (busy) return;
    const f = new FormData(ev.target); busy = true;
    const { error } = await sb.auth.signInWithPassword({ email: String(f.get("email")).trim(), password: String(f.get("password")) });
    busy = false;
    if (error) return loginView(root, onDone, "Invalid email or password.");
    onDone();
  });
}

function passwordView(root, onDone, msg = "") {
  root.innerHTML = shellHtml(`<form id="pf">${brand}<h1>Choose a new password</h1><p class="mut">Required on first sign-in. Use at least 12 characters.</p>
    <label for="np">New password</label><input id="np" name="p" type="password" autocomplete="new-password" minlength="12" required>
    <label for="nq">Repeat password</label><input id="nq" name="q" type="password" autocomplete="new-password" minlength="12" required>
    <p class="err" role="alert">${esc(msg)}</p><button class="btn full" type="submit">Save password</button></form>`);
  $("#pf").addEventListener("submit", async (ev) => {
    ev.preventDefault(); const f = new FormData(ev.target);
    if (f.get("p") !== f.get("q")) return passwordView(root, onDone, "Passwords don't match.");
    const { error } = await sb.auth.updateUser({ password: String(f.get("p")) });
    if (error) return passwordView(root, onDone, error.message);
    const { data: { session } } = await sb.auth.getSession();
    await sb.from("profiles").update({ must_change_password: false }).eq("id", session.user.id);
    onDone();
  });
}

async function mfaView(root, onDone, enrolled) {
  const verify = async (ev, factorId) => {
    ev.preventDefault();
    const code = String(new FormData(ev.target).get("c")).replace(/\s/g, "");
    const { data: ch, error: e1 } = await sb.auth.mfa.challenge({ factorId });
    if (e1) return ($("#me").textContent = e1.message);
    const { error } = await sb.auth.mfa.verify({ factorId, challengeId: ch.id, code });
    if (error) return ($("#me").textContent = "That code didn't work. Try the newest one.");
    onDone();
  };
  if (!enrolled) {
    const { data, error } = await sb.auth.mfa.enroll({ factorType: "totp", friendlyName: "Seculate admin " + Date.now() });
    if (error) return loginView(root, onDone, error.message);
    root.innerHTML = shellHtml(`<form id="mf">${brand}<h1>Set up 2-step verification</h1>
      <p class="mut">Scan this code with Google Authenticator, Authy or 1Password, then enter the 6-digit code it shows.</p>
      <div style="text-align:center;margin:14px 0"><img alt="QR code" width="176" height="176" style="border:1.5px solid var(--line2);border-radius:16px;padding:8px" src="${esc(data.totp.qr_code)}"></div>
      <p class="mut" style="word-break:break-all;font-size:12px">Can't scan? Enter this key: <b>${esc(data.totp.secret)}</b></p>
      <label for="c">6-digit code</label><input id="c" name="c" inputmode="numeric" maxlength="7" autocomplete="one-time-code" required><p class="err" id="me" role="alert"></p><button class="btn full" type="submit">Verify and continue</button></form>`);
    $("#mf").addEventListener("submit", (ev) => verify(ev, data.id));
  } else {
    const { data } = await sb.auth.mfa.listFactors();
    const fac = data.totp.find((f) => f.status === "verified");
    root.innerHTML = shellHtml(`<form id="mf">${brand}<h1>Enter your code</h1><p class="mut">Open your authenticator app and type the current 6-digit code.</p>
      <label for="c">6-digit code</label><input id="c" name="c" inputmode="numeric" maxlength="7" autocomplete="one-time-code" required><p class="err" id="me" role="alert"></p><button class="btn full" type="submit">Continue</button></form>`);
    $("#mf").addEventListener("submit", (ev) => verify(ev, fac.id)); $("#c").focus();
  }
}

// Resolves to {access, email, userId} once the person is fully signed in (password + 2-step code), or renders the next step.
export async function ensureSignedIn(root, onReady) {
  const again = () => ensureSignedIn(root, onReady);
  const { data: { session } } = await sb.auth.getSession();
  if (!session) return loginView(root, again);
  let acc = null; try { acc = await rpc("my_staff_access"); } catch { acc = null; }
  if (!acc) { await sb.auth.signOut(); return loginView(root, again, "This account does not have staff access."); }
  const { data: prof } = await sb.from("profiles").select("must_change_password").eq("id", session.user.id).maybeSingle();
  if (prof?.must_change_password) return passwordView(root, again);
  const { data: aal } = await sb.auth.mfa.getAuthenticatorAssuranceLevel();
  if (aal.currentLevel !== "aal2") return mfaView(root, again, aal.nextLevel === "aal2");
  onReady({ access: acc, email: session.user.email || "", userId: session.user.id });
}
