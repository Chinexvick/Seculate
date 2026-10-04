import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { env } from "./vault.ts";
import { caller, cors, ep, EscrowError, escrowConfigured, json, minor } from "./_escrow.ts";

// Starts a payment. The amount is ALWAYS computed here from database rows; the
// app only sends which transaction / plan it wants to pay for.
//  - purpose "escrow": EscrowPay holds the money until the borrow/task is done.
//  - purpose "subscription": Flutterwave hosted checkout (card/bank/USSD).
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  const { db, uid, email } = await caller(req);
  if (!uid) return json({ error: "Please log in again." }, 401);
  let body: any;
  try { body = await req.json(); } catch { return json({ error: "Invalid request" }, 400); }

  try {
    if (body.purpose === "escrow") return await escrowPayment(db, uid, String(body.transaction_id ?? ""));
    if (body.purpose === "subscription") return await subscriptionPayment(db, uid, email, String(body.plan_id ?? ""));
    if (body.purpose === "subscription_sync") return await subscriptionSync(db, uid, "subscription");
    if (body.purpose === "credits") return await creditsPayment(db, uid, email, String(body.bundle_id ?? ""));
    if (body.purpose === "credits_sync") return await subscriptionSync(db, uid, "credits");
    if (body.purpose === "topup") return await topupPayment(db, uid, email, Number(body.amount));
    if (body.purpose === "topup_sync") return await subscriptionSync(db, uid, "topup");
    return json({ error: "Invalid request" }, 400);
  } catch (e) {
    if (e instanceof EscrowError) return json({ error: e.status === 503 ? "Payments aren't switched on yet." : e.message, code: e.code }, e.status === 503 ? 503 : 502);
    console.error("payment-init failed", String(e));
    return json({ error: "Something went wrong. Please try again." }, 500);
  }
});

// Landing pages live on the pay subdomain, one per outcome. Flutterwave appends
// status / tx_ref / transaction_id to this URL when it redirects back.
function payUrl(page: string, q: Record<string, string> = {}) {
  let origin = "https://pay.seculate.ng";
  try { origin = new URL(env("PAYMENT_REDIRECT_URL") ?? origin).origin; } catch { /* keep default */ }
  const qs = new URLSearchParams(q).toString();
  return `${origin}/${page}${qs ? `?${qs}` : ""}`;
}

async function topupPayment(db: any, uid: string, email: string | null, amount: number) {
  const key = env("FLW_SECRET_KEY");
  if (!key) return json({ error: "Payments aren't switched on yet.", code: "not_configured" }, 503);
  const { data: st } = await db.from("app_settings").select("value").eq("key", "wallet").maybeSingle();
  const min = Number(st?.value?.min_topup ?? 100), max = Number(st?.value?.max_topup ?? 10000000);
  if (!Number.isFinite(amount) || !Number.isInteger(amount) || amount < min || amount > max)
    return json({ error: `Enter a whole amount between ₦${min.toLocaleString("en-NG")} and ₦${max.toLocaleString("en-NG")}.` }, 400);
  const { data: prof } = await db.from("profiles").select("first_name,last_name,phone,account_status").eq("id", uid).maybeSingle();
  if (prof?.account_status && prof.account_status !== "active") return json({ error: "Your account is restricted." }, 403);
  const txRef = `top_${uid.replaceAll("-", "").slice(0, 12)}_${Date.now().toString(36)}`;
  const { error } = await db.from("payments").insert({ user_id: uid, purpose: "topup", tx_ref: txRef, amount, currency: "NGN", status: "pending", raw: { provider: "flutterwave" } });
  if (error) { console.error("topup insert", error.message); return json({ error: "Could not start the payment." }, 500); }
  const r = await fetch("https://api.flutterwave.com/v3/payments", {
    method: "POST",
    headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      tx_ref: txRef, amount, currency: "NGN", redirect_url: payUrl("wallet-topped-up", { amount: String(amount) }),
      customer: { email: email ?? "", name: `${prof?.first_name ?? ""} ${prof?.last_name ?? ""}`.trim() || "Seculate user", phonenumber: prof?.phone ?? undefined },
      customizations: { title: "Seculate", description: "Wallet top-up" },
      meta: { user_id: uid, purpose: "topup" },
    }),
  });
  const j = await r.json().catch(() => ({}));
  if (!r.ok || !j?.data?.link) { console.error("flutterwave init", r.status, JSON.stringify(j).slice(0, 300)); return json({ error: "The payment provider is unavailable. Try again shortly." }, 502); }
  return json({ ok: true, link: j.data.link, tx_ref: txRef, amount, provider: "flutterwave" });
}

