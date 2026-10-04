import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { env } from "./vault.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

// Flutterwave -> Seculate payment confirmation (plan subscriptions).
// 1. Reject anything without the secret hash header we configured in the Flutterwave dashboard.
// 2. Never trust the webhook body: re-verify the transaction directly with Flutterwave.
// 3. The database function server_mark_paid() re-checks the amount and is idempotent.
const json = (b: unknown, status = 200) => new Response(JSON.stringify(b), { status, headers: { "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  const secretHash = env("FLW_SECRET_HASH");
  const key = env("FLW_SECRET_KEY");
  if (!secretHash || !key) return json({ error: "Not configured" }, 503);
  if (req.headers.get("verif-hash") !== secretHash) return json({ error: "Forbidden" }, 401);

  let evt: any;
  try { evt = await req.json(); } catch { return json({ error: "Invalid" }, 400); }
  const data = evt?.data ?? {};
  // Bank-transfer (withdrawal) result: confirm with Flutterwave before touching the wallet.
  if (String(evt?.event ?? "").startsWith("transfer") && data.id) {
    const rr = await fetch(`https://api.flutterwave.com/v3/transfers/${encodeURIComponent(String(data.id))}`, { headers: { Authorization: `Bearer ${key}` } });
    const vv = await rr.json().catch(() => ({}));
    const tr = vv?.data;
    if (!rr.ok || !tr?.reference) return json({ error: "Could not verify" }, 502);
    const sdb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const st = String(tr.status ?? "").toUpperCase();
    if (st === "SUCCESSFUL") await sdb.rpc("server_wallet_finish_withdrawal", { p_ref: String(tr.reference), p_ok: true, p_flw_id: String(tr.id), p_reason: null });
    else if (st === "FAILED") await sdb.rpc("server_wallet_finish_withdrawal", { p_ref: String(tr.reference), p_ok: false, p_flw_id: String(tr.id), p_reason: String(tr.complete_message ?? "Bank rejected the transfer").slice(0, 200) });
    return json({ ok: true });
  }
  const id = data.id ? String(data.id) : "";
  const txRef = String(data.tx_ref ?? "");
  if (!id || !txRef) return json({ ok: true, ignored: true });

  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  // Idempotency: one row per provider event.
  // A row is stored per event; it only counts as handled once `processed` is true,
  // so a failed attempt is retried when Flutterwave re-sends the event.
  await db.from("payment_events").upsert({ provider: "flutterwave", event_id: id, event_type: String(evt?.event ?? ""), tx_ref: txRef, payload: evt }, { onConflict: "provider,event_id", ignoreDuplicates: true });
  const { data: seen } = await db.from("payment_events").select("processed").eq("provider", "flutterwave").eq("event_id", id).maybeSingle();
  if (seen?.processed) return json({ ok: true, duplicate: true });

  const r = await fetch(`https://api.flutterwave.com/v3/transactions/${encodeURIComponent(id)}/verify`, { headers: { Authorization: `Bearer ${key}` } });
  const v = await r.json().catch(() => ({}));
  const t = v?.data;
  if (!r.ok || v?.status !== "success" || !t) return json({ error: "Could not verify" }, 502);
  if (t.tx_ref !== txRef) return json({ error: "Reference mismatch" }, 400);
  const done = () => db.from("payment_events").update({ processed: true }).eq("provider", "flutterwave").eq("event_id", id);
  if (t.status !== "successful") {
    await db.rpc("server_mark_failed", { p_tx_ref: txRef, p_status: t.status === "cancelled" ? "abandoned" : "failed" });
    await done();
    return json({ ok: true, status: t.status });
  }
  if (t.currency !== "NGN") return json({ error: "Currency mismatch" }, 400);
  const { error } = await db.rpc("server_mark_paid", { p_tx_ref: txRef, p_flw_id: String(t.id), p_amount: Number(t.amount) });
  if (error) { console.error("server_mark_paid", error.message); return json({ error: "Could not apply payment" }, 500); }
  await done();
  return json({ ok: true });
});
