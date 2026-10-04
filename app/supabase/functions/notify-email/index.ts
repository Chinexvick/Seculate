import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { env } from "./vault.ts";
import { eventEmail, providerConfigured, sendEmail } from "./email.ts";

const json = (b: unknown, s = 200) => new Response(JSON.stringify(b), { status: s, headers: { "Content-Type": "application/json" } });
const naira = (n: unknown) => `₦${Number(n).toLocaleString("en-NG")}`;

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  const secret = env("NOTIFY_HOOK_SECRET");
  if (!secret || req.headers.get("x-hook-secret") !== secret) return json({ error: "Unauthorized" }, 401);
  let n: { id: string; user_id: string; kind: string; title: string; body: string; ref_type?: string; ref_id?: string };
  try { n = await req.json(); } catch { return json({ error: "Bad request" }, 400); }
  if (!providerConfigured()) return json({ skipped: "no provider" });

  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });
  const { data: p } = await db.from("profiles").select("email, first_name, account_status").eq("id", n.user_id).maybeSingle();
  if (!p?.email) return json({ skipped: "no email" });

  // respect the user's choices (email: false switches every email off)
  const { data: pr } = await db.from("notification_preferences").select("prefs").eq("user_id", n.user_id).maybeSingle();
  const prefs = (pr?.prefs ?? {}) as Record<string, unknown>;
  if (prefs.email === false) return json({ skipped: "email off" });

  const vars: Record<string, string | undefined> = { name: p.first_name ?? undefined, message: n.body, title: n.title };
  let kind = n.kind;
  let category = "";

  // resolve the item behind the notification
  let itemTitle: string | undefined; let itemKind: string | undefined;
  if (n.ref_type === "listing" && n.ref_id) {
    const { data } = await db.from("listings").select("title, kind").eq("id", n.ref_id).maybeSingle(); itemTitle = data?.title; itemKind = data?.kind;
  } else if (n.ref_type === "task" && n.ref_id) {
    const { data } = await db.from("tasks").select("title").eq("id", n.ref_id).maybeSingle(); itemTitle = data?.title; itemKind = "errand";
  } else if (n.ref_type === "transaction" && n.ref_id) {
    const { data } = await db.from("transactions").select("title, kind, amount").eq("id", n.ref_id).maybeSingle(); itemTitle = data?.title; itemKind = data?.kind;
  }
  vars.item = itemTitle;

  switch (n.kind) {
    case "listing_approved":
      kind = itemKind === "errand" ? "errand_approved" : itemKind === "service" ? "service_approved" : "product_approved"; category = "listings"; break;
    case "listing_changes": kind = "changes_requested"; vars.reason = n.body.includes(": ") ? n.body.split(": ").slice(1).join(": ") : n.body; category = "listings"; break;
    case "listing_rejected": kind = itemKind === "errand" ? "errand_rejected" : "listing_rejected"; vars.reason = n.body.includes(": ") ? n.body.split(": ").slice(1).join(": ") : n.body; category = "listings"; break;
    case "offer_new":
      kind = n.ref_type === "task" ? "interest_errand" : "interest_item"; category = "offers";
      vars.amount = /₦\s?([\d,\.]+)/.exec(n.body)?.[0]; break;
    case "counter_offer": category = "offers"; vars.amount = /₦\s?([\d,\.]+)/.exec(n.body)?.[0]; break;
    case "message": {
      kind = "new_message"; category = "messages";
      vars.from = /^(.+?) sent you/.exec(n.body)?.[1];
      // at most one email per conversation per 30 minutes
      if (n.ref_id) {
        const since = new Date(Date.now() - 30 * 60_000).toISOString();
        const { count } = await db.from("notifications").select("id", { count: "exact", head: true }).eq("user_id", n.user_id).eq("kind", "message").eq("ref_id", n.ref_id).gte("created_at", since).neq("id", n.id);
        if ((count ?? 0) > 0) return json({ skipped: "throttled" });
      }
      break;
    }
    case "offer_accepted": case "offer_rejected": category = "offers"; break;
    case "listing_available": category = "offers"; break;
    case "request_approved": category = "offers"; vars.item = n.body.replace(/^Your request for /, "").replace(/ is now visible.*$/, ""); break;
    case "request_new_bid": category = "offers"; break;
    case "escrow_funded": case "refund": category = "payments"; break;
    case "payment_success": category = "payments"; vars.amount = undefined; kind = "escrow_funded"; break;
    case "return_requested": case "review_received": case "support_reply": case "account_warning": case "announcement": break;
    case "admin_message": kind = "support_reply"; break;
    case "account_suspended": vars.reason = undefined; break;
    case "topup_success": case "payment_failed": case "withdrawal_success": case "withdrawal_failed": case "credits_added": case "refund_done": category = "payments"; vars.amount = /₦\s?([\d,\.]+)/.exec(n.body)?.[0]; break;
    case "plan_activated": kind = "subscription_active"; category = "payments"; vars.plan = n.body.replace(/^Your /, "").replace(/ plan is now active.*$/, ""); break;
    case "dispute_opened": category = "payments"; break;
    case "verification_success": case "verification_pending": break;
    case "verification_rejected": break;
    case "certificate_issued": case "dispute_due": case "dispute_updated": case "payment_window_expired": case "return_overdue": break;
    case "request_changes": case "request_rejected": case "request_reopened": category = "offers"; break;
    case "bid_accepted": case "bid_rejected": category = "offers"; break;
    case "payment_plan": kind = "subscription_active"; vars.plan = n.body; break;
    default: return json({ skipped: "no email for this kind" });
  }
  if (category && prefs[category] === false) return json({ skipped: "category off" });

  try { await sendEmail(p.email, eventEmail(kind, vars)); } catch (e) { console.error("notify email failed", String(e)); return json({ error: "send failed" }, 502); }
  return json({ ok: true, kind });
});
