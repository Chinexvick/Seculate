import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm";
import { SUPABASE_URL, SUPABASE_KEY } from "./config.js";

export const sb = createClient(SUPABASE_URL, SUPABASE_KEY, {
  auth: { persistSession: true, autoRefreshToken: true, storage: window.sessionStorage },
});

const FRIENDLY = [
  [/not allowed|permission denied|row-level security/i, "You don't have permission to do that."],
  [/jwt expired|invalid jwt|not authenticated/i, "Your session expired. Please sign in again."],
  [/failed to fetch|networkerror|load failed/i, "Can't reach the server. Check your internet connection."],
];
export function friendly(e) {
  const m = (e && (e.message || e.error_description || e.details)) || String(e || "Something went wrong");
  for (const [re, text] of FRIENDLY) if (re.test(m)) return text;
  return m;
}
export async function rpc(name, args) {
  const { data, error } = await sb.rpc(name, args);
  if (error) throw new Error(friendly(error));
  return data;
}
export async function db(q) { const { data, error } = await q; if (error) throw new Error(friendly(error)); return data; }

// Storage: public buckets only. Private buckets are never linked from this dashboard.
export function publicUrl(bucket, path) {
  if (!path) return "";
  if (/^https:\/\//i.test(path)) return path;
  return `${SUPABASE_URL}/storage/v1/object/public/${bucket}/${String(path).split("/").map(encodeURIComponent).join("/")}`;
}

// Names for ids that show up in raw tables (audit log, chat flags). One lookup per id.
const nameCache = new Map();
export async function people(ids) {
  const need = [...new Set(ids.filter(Boolean))].filter((i) => !nameCache.has(i));
  if (need.length) {
    const rows = await db(sb.from("profiles").select("id,first_name,last_name,email").in("id", need.slice(0, 200)));
    for (const r of rows || []) nameCache.set(r.id, { name: [r.first_name, r.last_name].filter(Boolean).join(" ") || r.email, email: r.email });
  }
  return (id) => nameCache.get(id) || { name: "Unknown", email: "" };
}