async function escrowPayment(db: any, uid: string, txId: string) {
  if (!escrowConfigured()) return json({ error: "Payments aren't switched on yet.", code: "not_configured" }, 503);
  const { data: t } = await db.from("transactions").select("*").eq("id", txId).maybeSingle();
  if (!t) return json({ error: "Transaction not found." }, 404);
  if (t.payer_id !== uid) return json({ error: "Only the person paying can start this payment." }, 403);
  if (!["accepted", "payment_pending"].includes(t.state)) return json({ error: "This transaction isn't waiting for payment." }, 409);

  // Both people must be identity-verified: they become escrow "parties".
  const { data: recs } = await db.from("verification_records").select("user_id, provider_ref").in("user_id", [t.payer_id, t.payee_id]).eq("provider", "escrowpay").eq("status", "verified");
  const party = (id: string) => recs?.find((r: any) => r.user_id === id)?.provider_ref as string | undefined;
  const payerParty = party(t.payer_id), payeeParty = party(t.payee_id);
  if (!payerParty) return json({ error: "Verify your identity (NIN) in your profile before paying.", code: "identity_required", who: "self" }, 428);
  if (!payeeParty) return json({ error: "The other person hasn't verified their identity yet, so payment isn't available.", code: "identity_required", who: "other" }, 428);

  const total = Number(t.amount) + Number(t.collateral) + Number(t.platform_fee ?? 0);
  if (!(total > 0)) return json({ error: "Invalid amount." }, 409);

  if (t.state === "accepted") await db.rpc("tx_move", { p_tx: t.id, p_to: "payment_pending", p_note: "Awaiting payment" });

  // Reuse the provider transaction if one already exists for this payment.
  const { data: existing } = await db.from("payments").select("*").eq("transaction_id", t.id).eq("purpose", "transaction").eq("status", "pending").order("created_at", { ascending: false }).limit(1).maybeSingle();
  let escrowTxn: string | undefined = existing?.flw_transaction_id ?? undefined;
  let txRef: string = existing?.tx_ref;

  if (!escrowTxn) {
    txRef = `sec_${t.id.replaceAll("-", "").slice(0, 16)}_${Date.now().toString(36)}`;
    const created = await ep("POST", "/api/v1/transactions", {
      type: "standard", amount_minor: minor(total), currency: "NGN", funding_mode: "exact",
      payer: { party_id: payerParty }, beneficiary: { party_id: payeeParty },
      release_policy: "manual_only", refund_policy: "manual_only", payout_preference: "retain_in_wallet",
      external_reference: txRef, description: String(t.title ?? "Seculate transaction").slice(0, 200),
      metadata: { app: "seculate", transaction_id: t.id },
    }, `create_${t.id}_${txRef}`);
    await ep("POST", `/api/v1/transactions/${created.id}/activate`, { version: created.version ?? 1 }, `activate_${created.id}`);
    escrowTxn = created.id;
    const { error } = await db.from("payments").insert({ user_id: uid, purpose: "transaction", tx_ref: txRef, amount: total, currency: "NGN", status: "pending", transaction_id: t.id, flw_transaction_id: escrowTxn, raw: { provider: "escrowpay" } });
    if (error) { console.error("payments insert", error.message); return json({ error: "Could not start the payment." }, 500); }
  }

  const session = await ep("POST", `/api/v1/transactions/${escrowTxn}/checkout-sessions`, {}, `session_${escrowTxn}_${Date.now()}`);
  return json({ ok: true, link: session.hosted_url, tx_ref: txRef, amount: total, provider: "escrowpay" });
}

