// Shared RevenueCat helpers (Prompt M3).
// UNTESTED: written without Deno / the Supabase CLI. Run `deno check` and the
// curl checks in README.md before deploying.
import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";

function env(name: string): string {
  const v = Deno.env.get(name);
  if (!v) throw new Error(`missing env ${name}`);
  return v;
}

/** Service-role client. Server only — never exposed to the app. */
export const admin: SupabaseClient = createClient(
  env("SUPABASE_URL"),
  env("SUPABASE_SERVICE_ROLE_KEY"),
  { auth: { persistSession: false, autoRefreshToken: false } },
);

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
export const ENTITLEMENT = "premium";

export function isUuid(id: unknown): id is string {
  return typeof id === "string" && UUID_RE.test(id);
}

/** Constant-time string compare (no early exit on the first mismatch). */
export function safeEqual(a: string, b: string): boolean {
  const ea = new TextEncoder().encode(a);
  const eb = new TextEncoder().encode(b);
  let diff = ea.length ^ eb.length;
  const n = Math.max(ea.length, eb.length);
  for (let i = 0; i < n; i++) diff |= (ea[i] ?? 0) ^ (eb[i] ?? 0);
  return diff === 0;
}

/** App user ids are Supabase auth UUIDs. `$RCAnonymousID:` ids are ignored. */
export function resolveUserId(ev: Record<string, unknown>): string | null {
  const aliases = Array.isArray(ev.aliases) ? (ev.aliases as unknown[]) : [];
  const ids = [ev.app_user_id, ev.original_app_user_id, ...aliases];
  return (ids.find(isUuid) as string | undefined) ?? null;
}

// deno-lint-ignore no-explicit-any
export type Subscriber = Record<string, any>;

/**
 * RevenueCat REST v1 GET /subscribers/{id}.
 * VERIFY field names against the current API reference (v2 exists too).
 */
export async function fetchSubscriber(uid: string): Promise<Subscriber> {
  const res = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(uid)}`,
    {
      headers: {
        Authorization: `Bearer ${env("REVENUECAT_SECRET_API_KEY")}`,
        "Content-Type": "application/json",
      },
    },
  );
  if (!res.ok) throw new Error(`RevenueCat ${res.status}`);
  const body = await res.json();
  return body.subscriber as Subscriber;
}

/**
 * Mirrors the "premium" entitlement into public.profiles. Always re-reads the
 * subscriber (out-of-order webhook events can't corrupt the mirror).
 */
export async function syncEntitlement(
  uid: string,
  opts: { trialStarted?: boolean; lapsed?: boolean; subscriber?: Subscriber } = {},
): Promise<{ active: boolean; expires: Date | null }> {
  const sub = opts.subscriber ?? (await fetchSubscriber(uid));
  const ent = sub.entitlements?.[ENTITLEMENT];
  const s = ent ? sub.subscriptions?.[ent.product_identifier] : undefined;
  const dates = [ent?.expires_date, ent?.grace_period_expires_date, s?.grace_period_expires_date]
    .filter((d): d is string => typeof d === "string")
    .map((d) => new Date(d).getTime());
  const expires = dates.length ? new Date(Math.max(...dates)) : null;
  const now = new Date();
  const active = !!expires && expires > now;

  const patch: Record<string, unknown> = {
    premium_expires_at: expires?.toISOString() ?? null,
    premium_product_id: ent?.product_identifier ?? null,
    premium_period_type: s?.period_type ?? null, // 'trial' | 'intro' | 'normal' | ...
    premium_will_renew: s ? s.unsubscribe_detected_at == null : null,
    premium_billing_issue_at: s?.billing_issues_detected_at ?? null,
    premium_is_sandbox: s?.is_sandbox ?? false,
    premium_synced_at: now.toISOString(),
  };
  if (active) patch.had_premium = true;
  if (opts.trialStarted) patch.trial_started_at = now.toISOString();
  if (opts.lapsed && !active) patch.premium_lapsed_at = now.toISOString();

  const { error } = await admin.from("profiles").upsert({ id: uid, ...patch }, { onConflict: "id" });
  if (error) throw error;
  return { active, expires };
}

async function coinPack(productId: string): Promise<{ coins: number; bonus: number } | null> {
  const { data, error } = await admin
    .from("coin_packs")
    .select("coins,bonus")
    .eq("product_id", productId)
    .maybeSingle();
  if (error) throw error;
  return data;
}

export async function isCoinProduct(productId: string): Promise<boolean> {
  return (await coinPack(productId)) != null;
}

/** Credits a coin pack, idempotent by store transaction id (`iap:<txn>`). */
export async function creditPack(
  uid: string,
  productId: string,
  txnId: string,
  meta: Record<string, unknown>,
) {
  const pack = await coinPack(productId);
  if (!pack) {
    console.warn("unknown coin product", productId);
    return null;
  }
  const { data, error } = await admin.rpc("credit_coins", {
    p_uid: uid,
    p_amount: pack.coins + pack.bonus,
    p_kind: "purchase",
    p_key: `iap:${txnId}`,
    p_meta: { product_id: productId, ...meta },
  });
  if (error) throw error;
  return data;
}

/** Refund clawback (`refund:<txn>`). The balance may go negative; unlocks stay. */
export async function clawbackPack(uid: string, productId: string, txnId: string) {
  const pack = await coinPack(productId);
  if (!pack) return;
  const { error } = await admin.rpc("credit_coins", {
    p_uid: uid,
    p_amount: -(pack.coins + pack.bonus),
    p_kind: "refund_clawback",
    p_key: `refund:${txnId}`,
    p_meta: { product_id: productId },
  });
  if (error) throw error;
}

export async function grantPremiumBonus(uid: string) {
  const { error } = await admin.rpc("grant_premium_bonus", { p_uid: uid });
  if (error) throw error;
}
