import { createClient } from "npm:@supabase/supabase-js@2";
import { env } from "./vault.ts";

export const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type", "Content-Type": "application/json" };
export const json = (b: unknown, status = 200) => new Response(JSON.stringify(b), { status, headers: cors });

export const BASE = env("ESCROW_BASE_URL") ?? "https://production-business-api.escrowpay.app";
export const escrowConfigured = () => !!env("ESCROW_API_KEY");

export class EscrowError extends Error {
  constructor(public status: number, public code: string, message: string) { super(message); }
}

/** Calls the EscrowPay merchant API with the server-side secret key. */
export async function ep(method: string, path: string, body?: unknown, idem?: string) {
  const key = env("ESCROW_API_KEY");
  if (!key) throw new EscrowError(503, "not_configured", "Escrow is not configured yet.");
  const headers: Record<string, string> = { "X-API-Key": key, "Content-Type": "application/json", "Accept": "application/json", "User-Agent": "seculate-edge/1.0" };
  if (method === "POST") headers["Idempotency-Key"] = idem ?? crypto.randomUUID();
  const r = await fetch(BASE + path, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) });
  const text = await r.text();
  let j: any = {};
  try { j = JSON.parse(text); } catch { /* non-json */ }
  if (!r.ok) {
    const d = j?.detail ?? j;
    console.error("escrow error", method, path, r.status, text.slice(0, 300));
    throw new EscrowError(r.status, d?.code ?? "provider_error", d?.message ?? "The payment provider rejected the request.");
  }
  return j?.data ?? j;
}

export function serviceClient() {
  return createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
}

/** Resolves the caller from the Authorization bearer token. */
export async function caller(req: Request) {
  const token = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
  const db = serviceClient();
  const { data } = await db.auth.getUser(token);
  return { db, uid: data?.user?.id ?? null, email: data?.user?.email ?? null, token };
}

/** True when the caller has the given staff permission (checked by the database as that user). */
export async function hasPermission(token: string, permission: string) {
  const c = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, { global: { headers: { Authorization: `Bearer ${token}` } } });
  const { data } = await c.rpc("has_permission", { p: permission });
  return data === true;
}

export const minor = (naira: number) => Math.round(naira * 100);
