// Branded Seculate email templates + provider-agnostic sender (SMTP or Resend).
// Secrets (set in Supabase > Edge Functions > Secrets, never in code):
//   SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM   (or)   RESEND_API_KEY, SMTP_FROM
import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts";
import { env } from "./vault.ts";

const GREEN = "#00C532";
const GREEN_DARK = "#008A23";
const INK = "#121212";
const MUTED = "#6B788E";
const SITE = env("SITE_URL") ?? "https://seculate.ng";
const LOGO = env("EMAIL_LOGO_URL") ?? "https://seculate-admin.vercel.app/assets/logo-192.png";

export type Mail = { subject: string; html: string; text: string };

const esc = (s: string) =>
  s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

function layout(opts: { preheader: string; title: string; body: string; cta?: { label: string; url: string }; footnote?: string }) {
  const cta = opts.cta
    ? `<tr><td align="center" style="padding:8px 0 4px"><a href="${esc(opts.cta.url)}" style="background:${GREEN};color:#fff;text-decoration:none;font-weight:600;font-size:15px;padding:14px 32px;border-radius:16px 5px 16px 5px;display:inline-block">${esc(opts.cta.label)}</a></td></tr>`
    : "";
  return `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="color-scheme" content="light only"><title>${esc(opts.title)}</title></head>
<body style="margin:0;padding:0;background:#F1F4F2;font-family:'Poppins',-apple-system,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:${INK}">
<div style="display:none;max-height:0;overflow:hidden;opacity:0;color:transparent">${esc(opts.preheader)}</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#F1F4F2"><tr><td align="center" style="padding:32px 16px">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px">
 <tr><td align="center" style="padding-bottom:20px">
   <table role="presentation" cellpadding="0" cellspacing="0"><tr>
     <td><img src="${LOGO}" width="44" height="44" alt="Seculate" style="display:block;border:0"></td>
     <td style="padding-left:10px;font-size:24px;font-weight:700;color:${INK};letter-spacing:-0.3px">Seculate</td>
   </tr></table>
 </td></tr>
 <tr><td style="background:#fff;border-radius:28px 8px 28px 8px;padding:0;box-shadow:0 4px 24px rgba(18,18,18,.06);overflow:hidden">
   <div style="height:6px;background:${GREEN};background-image:linear-gradient(90deg,#2BCF55,${GREEN_DARK});line-height:6px;font-size:0">&nbsp;</div>
   <div style="padding:34px 32px 32px">
   <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
     <tr><td style="font-size:22px;font-weight:600;color:${INK};padding-bottom:12px">${esc(opts.title)}</td></tr>
     <tr><td style="font-size:15px;line-height:24px;color:#3A4350;padding-bottom:20px">${opts.body}</td></tr>
     ${cta}
   </table>
   ${opts.footnote ? `<div style="margin-top:20px;padding-top:16px;border-top:1px solid #E7EBEF;font-size:12px;line-height:19px;color:${MUTED}">${opts.footnote}</div>` : ""}
   </div>
 </td></tr>
 <tr><td align="center" style="padding:22px 12px 0;font-size:12px;line-height:19px;color:${MUTED}">
   Own it for as long as you need it.<br>
   Seculate never asks for your password, PIN or verification code by phone, chat or email.<br>
   &copy; ${new Date().getFullYear()} Seculate. All rights reserved.
 </td></tr>
</table></td></tr></table></body></html>`.replace(/\s*\n\s*/g, "");
}

const PURPOSE_COPY: Record<string, { title: string; intro: string; subject: string }> = {
  signup: { title: "Verify your email", intro: "Welcome to Seculate! Enter this code in the app to verify your email and finish creating your account.", subject: "Your Seculate verification code" },
  recovery: { title: "Reset your password", intro: "We received a request to reset your Seculate password. Enter this code in the app to continue.", subject: "Your Seculate password reset code" },
  login: { title: "Your sign-in code", intro: "Use this code to sign in to Seculate.", subject: "Your Seculate sign-in code" },
  email_change: { title: "Confirm your new email", intro: "Enter this code in the app to confirm your new email address.", subject: "Confirm your new Seculate email" },
};

