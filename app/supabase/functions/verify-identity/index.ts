import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { env } from "./vault.ts";
import { caller, cors, ep, EscrowError, escrowConfigured, json } from "./_escrow.ts";

const sha = async (s: string) => Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s)))).map((b) => b.toString(16).padStart(2, "0")).join("");
const norm = (s: string) => s.toLowerCase().replace(/[^a-z ]/g, " ").split(/\s+/).filter(Boolean);

// NIN verification (BVN is not accepted). Full numbers are never stored: only the last 4
// digits (display) and a peppered hash (stops one ID on many accounts).
// With the escrow provider configured, the check is a real KYC lookup and the
// resulting "party" is what the user pays / gets paid through. Without it, the
// record is saved as "pending" for manual staff review.
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  const { db, uid, email } = await caller(req);
  if (!uid) return json({ error: "Please log in again." }, 401);
  let body: { bvn?: string; nin?: string; consent?: boolean };
  try { body = await req.json(); } catch { return json({ error: "Invalid request" }, 400); }

  if (body.bvn) return json({ error: "Only your NIN is needed. Enter your NIN." }, 400);
  const docs = ([["nin", body.nin]] as [string, string | undefined][])
    .map(([t, n]) => [t, (n ?? "").trim()] as [string, string]).filter(([, n]) => n);
  if (!docs.length) return json({ error: "Enter your NIN." }, 400);
  for (const [t, n] of docs) if (!/^\d{11}$/.test(n)) return json({ error: `${t.toUpperCase()} must be 11 digits.` }, 400);
  if (body.consent !== true) return json({ error: "Please agree to the identity check to continue." }, 400);

  const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const pepper = env("IDENTITY_PEPPER") ?? service.slice(0, 24);
  const hashes: Record<string, string> = {};
  for (const [t, n] of docs) {
    hashes[t] = await sha(`${t}:${n}:${pepper}`);
    const { data: dup } = await db.from("verification_records").select("user_id").eq("id_hash", hashes[t]).neq("user_id", uid).limit(1);
    if (dup && dup.length) return json({ error: `This ${t.toUpperCase()} can't be used. Contact support if you think this is a mistake.` }, 409);
  }
  const { data: prof } = await db.from("profiles").select("first_name,last_name,phone,email").eq("id", uid).maybeSingle();
  const [type, num] = docs[0];
  const hash = hashes[type];

  // Step 1: real-time NIN lookup with Prembly (when its key is set). The photo and
  // address Prembly returns are never stored; only the verified name is kept.
  let pName: string | null = null, pSandbox = true, pChecked = false;
  const pKey = env("PREMBLY_API_KEY");
  if (pKey) {
    try {
      const pr = await fetch("https://api.prembly.com/verification/vnin-basic", {
        method: "POST",
        headers: { "x-api-key": pKey, "Content-Type": "application/json", "Accept": "application/json" },
        body: JSON.stringify({ number: num }),
      });
      const pj: any = await pr.json().catch(() => ({}));
      const okp = pj?.status === true && (pj?.verification?.status === "VERIFIED" || pj?.verification_status === "verified");
      if (okp) {
        pChecked = true;
        pSandbox = pj?.is_sandbox !== false;
        const d = pj?.data ?? {};
        pName = [d.firstname, d.middlename, d.surname].filter(Boolean).join(" ").trim() || null;
      } else if (pr.status >= 500 || pr.status === 401 || pr.status === 403 || pr.status === 429) {
        console.error("prembly unavailable", pr.status, String(pj?.detail ?? pj?.message ?? "").slice(0, 120));
        return json({ error: "Verification is unavailable right now. Please try again later." }, 502);
      } else {
        await db.rpc("server_set_escrow_party", { p_user: uid, p_doc: type, p_last4: num.slice(-4), p_hash: hash, p_party: null, p_name: null, p_status: "rejected", p_reason: "provider_rejected" });
        await db.from("audit_logs").insert({ actor_id: uid, action: "identity.rejected", target_type: "user", target_id: uid, metadata: { doc: type, provider: "prembly" } });
        return json({ error: "We couldn't verify that NIN. Check the number and try again.", code: "identity_verification_failed" }, 422);
      }
    } catch (e) {
      console.error("prembly call failed", String(e));
      return json({ error: "Verification is unavailable right now. Please try again later." }, 502);
    }
  }
  const saveDoc = (t: string, n: string, party: string | null, name: string | null, status: string, reason: string | null) =>
    db.rpc("server_set_escrow_party", { p_user: uid, p_doc: t, p_last4: n.slice(-4), p_hash: hashes[t], p_party: party, p_name: name, p_status: status, p_reason: reason });
  for (const [t, n] of docs) if (t !== type) await saveDoc(t, n, null, null, "pending", "manual_review");
  const save = (party: string | null, name: string | null, status: string, reason: string | null) => saveDoc(type, num, party, name, status, reason);

  const nameOnFile = `${prof?.first_name ?? ""} ${prof?.last_name ?? ""}`.trim();
  // Live mode: the name on the NIN must match the profile name. Sandbox returns made-up people, so it is skipped.
  const pMatch = !pChecked || pSandbox || !pName || (norm(nameOnFile).length > 0 && norm(nameOnFile).every((w) => new Set(norm(pName!)).has(w)));
  if (pChecked && !pMatch) {
    await save(null, pName, "pending", "name_mismatch");
    await db.from("audit_logs").insert({ actor_id: uid, action: "identity.pending", target_type: "user", target_id: uid, metadata: { doc: type, provider: "prembly", reason: "name_mismatch" } });
    return json({ ok: true, status: "pending", message: "Submitted. We'll review your details shortly." });
  }
  if (!escrowConfigured() && pChecked) {
    await save(null, pName, "verified", null);
    await db.from("audit_logs").insert({ actor_id: uid, action: "identity.verified", target_type: "user", target_id: uid, metadata: { doc: type, provider: "prembly", sandbox: pSandbox } });
    return json({ ok: true, status: "verified", message: "You're verified." });
  }
  if (!escrowConfigured()) {
    await save(null, null, "pending", "manual_review");
    await db.from("audit_logs").insert({ actor_id: uid, action: "identity.submitted", target_type: "user", target_id: uid, metadata: { mode: "manual" } });
    return json({ ok: true, status: "pending", message: "Submitted. We'll review your details shortly." });
  }

  try {
    const name = `${prof?.first_name ?? ""} ${prof?.last_name ?? ""}`.trim();
    const r = await ep("POST", "/api/v1/parties/onboard", {
      type, identifier: num, email: prof?.email ?? email, name: name || undefined,
      phone: prof?.phone || undefined, consent: true, consent_reference: `seculate-app-${uid}`, country_code: "NG",
      external_reference: `seculate-${uid}`,
    }, `onboard_${uid}_${type}_${hash.slice(0, 12)}`);
    const party = r?.party?.id as string | undefined;
    const idn = r?.identity ?? {};
    const vname = (idn.verification_details?.full_name ?? "") as string;
    const live = !pChecked && (idn.environment ?? r?.party?.environment) !== "test";
    // In live mode the name on the NIN must match the profile name.
    let status = "verified", reason: string | null = null;
    if (live && vname) {
      const a = new Set(norm(vname));
      const ok = norm(name).length > 0 && norm(name).every((w) => a.has(w));
      if (!ok) { status = "pending"; reason = "name_mismatch"; }
    }
    await save(party ?? null, vname || pName || null, status, reason);
    await db.from("audit_logs").insert({ actor_id: uid, action: `identity.${status}`, target_type: "user", target_id: uid, metadata: { doc: type, party } });
    return json({ ok: true, status, message: status === "verified" ? "You're verified." : "Submitted. We'll review your details shortly." });
  } catch (e) {
    if (e instanceof EscrowError) {
      if (e.code === "identity_verification_failed") { await save(null, null, "rejected", "provider_rejected"); return json({ error: "We couldn't verify those details. Check the number and try again.", code: e.code }, 422); }
      if (e.code === "identity_requires_review") { await save(null, null, "pending", "needs_review"); return json({ ok: true, status: "pending", message: "Submitted. We'll review your details shortly." }); }
      return json({ error: "Verification is unavailable right now. Please try again later." }, 502);
    }
    console.error("verify-identity failed", String(e));
    return json({ error: "Something went wrong. Please try again." }, 500);
  }
});
