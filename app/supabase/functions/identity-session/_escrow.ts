import { createClient } from "npm:@supabase/supabase-js@2";
export const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type", "Content-Type": "application/json" };
export const json = (b: unknown, status = 200) => new Response(JSON.stringify(b), { status, headers: cors });
export async function caller(req: Request) {
  const token = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data } = await db.auth.getUser(token);
  return { db, uid: data?.user?.id ?? null, email: data?.user?.email ?? null, token };
}
