import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { caller, cors, ep, EscrowError, hasPermission, json, minor } from "./_escrow.ts";

// Moves money at the escrow provider AFTER a staff member with the
// `escrow.release` permission approved it in the database (approve_release or
// an admin dispute ruling). Staff-only; every step is idempotent.
//  state release_pending + escrow release_approved -> pay the rental fee to the
//     lender / worker and give the collateral back to the borrower
//     (dispute ruled for the lender: collateral goes to the lender too).
//  state refunded + escrow refund_approved -> refund everything to the payer.
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  const { db, uid, token } = await caller(req);
  if (!uid) return json({ error: "Please log in again." }, 401);
  if (!(await hasPermission(token, "escrow.release"))) return json({ error: "Not allowed" }, 403);
  let body: any; try { body = await req.json(); } catch { return json({ error: "Invalid request" }, 400); }
  const txId = String(body.transaction_id ?? "");
  const { data: t } = await db.from("transactions").select("*").eq("id", txId).maybeSingle();
  const { data: esc } = await db.from("escrow_transactions").select("*").eq("transaction_id", txId).maybeSingle();
  const { data: pay } = await db.from("payments").select("flw_transaction_id").eq("transaction_id", txId).eq("purpose", "transaction").eq("status", "successful").limit(1).maybeSingle();
  if (!t || !esc || !pay?.flw_transaction_id) return json({ error: "Nothing to settle for this transaction." }, 404);
  const prov = pay.flw_transaction_id as string;

  try {
    const e = await ep("GET", `/api/v1/transactions/${prov}`);
    const funded = Number(e.funded_minor ?? 0), released = Number(e.released_minor ?? 0), refunded = Number(e.refunded_minor ?? 0);
    const held = funded - released - refunded;

    if (t.state === "release_pending" && esc.status === "release_approved") {
      const { data: disp } = await db.from("disputes").select("status").eq("transaction_id", txId).eq("status", "RELEASED").limit(1).maybeSingle();
      const fee = minor(Number(t.platform_fee ?? 0));
      const collateral = minor(Number(t.collateral ?? 0));
      const toLender = disp ? held : Math.max(0, held - collateral);
      let releaseId = "already-released";
      if (toLender > 0) {
        const rel = await ep("POST", `/api/v1/transactions/${prov}/releases`, { amount_minor: toLender, reason: "Released by Seculate after approval" }, `rel_${txId}`);
        releaseId = rel.id;
      }
      if (!disp && collateral > 0 && held >= collateral) {
        await ep("POST", `/api/v1/transactions/${prov}/refunds`, { amount_minor: collateral, source: "escrow_held", reason: "Collateral returned" }, `col_${txId}`);
      }
      const { error } = await db.rpc("server_mark_released", { p_tx: txId, p_provider_ref: releaseId });
      if (error) return json({ error: error.message }, 409);
      await db.from("audit_logs").insert({ actor_id: uid, action: "escrow.settled_release", target_type: "transaction", target_id: txId, metadata: { provider_txn: prov, to_lender_minor: toLender, fee_minor: fee } });
      return json({ ok: true, settled: "released" });
    }

    if (t.state === "refunded" && esc.status === "refund_approved") {
      let refundId = "nothing-held";
      if (held > 0) {
        const rf = await ep("POST", `/api/v1/transactions/${prov}/refunds`, { amount_minor: held, source: "escrow_held", reason: "Refund approved by Seculate" }, `ref_${txId}`);
        refundId = rf.id;
      }
      const { error } = await db.rpc("server_mark_refunded", { p_tx: txId, p_provider_ref: refundId });
      if (error) return json({ error: error.message }, 409);
      await db.from("audit_logs").insert({ actor_id: uid, action: "escrow.settled_refund", target_type: "transaction", target_id: txId, metadata: { provider_txn: prov, refunded_minor: held } });
      return json({ ok: true, settled: "refunded" });
    }
    return json({ error: "This transaction isn't approved for settlement." }, 409);
  } catch (err) {
    if (err instanceof EscrowError) return json({ error: err.message, code: err.code }, 502);
    console.error("escrow-settle failed", String(err));
    return json({ error: "Settlement failed. Nothing was changed; try again." }, 500);
  }
});
