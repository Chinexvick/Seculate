// Server-side secrets. Real Edge Function env vars win; otherwise values come from Supabase Vault.
// Only the service role can read the vault (public.get_server_secrets is revoked from everyone else),
// so nothing here is reachable from the app. Deno.env.set is not supported on the edge runtime, hence the map.
import { createClient } from "npm:@supabase/supabase-js@2";

const store: Record<string, string> = {};
try {
  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });
  const { data, error } = await db.rpc("get_server_secrets");
  if (error) console.error("vault load failed", error.message);
  for (const r of (data ?? []) as { name: string; secret: string }[]) store[r.name] = r.secret;
} catch (e) {
  console.error("vault load error", String(e));
}

export const env = (name: string): string | undefined => Deno.env.get(name) ?? store[name];
