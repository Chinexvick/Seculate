import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { caller, cors, ep, EscrowError, escrowConfigured, json } from "./_escrow.ts";

// The app calls this after the user returns from checkout (and while waiting).
// It asks EscrowPay whether the money has arrived and, if so, tells the
// database through the service-only server_mark_paid() which re-checks the
// amount. The client can never mark anything paid by itself.
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  const { db, uid } = await caller(req);
  if (!uid) return json({ error: "Please log in again." }, 401);
  let body: any; try { body = await req.json(); } catch { return json({ error: "Invalid request" }, 400); }
  const txId = String(body.transaction_id ?? "");
  const { data: t } = await db.from("transactions").select("id,state,payer_id,payee_id").eq("id", txId).maybeSingle();
  if (!t || (t.payer_id !== uid && t.payee_id !== uid)) return json({ error: "Transaction not found." }, 404);
  if (t.state !== "payment_pending") return json({ ok: true, state: t.state });
  if (!escrowConfigured()) return json({ ok: true, state: t.state });
  const { data: pay } = await db.from("payments").select("*").eq("transaction_id", txId).eq("purpose", "transaction").eq("status", "pending").order("created_at", { ascending: false }).limit(1).maybeSingle();
  if (!pay?.flw_transaction_id) return json({ ok: true, state: t.state });
  try {
    const e = await ep("GET", `/api/v1/transactions/${pay.flw_transaction_id}`);
    const funded = Number(e.funded_minor ?? 0), want = Math.round(Number(pay.amount) * 100);
    if (funded >= want && ["funded", "partially_released", "released", "partially_refunded"].includes(e.status)) {
      const { error } = await db.rpc("server_mark_paid", { p_tx_ref: pay.tx_ref, p_flw_id: pay.flw_transaction_id, p_amount: funded / 100 });
      if (error) { console.error("mark paid", error.message); return json({ ok: false, error: "Could not confirm the payment yet." }, 500); }
    }
  } catch (err) {
    if (err instanceof EscrowError) return json({ ok: true, state: t.state, note: "Waiting for the payment provider." });
    throw err;
  }
  const { data: after } = await db.from("transactions").select("state").eq("id", txId).single();
  return json({ ok: true, state: after?.state ?? t.state });
});
