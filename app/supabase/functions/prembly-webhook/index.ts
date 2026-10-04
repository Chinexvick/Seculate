import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

// Prembly -> Seculate. Anyone can POST here, so the body is only STORED for staff to
// look at (admin dashboard / database); it never changes a user's verification status.
Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response(JSON.stringify({ ok: true }), { status: 200, headers: { "Content-Type": "application/json" } });
  let payload: unknown = {};
  try { payload = await req.json(); } catch { /* ignore */ }
  try {
    const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });
    await db.from("prembly_events").insert({ payload });
  } catch (e) { console.error("prembly-webhook", String(e)); }
  return new Response(JSON.stringify({ ok: true }), { status: 200, headers: { "Content-Type": "application/json" } });
});