async function subscriptionPayment(db: any, uid: string, email: string | null, planId: string) {
  const key = env("FLW_SECRET_KEY");
  if (!key) return json({ error: "Payments aren't switched on yet.", code: "not_configured" }, 503);
  const { data: plan } = await db.from("subscription_plans").select("*").eq("id", planId).eq("is_active", true).maybeSingle();
  if (!plan || Number(plan.price_ngn) <= 0) return json({ error: "That plan can't be purchased." }, 400);
  const { data: prof } = await db.from("profiles").select("first_name,last_name,phone").eq("id", uid).maybeSingle();
  const txRef = `sub_${uid.replaceAll("-", "").slice(0, 12)}_${planId}_${Date.now().toString(36)}`;
  const { error } = await db.from("payments").insert({ user_id: uid, purpose: "subscription", tx_ref: txRef, amount: plan.price_ngn, currency: "NGN", status: "pending", plan_id: planId, raw: { provider: "flutterwave" } });
  if (error) return json({ error: "Could not start the payment." }, 500);
  const r = await fetch("https://api.flutterwave.com/v3/payments", {
    method: "POST",
    headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      tx_ref: txRef, amount: Number(plan.price_ngn), currency: "NGN",
      redirect_url: payUrl("subscribed", { plan: String(plan.name) }),
      customer: { email: email ?? "", name: `${prof?.first_name ?? ""} ${prof?.last_name ?? ""}`.trim() || "Seculate user", phonenumber: prof?.phone ?? undefined },
      customizations: { title: "Seculate", description: `${plan.name} plan (30 days)` },
      meta: { user_id: uid, plan_id: planId },
    }),
  });
  const j = await r.json().catch(() => ({}));
  if (!r.ok || !j?.data?.link) { console.error("flutterwave init", r.status, JSON.stringify(j).slice(0, 300)); return json({ error: "The payment provider is unavailable. Try again shortly." }, 502); }
  return json({ ok: true, link: j.data.link, tx_ref: txRef, amount: Number(plan.price_ngn), provider: "flutterwave" });
}

// Fallback when the Flutterwave webhook is slow or not set up: the app asks us to
// look up the user's newest pending plan payment by reference and, if Flutterwave
// says it was paid, apply it (server_mark_paid re-checks the amount).
async function subscriptionSync(db: any, uid: string, purpose: string) {
  const key = env("FLW_SECRET_KEY");
  if (!key) return json({ ok: true, applied: false });
  const { data: pay } = await db.from("payments").select("*").eq("user_id", uid).eq("purpose", purpose).eq("status", "pending").order("created_at", { ascending: false }).limit(1).maybeSingle();
  if (!pay) return json({ ok: true, applied: false });
  const r = await fetch(`https://api.flutterwave.com/v3/transactions/verify_by_reference?tx_ref=${encodeURIComponent(pay.tx_ref)}`, { headers: { Authorization: `Bearer ${key}` } });
  const v = await r.json().catch(() => ({}));
  const t = v?.data;
  if (!r.ok || !t || t.status !== "successful" || t.tx_ref !== pay.tx_ref || t.currency !== "NGN") return json({ ok: true, applied: false });
  const { error } = await db.rpc("server_mark_paid", { p_tx_ref: pay.tx_ref, p_flw_id: String(t.id), p_amount: Number(t.amount) });
  if (error) { console.error("subscription sync", error.message); return json({ ok: false, error: "Could not apply the payment yet." }, 500); }
  return json({ ok: true, applied: true });
}

async function creditsPayment(db: any, uid: string, email: string | null, bundleId: string) {
  const key = env("FLW_SECRET_KEY");
  if (!key) return json({ error: "Payments aren't switched on yet.", code: "not_configured" }, 503);
  const { data: b } = await db.from("credit_bundles").select("*").eq("id", bundleId).eq("is_active", true).maybeSingle();
  if (!b || Number(b.price_ngn) <= 0) return json({ error: "That credit bundle isn't available." }, 400);
  const { data: prof } = await db.from("profiles").select("first_name,last_name,phone").eq("id", uid).maybeSingle();
  const txRef = `cr_${uid.replaceAll("-", "").slice(0, 12)}_${Date.now().toString(36)}`;
  const { error } = await db.from("payments").insert({ user_id: uid, purpose: "credits", tx_ref: txRef, amount: b.price_ngn, currency: "NGN", status: "pending", bundle_id: b.id, raw: { provider: "flutterwave" } });
  if (error) { console.error("credits insert", error.message); return json({ error: "Could not start the payment." }, 500); }
  const r = await fetch("https://api.flutterwave.com/v3/payments", {
    method: "POST",
    headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      tx_ref: txRef, amount: Number(b.price_ngn), currency: "NGN",
      redirect_url: payUrl("credits-added", { credits: String(b.credits) }),
      customer: { email: email ?? "", name: `${prof?.first_name ?? ""} ${prof?.last_name ?? ""}`.trim() || "Seculate user", phonenumber: prof?.phone ?? undefined },
      customizations: { title: "Seculate", description: `${b.credits} credits` },
      meta: { user_id: uid, bundle_id: b.id },
    }),
  });
  const j = await r.json().catch(() => ({}));
  if (!r.ok || !j?.data?.link) { console.error("flutterwave init", r.status, JSON.stringify(j).slice(0, 300)); return json({ error: "The payment provider is unavailable. Try again shortly." }, 502); }
  return json({ ok: true, link: j.data.link, tx_ref: txRef, amount: Number(b.price_ngn), provider: "flutterwave" });
}
