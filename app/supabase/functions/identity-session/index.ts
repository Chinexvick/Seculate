import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { env } from "./vault.ts";
import { caller, cors, json } from "./_escrow.ts";

// Hands the signed-in app what the Prembly in-app widget needs, plus a one-time
// session reference that identity-complete will check. Nothing is returned to
// anyone who isn't logged in.
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  const { db, uid, email } = await caller(req);
  if (!uid) return json({ error: "Please log in again." }, 401);
  const wKey = env("PREMBLY_WIDGET_KEY"), wId = env("PREMBLY_WIDGET_ID");
  if (!wKey || !wId) return json({ error: "ID verification isn't switched on yet.", code: "not_configured" }, 503);
  const { data: p } = await db.from("profiles").select("first_name,last_name,phone,verification_status").eq("id", uid).maybeSingle();
  if (p?.verification_status === "verified") return json({ error: "You're already verified." }, 409);
  const ref = `sv_${crypto.randomUUID().replaceAll("-", "")}`;
  const { error } = await db.from("verification_sessions").insert({ ref, user_id: uid });
  if (error) return json({ error: "Could not start verification." }, 500);
  return json({
    ok: true, ref, widget_key: wKey, widget_id: wId, is_test: (env("PREMBLY_ENV") ?? "sandbox") !== "live",
    first_name: p?.first_name ?? "", last_name: p?.last_name ?? "", email: email ?? "", phone: p?.phone ?? "",
  });
});
