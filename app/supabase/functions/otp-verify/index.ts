import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { env } from "./vault.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type", "Content-Type": "application/json" };
const json = (b: unknown, status = 200) => new Response(JSON.stringify(b), { status, headers: cors });
const sha = async (s: string) => Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s)))).map((b) => b.toString(16).padStart(2, "0")).join("");
const MAX_ATTEMPTS_PER_CODE = 5, LOCK_AFTER_FAILS = 8, LOCK_MINUTES = 60;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  let body: { email?: string; purpose?: string; code?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid request" }, 400); }
  const email = (body.email ?? "").trim().toLowerCase();
  const purpose = body.purpose ?? "signup";
  const code = (body.code ?? "").trim();
  if (!/^\d{6}$/.test(code) || !email) return json({ error: "Enter the 6-digit code" }, 400);

  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });
  const { data: lock } = await db.from("otp_lockouts").select("*").eq("email", email).maybeSingle();
  if (lock?.locked_until && new Date(lock.locked_until) > new Date()) return json({ error: "Too many wrong codes. Please try again later." }, 429);

  const { data: row } = await db.from("email_otps").select("*").eq("email", email).eq("purpose", purpose).is("used_at", null)
    .gt("expires_at", new Date().toISOString()).order("created_at", { ascending: false }).limit(1).maybeSingle();

  const fail = async (msg: string) => {
    const windowStart = lock && Date.now() - new Date(lock.window_start).getTime() < 3600_000 ? lock.window_start : new Date().toISOString();
    const n = (lock && windowStart === lock.window_start ? lock.failed_count : 0) + 1;
    await db.from("otp_lockouts").upsert({ email, failed_count: n, window_start: windowStart, locked_until: n >= LOCK_AFTER_FAILS ? new Date(Date.now() + LOCK_MINUTES * 60_000).toISOString() : null });
    return json({ error: msg }, 400);
  };
  if (!row) return await fail("That code is invalid or has expired. Request a new one.");
  if (row.attempts >= MAX_ATTEMPTS_PER_CODE) return await fail("Too many wrong attempts on this code. Request a new one.");

  const pepper = env("OTP_PEPPER") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!.slice(0, 24);
  const ok = (await sha(`${code}:${email}:${purpose}:${pepper}`)) === row.code_hash;
  if (!ok) { await db.from("email_otps").update({ attempts: row.attempts + 1 }).eq("id", row.id); return await fail("Incorrect code. Check the email and try again."); }

  await db.from("email_otps").update({ used_at: new Date().toISOString() }).eq("id", row.id);
  await db.from("otp_lockouts").delete().eq("email", email);

  const { data: existing } = await db.from("profiles").select("id").eq("email", email).maybeSingle();
  if (!existing) {
    if (purpose === "recovery") return json({ error: "That code is invalid or has expired." }, 400);
    const { error } = await db.auth.admin.createUser({ email, email_confirm: true });
    if (error && !/already/i.test(error.message)) return json({ error: "Could not create your account. Please try again." }, 500);
  } else if (purpose === "signup") {
    await db.auth.admin.updateUserById(existing.id, { email_confirm: true });
  }
  const { data: link, error: linkErr } = await db.auth.admin.generateLink({ type: "magiclink", email });
  if (linkErr || !link?.properties?.hashed_token) return json({ error: "Could not sign you in. Please try again." }, 500);
  // The client exchanges this one-time hash for a normal Supabase session with verifyOtp(token_hash, type: magiclink).
  return json({ ok: true, token_hash: link.properties.hashed_token, is_new: !existing });
});
