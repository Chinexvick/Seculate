import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { env } from "./vault.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { otpEmail, providerConfigured, sendEmail } from "./email.ts";

const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type", "Content-Type": "application/json" };
const json = (b: unknown, status = 200) => new Response(JSON.stringify(b), { status, headers: cors });
const sha = async (s: string) => Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s)))).map((b) => b.toString(16).padStart(2, "0")).join("");

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  let body: { email?: string; purpose?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid request" }, 400); }
  const email = (body.email ?? "").trim().toLowerCase();
  const purpose = body.purpose ?? "signup";
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]{2,}$/.test(email) || email.length > 254) return json({ error: "Enter a valid email address" }, 400);
  if (!["signup", "recovery", "login", "email_change"].includes(purpose)) return json({ error: "Invalid request" }, 400);

  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });
  const ip = (req.headers.get("x-forwarded-for") ?? "").split(",")[0].trim() || "unknown";

  // lockout + rate limits
  const { data: lock } = await db.from("otp_lockouts").select("locked_until").eq("email", email).maybeSingle();
  if (lock?.locked_until && new Date(lock.locked_until) > new Date()) return json({ error: "Too many attempts. Please try again later." }, 429);
  const since10 = new Date(Date.now() - 10 * 60_000).toISOString();
  const since24 = new Date(Date.now() - 24 * 3600_000).toISOString();
  const sinceH = new Date(Date.now() - 3600_000).toISOString();
  const [{ count: c10 }, { count: c24 }, { count: cip }] = await Promise.all([
    db.from("email_otps").select("id", { count: "exact", head: true }).eq("email", email).gte("created_at", since10),
    db.from("email_otps").select("id", { count: "exact", head: true }).eq("email", email).gte("created_at", since24),
    db.from("email_otps").select("id", { count: "exact", head: true }).eq("ip", ip).gte("created_at", sinceH),
  ]);
  if ((c10 ?? 0) >= 3 || (c24 ?? 0) >= 10 || (cip ?? 0) >= 20) return json({ error: "Too many codes requested. Please wait a few minutes." }, 429);

  // account existence rules (never reveal for recovery)
  const { data: existing } = await db.from("profiles").select("id").eq("email", email).maybeSingle();
  if (purpose === "signup" && existing) return json({ ok: true, exists: true });
  if (purpose === "recovery" && !existing) return json({ ok: true });

  const code = String(crypto.getRandomValues(new Uint32Array(1))[0] % 1000000).padStart(6, "0");
  const pepper = env("OTP_PEPPER") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!.slice(0, 24);
  await db.from("email_otps").update({ used_at: new Date().toISOString() }).eq("email", email).eq("purpose", purpose).is("used_at", null);
  const { error: insErr } = await db.from("email_otps").insert({ email, purpose, code_hash: await sha(`${code}:${email}:${purpose}:${pepper}`), expires_at: new Date(Date.now() + 10 * 60_000).toISOString(), ip });
  if (insErr) return json({ error: "Something went wrong. Please try again." }, 500);

  if (providerConfigured()) {
    try { await sendEmail(email, otpEmail(code, purpose)); } catch (e) { console.error("email send failed", String(e)); return json({ error: "We couldn't send the email. Please try again." }, 502); }
    return json({ ok: true });
  }
  // No provider configured yet: optional TEMPORARY dev echo so the flow can be tested before SMTP exists.
  const { data: s } = await db.from("app_settings").select("value").eq("key", "otp_dev_echo").maybeSingle();
  if (s?.value === true || s?.value === "true") return json({ ok: true, dev_code: code, dev_notice: "Email provider not configured: code returned for testing only." });
  return json({ error: "Email sending isn't configured yet." }, 503);
});