export function otpEmail(code: string, purpose: string, minutes = 10): Mail {
  const c = PURPOSE_COPY[purpose] ?? PURPOSE_COPY.signup;
  const boxes = code.split("").map((d) =>
    `<td style="padding:0 2px"><div style="width:38px;height:50px;line-height:50px;text-align:center;font-size:24px;font-weight:700;color:${GREEN_DARK};background:#F3FBF5;border:2px solid #BDEBC8;border-radius:10px 3px 10px 3px">${esc(d)}</div></td>`).join("");
  const body = `${esc(c.intro)}
   <table role="presentation" align="center" cellpadding="0" cellspacing="0" style="margin:26px auto 8px"><tr>${boxes}</tr></table>
   <div style="text-align:center;font-size:14px;color:${INK};margin-top:4px">Easy copy: <span style="font-weight:700;letter-spacing:3px;color:${GREEN_DARK};-webkit-user-select:all;user-select:all">${esc(code)}</span></div>
   <div style="text-align:center;font-size:13px;color:${MUTED};margin-top:6px">Press and hold the code above, tap Copy, then tap “Paste code” in the app.</div>
   <div style="text-align:center;font-size:13px;color:${MUTED};margin-top:6px">This code expires in <b>${minutes} minutes</b> and can be used once.</div>`;
  return {
    subject: `${code} is ${c.subject.replace("Your ", "your ")}`,
    html: layout({
      preheader: `${code} is your Seculate code. It expires in ${minutes} minutes.`,
      title: c.title, body,
      footnote: "Didn’t request this? You can safely ignore this email — your account stays protected. If you keep getting these, change your password or contact support in the app.",
    }),
    text: `${c.title}\n\n${c.intro}\n\nYour code: ${code}\nIt expires in ${minutes} minutes. Never share it with anyone.\n\n— Seculate`,
  };
}


// Status badge shown above event copy (success = green, problem = red, waiting = amber). Layout CSS is untouched.
function badge(kind: "ok" | "bad" | "wait", icon: string) {
  const c = { ok: ["#F3FBF5", "#BDEBC8"], bad: ["#FFF3F2", "#F6C4BF"], wait: ["#FFF9EC", "#F3DDA6"] }[kind];
  return `<div style="text-align:center;margin:2px 0 18px"><div style="display:inline-block;width:64px;height:64px;line-height:64px;font-size:30px;text-align:center;background:${c[0]};border:2px solid ${c[1]};border-radius:22px 6px 22px 6px">${icon}</div></div>`;
}
function amountCard(label: string, value?: string) {
  return value ? `<div style="margin:16px 0 4px;padding:14px 18px;background:#F7F9F8;border:1px solid #E7EBEF;border-radius:14px 4px 14px 4px;text-align:center"><div style="font-size:12px;color:${MUTED};letter-spacing:.6px;text-transform:uppercase">${esc(label)}</div><div style="font-size:26px;font-weight:700;color:${INK};margin-top:2px">${esc(value)}</div></div>` : "";
}

