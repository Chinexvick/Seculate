import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { env } from "./vault.ts";
import { caller, cors, json } from "./_escrow.ts";

// Wallet withdrawals. The wallet debit, limits and identity check all happen in the
// database (server_wallet_request_withdrawal); the Flutterwave key never leaves here.
//  action "banks"    -> list of Nigerian banks
//  action "resolve"  -> account name for bank + account number
//  action "withdraw" -> debit wallet, start transfer; webhook finalises (or refunds)
const FLW = "https://api.flutterwave.com/v3";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  const { db, uid } = await caller(req);
  if (!uid) return json({ error: "Please log in again." }, 401);
  const key = env("FLW_SECRET_KEY");
  if (!key) return json({ error: "Withdrawals aren't switched on yet.", code: "not_configured" }, 503);
  let b: any;
  try { b = await req.json(); } catch { return json({ error: "Invalid request" }, 400); }
  const H = { Authorization: `Bearer ${key}`, "Content-Type": "application/json" };

  try {
    if (b.action === "banks") {
      const r = await fetch(`${FLW}/banks/NG`, { headers: H });
      const j = await r.json().catch(() => ({}));
      if (!r.ok || !Array.isArray(j?.data)) return json({ error: "Could not load banks. Try again." }, 502);
      return json({ ok: true, banks: j.data.map((x: any) => ({ code: String(x.code), name: String(x.name) })).sort((a: any, c: any) => a.name.localeCompare(c.name)) });
    }
    const code = String(b.bank_code ?? ""), acct = String(b.account_number ?? "");
    if (!/^\d{3,6}$/.test(code) || !/^\d{10}$/.test(acct)) return json({ error: "Enter a valid bank and 10-digit account number." }, 400);

    if (b.action === "resolve") {
      const r = await fetch(`${FLW}/accounts/resolve`, { method: "POST", headers: H, body: JSON.stringify({ account_number: acct, account_bank: code }) });
      const j = await r.json().catch(() => ({}));
      if (!r.ok || !j?.data?.account_name) return json({ error: "We couldn't find that account. Check the number and bank." }, 422);
      return json({ ok: true, account_name: String(j.data.account_name) });
    }

    if (b.action === "withdraw") {
      const amount = Number(b.amount);
      if (!Number.isInteger(amount) || amount <= 0) return json({ error: "Enter a whole amount." }, 400);
      // Resolve again server-side: never trust a name sent by the app.
      const rr = await fetch(`${FLW}/accounts/resolve`, { method: "POST", headers: H, body: JSON.stringify({ account_number: acct, account_bank: code }) });
      const rj = await rr.json().catch(() => ({}));
      if (!rr.ok || !rj?.data?.account_name) return json({ error: "We couldn't verify that bank account." }, 422);
      const bankName = String(b.bank_name ?? "").slice(0, 80);
      const { data: w, error } = await db.rpc("server_wallet_request_withdrawal", { p_user: uid, p_amount: amount, p_bank_code: code, p_bank_name: bankName, p_acct: acct, p_acct_name: rj.data.account_name });
      if (error) return json({ error: error.message.replace(/^.*?:\s*/, "") }, 422);
      const ref = w.reference as string;
      const tr = await fetch(`${FLW}/transfers`, { method: "POST", headers: H, body: JSON.stringify({
        account_bank: code, account_number: acct, amount, currency: "NGN", debit_currency: "NGN",
        narration: "Seculate wallet withdrawal", reference: ref,
      }) });
      const tj = await tr.json().catch(() => ({}));
      if (!tr.ok || tj?.status !== "success") {
        console.error("transfer init", tr.status, JSON.stringify(tj).slice(0, 300));
        await db.rpc("server_wallet_finish_withdrawal", { p_ref: ref, p_ok: false, p_flw_id: null, p_reason: "The transfer could not be started." });
        return json({ error: "The transfer could not be started. Your wallet was not charged." }, 502);
      }
      const st = String(tj.data?.status ?? "").toUpperCase();
      if (st === "FAILED") await db.rpc("server_wallet_finish_withdrawal", { p_ref: ref, p_ok: false, p_flw_id: String(tj.data?.id ?? ""), p_reason: String(tj.data?.complete_message ?? "Transfer failed") });
      else if (st === "SUCCESSFUL") await db.rpc("server_wallet_finish_withdrawal", { p_ref: ref, p_ok: true, p_flw_id: String(tj.data?.id ?? ""), p_reason: null });
      return json({ ok: true, reference: ref, status: st === "FAILED" ? "failed" : st === "SUCCESSFUL" ? "successful" : "processing", account_name: rj.data.account_name });
    }
    return json({ error: "Invalid request" }, 400);
  } catch (e) {
    console.error("wallet-withdraw", String(e));
    return json({ error: "Something went wrong. Please try again." }, 500);
  }
});
