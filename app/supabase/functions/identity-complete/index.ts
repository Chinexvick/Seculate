import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { env } from "./vault.ts";
import { caller, cors, json } from "./_escrow.ts";

// Records the outcome of the in-app Prembly widget (ID document + face scan).
// The app can only report an outcome for a session this server issued to this user,
// once. In Prembly sandbox the widget result is accepted so the flow can be tested.
// In live mode a widget result alone is NOT trusted: it is saved as "pending" for
// staff to confirm in the admin dashboard.
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  const { db, uid } = await caller(req);
  if (!uid) return json({ error: "Please log in again." }, 401);
  let b: any;
  try { b = await req.json(); } catch { return json({ error: "Invalid request" }, 400); }
  const ref = String(b.ref ?? "");
  const outcome = String(b.outcome ?? ""); // success | failed
  if (!/^sv_[0-9a-f]{32}$/.test(ref) || !["success", "failed"].includes(outcome)) return json({ error: "Invalid request" }, 400);

  const { data: s } = await db.from("verification_sessions").select("*").eq("ref", ref).eq("user_id", uid).maybeSingle();
  if (!s) return json({ error: "Verification session not found." }, 404);
  if (s.used || Date.now() - new Date(s.created_at).getTime() > 60 * 60 * 1000) return json({ error: "This verification session has ended. Start again." }, 410);
  const { data: claimed } = await db.from("verification_sessions").update({ used: true }).eq("ref", ref).eq("used", false).select("ref");
  if (!claimed?.length) return json({ error: "This verification session has ended. Start again." }, 410);

  const live = (env("PREMBLY_ENV") ?? "sandbox") === "live";
  const audit = (status: string) => db.from("audit_logs").insert({ actor_id: uid, action: `identity.${status}`, target_type: "user", target_id: uid, metadata: { provider: "prembly_widget", live } });
  let status: string, reason: string | null = null;
  if (outcome === "failed") { status = "rejected"; reason = "The ID or face scan did not pass. Try again in good light with your ID flat."; }
  else if (live) { status = "pending"; reason = "manual_review"; }
  else status = "verified";
  const { error } = await db.rpc("server_set_widget_verification", { p_user: uid, p_ref: ref, p_name: null, p_status: status, p_reason: reason });
  if (error) { console.error("widget verification", error.message); return json({ error: "Could not save the result." }, 500); }
  await audit(status);
  return json({ ok: true, status, message: status === "verified" ? "You're verified." : status === "pending" ? "Submitted. We'll review your details shortly." : "We couldn't verify you." });
});