type Vars = Record<string, string | undefined>;
export function eventEmail(kind: string, v: Vars = {}): Mail {
  const name = esc(v.name ?? "there");
  const open = { label: "Open Seculate", url: v.url ?? SITE };
  const t: Record<string, { subject: string; title: string; body: string; cta?: boolean }> = {
    welcome: { subject: "Welcome to Seculate", title: `Welcome, ${name}!`, body: "Your account is ready. Borrow what you need, lend what you own, or offer your skills to people around you — all protected by escrow.", cta: true },
    listing_approved: { subject: "Your listing is live", title: "Your listing is live", body: `Good news, ${name} — <b>${esc(v.item ?? "your listing")}</b> was approved and is now visible to people near you.`, cta: true },
    listing_rejected: { subject: "Your listing needs changes", title: "Your listing was not approved", body: `Hi ${name}, <b>${esc(v.item ?? "your listing")}</b> wasn’t approved.<br><br><b>Reason:</b> ${esc(v.reason ?? "See the app for details.")}<br><br>You can edit it and submit it again.`, cta: true },
    payment_success: { subject: "Payment received", title: "Payment successful", body: `We received your payment of <b>${esc(v.amount ?? "")}</b>. Funds are held safely in escrow until the transaction is completed.`, cta: true },
    subscription_active: { subject: "Your plan is active", title: "Your plan is active", body: `Thanks ${name}! Your <b>${esc(v.plan ?? "")}</b> plan is now active${v.until ? ` until ${esc(v.until)}` : ""}.`, cta: true },
    dispute_opened: { subject: "A problem was reported on your transaction", title: "A problem was reported", body: `A dispute was opened on <b>${esc(v.item ?? "your transaction")}</b>. Funds stay protected while our team reviews it. You can add your evidence in the app.`, cta: true },
    security_alert: { subject: "Security alert on your Seculate account", title: "New sign-in to your account", body: `We noticed a sign-in${v.device ? ` from <b>${esc(v.device)}</b>` : ""}. If this was you, no action is needed. If not, change your password right away.`, cta: true },
    account_suspended: { subject: "Your Seculate account was suspended", title: "Account suspended", body: `Hi ${name}, your account has been suspended${v.reason ? `: ${esc(v.reason)}` : ""}. Our team will review it. You can contact support from the app.` },
    password_changed: { subject: "Your password was changed", title: "Password changed", body: "Your Seculate password was just changed. If this wasn’t you, reset it immediately and contact support." },
    product_approved: { subject: "Your item is approved 🎉", title: "Congratulations, your item is live", body: `Great news, ${name}! <b>${esc(v.item ?? "Your item")}</b> has been approved and is now visible to people near you. We’ll email you as soon as someone shows interest.`, cta: true },
    service_approved: { subject: "Your service is approved 🎉", title: "Congratulations, your service is live", body: `Great news, ${name}! Your service <b>${esc(v.item ?? "")}</b> has been approved and can now be found by people near you. We’ll email you when someone is interested.`, cta: true },
    errand_approved: { subject: "Your errand is approved 🎉", title: "Congratulations, your errand is live", body: `Great news, ${name}! Your errand <b>${esc(v.item ?? "")}</b> has been approved and is now open for people nearby to take on. We’ll email you when someone makes an offer.`, cta: true },
    changes_requested: { subject: "Changes needed on your post", title: "A few changes are needed", body: `Hi ${name}, our team reviewed <b>${esc(v.item ?? "your post")}</b> and needs a few changes before it can go live.<br><br><b>What to fix:</b> ${esc(v.reason ?? "See the app for details.")}<br><br>Update it in the app and send it back for review.`, cta: true },
    errand_rejected: { subject: "Your errand wasn’t approved", title: "Your errand was not approved", body: `Hi ${name}, <b>${esc(v.item ?? "your errand")}</b> wasn’t approved.<br><br><b>Reason:</b> ${esc(v.reason ?? "See the app for details.")}`, cta: true },
    interest_item: { subject: "Someone wants to borrow your item", title: "You have a new request", body: `Hi ${name}, ${esc(v.from ?? "someone")} is interested in <b>${esc(v.item ?? "your item")}</b>. Open the app to review the request and accept or decline it.`, cta: true },
    listing_available: { subject: "An item you wanted is available", title: "It's available again", body: `Hi ${name}, <b>${esc(v.item ?? "an item you were watching")}</b> is available to borrow again. Open the app to request it before someone else does.`, cta: true },
    request_approved: { subject: "Your request is live", title: "Your request was approved", body: `Hi ${name}, your request for <b>${esc(v.item ?? "your item")}</b> is now visible to lenders near you. We'll let you know when offers come in.`, cta: true },
    request_new_bid: { subject: "You have a new offer", title: "Someone can lend what you need", body: `Hi ${name}, a lender made an offer on your request. Open the app to accept, counter or decline it.`, cta: true },
    interest_errand: { subject: "New offer on your errand", title: "You have a new offer", body: `Hi ${name}, you received an offer${v.amount ? ` of <b>${esc(v.amount)}</b>` : ""} on your errand <b>${esc(v.item ?? "")}</b>. Open the app to accept, counter or decline.`, cta: true },
    counter_offer: { subject: "You have a counter offer", title: "A counter offer is waiting", body: `Hi ${name}, there is a counter offer${v.amount ? ` of <b>${esc(v.amount)}</b>` : ""} on <b>${esc(v.item ?? "your post")}</b>. Open the app to respond.`, cta: true },
    new_message: { subject: "You have a new message", title: "New message", body: `Hi ${name}, ${esc(v.from ?? "someone")} sent you a message on Seculate. Open the app to read and reply.`, cta: true },
    offer_accepted: { subject: "Your request was accepted", title: "Good news, it was accepted", body: `Hi ${name}, your request for <b>${esc(v.item ?? "")}</b> was accepted. Pay in the app to secure it. Your money stays in escrow until everything is done.`, cta: true },
    offer_rejected: { subject: "Your offer wasn’t accepted", title: "Offer not accepted", body: `Hi ${name}, your offer on <b>${esc(v.item ?? "")}</b> wasn’t accepted this time. There are plenty of other posts near you.`, cta: true },
    escrow_funded: { subject: "Payment secured in escrow", title: "Payment is in escrow", body: `Hi ${name}, the payment for <b>${esc(v.item ?? "your transaction")}</b> is now held safely in escrow. You can go ahead with the handover.`, cta: true },
    return_requested: { subject: "Return confirmation needed", title: "Please confirm the return", body: `Hi ${name}, a return was submitted for <b>${esc(v.item ?? "your transaction")}</b>. Open the app to check it and confirm.`, cta: true },
    refund: { subject: "Your refund is on its way", title: "Refund issued", body: `Hi ${name}, a refund${v.item ? ` for <b>${esc(v.item)}</b>` : ""} has been issued. It can take a little while to reach your bank.`, cta: true },
    review_received: { subject: "You received a new review", title: "New review", body: `Hi ${name}, someone left you a review. Open the app to see what they said.`, cta: true },
    support_reply: { subject: "Support replied to your ticket", title: "Support has replied", body: `Hi ${name}, our team replied to your ticket:<br><br><i>${esc(v.message ?? "")}</i><br><br>Open the app to continue the conversation.`, cta: true },
    account_warning: { subject: "An update on your Seculate account", title: "Account update", body: `Hi ${name}, ${esc(v.message ?? "our team reviewed your account.")}`, cta: true },
    topup_success: { subject: "Your wallet top-up was successful", title: "Wallet topped up", body: `${badge("ok", "💳")}Hi ${name}, your top-up went through and the money is now in your Seculate wallet.${amountCard("Added to wallet", v.amount)}<br>Open the app to see your balance.`, cta: true },
    credits_added: { subject: "Your credits were added", title: "Credits added", body: `${badge("ok", "🪙")}Hi ${name}, ${esc(v.message ?? "your credits were added to your balance.")}<br><br>Use them to post item requests and unlock offers.`, cta: true },
    payment_failed: { subject: "Your payment didn’t go through", title: "Payment failed", body: `${badge("bad", "⚠️")}Hi ${name}, ${esc(v.message ?? "your payment did not go through.")}<br><br>You can try again from the app. If money left your account, it is returned automatically by your bank.`, cta: true },
    verification_success: { subject: "You’re verified on Seculate", title: "Identity verified", body: `${badge("ok", "✅")}Congratulations ${name}! Your identity has been verified. Your profile now carries a verified badge, and you can withdraw from your wallet and pay through escrow.`, cta: true },
    verification_rejected: { subject: "We couldn’t verify your identity", title: "Verification not approved", body: `${badge("bad", "🚫")}Hi ${name}, we couldn’t verify your identity.<br><br><b>Why:</b> ${esc(v.message ?? "The details did not match.")}<br><br>Check your details, use good light, and try again from your profile.`, cta: true },
    verification_pending: { subject: "We’re reviewing your identity details", title: "Verification in review", body: `${badge("wait", "⏳")}Hi ${name}, we received your identity details. Our team is reviewing them and we’ll email you the result.`, cta: true },
    withdrawal_success: { subject: "Your withdrawal is on its way", title: "Withdrawal sent", body: `${badge("ok", "🏦")}Hi ${name}, ${esc(v.message ?? "your withdrawal was sent to your bank.")}<br><br>Banks can take a few minutes to show it.`, cta: true },
    withdrawal_failed: { subject: "Your withdrawal didn’t complete", title: "Withdrawal failed", body: `${badge("bad", "⚠️")}Hi ${name}, ${esc(v.message ?? "your withdrawal could not be completed.")}`, cta: true },
    certificate_issued: { subject: "Your Seculate certificate is ready", title: "Certificate issued", body: `${badge("ok", "📜")}Hi ${name}, ${esc(v.message ?? "a certificate was issued for your completed transaction.")}<br><br>You can view and share it from the app.`, cta: true },
    dispute_due: { subject: "Reminder: respond to the reported problem", title: "A response is due soon", body: `${badge("wait", "⏰")}Hi ${name}, ${esc(v.message ?? "a reported problem is waiting for your response.")}`, cta: true },
    dispute_updated: { subject: "Update on the reported problem", title: "Problem report updated", body: `${badge("wait", "🛡️")}Hi ${name}, ${esc(v.message ?? "there is an update on the problem report.")}`, cta: true },
    payment_window_expired: { subject: "The payment window closed", title: "Payment window expired", body: `${badge("bad", "⌛")}Hi ${name}, ${esc(v.message ?? "the time to pay for this transaction ran out, so it was cancelled.")}`, cta: true },
    request_changes: { subject: "Changes needed on your request", title: "A few changes are needed", body: `${badge("wait", "✏️")}Hi ${name}, ${esc(v.message ?? "your item request needs a few changes before it can go live.")}`, cta: true },
    request_rejected: { subject: "Your request wasn’t approved", title: "Request not approved", body: `${badge("bad", "🚫")}Hi ${name}, ${esc(v.message ?? "your item request wasn’t approved.")}`, cta: true },
    request_reopened: { subject: "Your request is open again", title: "Back in the feed", body: `${badge("ok", "🔁")}Hi ${name}, ${esc(v.message ?? "your item request is open again so lenders can make new offers.")}`, cta: true },
    return_overdue: { subject: "A return is overdue", title: "Return overdue", body: `${badge("bad", "⏰")}Hi ${name}, ${esc(v.message ?? "a return is overdue.")} Please sort it out in the app.`, cta: true },
    bid_accepted: { subject: "Your offer was accepted", title: "Your offer was accepted", body: `${badge("ok", "🤝")}Hi ${name}, ${esc(v.message ?? "your offer on an item request was accepted.")}`, cta: true },
    bid_rejected: { subject: "Your offer wasn’t accepted", title: "Offer not accepted", body: `${badge("bad", "✖️")}Hi ${name}, ${esc(v.message ?? "your offer wasn’t accepted this time.")}`, cta: true },
    announcement: { subject: v.title ?? "News from Seculate", title: v.title ?? "News from Seculate", body: esc(v.message ?? ""), cta: true },
  };
  const e = t[kind] ?? { subject: "Seculate update", title: "Update", body: esc(v.message ?? "") };
  return {
    subject: e.subject,
    html: layout({ preheader: e.subject, title: e.title, body: e.body, cta: e.cta ? open : undefined }),
    text: `${e.title}\n\n${e.body.replace(/<[^>]+>/g, "")}\n\n— Seculate`,
  };
}

export function providerConfigured(): boolean {
  return !!(env("SMTP_HOST") || env("RESEND_API_KEY"));
}

export async function sendEmail(to: string, mail: Mail): Promise<void> {
  const from = env("SMTP_FROM") ?? "Seculate <info@seculate.ng>";
  const host = env("SMTP_HOST");
  if (host) {
    const port = Number(env("SMTP_PORT") ?? "465");
    const client = new SMTPClient({
      connection: { hostname: host, port, tls: port === 465, auth: { username: env("SMTP_USER") ?? "", password: env("SMTP_PASS") ?? "" } },
    });
    try { await client.send({ from, to, subject: mail.subject, content: mail.text, html: mail.html }); } finally { await client.close(); }
    return;
  }
  const key = env("RESEND_API_KEY");
  if (key) {
    const r = await fetch("https://api.resend.com/emails", {
      method: "POST", headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
      body: JSON.stringify({ from, to, subject: mail.subject, html: mail.html, text: mail.text }),
    });
    if (!r.ok) throw new Error(`Email provider error ${r.status}`);
    return;
  }
  throw new Error("NO_EMAIL_PROVIDER");
}
