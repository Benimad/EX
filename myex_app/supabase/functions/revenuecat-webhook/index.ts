// RevenueCat → Supabase webhook (Prompt M3).
// Deploy: supabase functions deploy revenuecat-webhook --no-verify-jwt
// Secrets: REVENUECAT_WEBHOOK_AUTH, REVENUECAT_SECRET_API_KEY
// UNTESTED: see README.md "Edge Functions — manual checks".
import {
  admin,
  clawbackPack,
  creditPack,
  grantPremiumBonus,
  isCoinProduct,
  isUuid,
  resolveUserId,
  safeEqual,
  syncEntitlement,
} from "../_shared/revenuecat.ts";

const ok = (msg = "ok") => new Response(msg, { status: 200 });

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("method not allowed", { status: 405 });

  const secret = Deno.env.get("REVENUECAT_WEBHOOK_AUTH");
  if (!secret) return new Response("not configured", { status: 500 });
  if (!safeEqual(req.headers.get("authorization") ?? "", `Bearer ${secret}`)) {
    return new Response("unauthorized", { status: 401 });
  }

  // deno-lint-ignore no-explicit-any
  let body: any;
  try {
    body = await req.json();
  } catch {
    return new Response("bad json", { status: 400 });
  }
  const ev = body?.event;
  if (!ev?.id || !ev?.type) return new Response("bad event", { status: 400 });

  // Idempotency gate on event.id. A previously FAILED event (processed_at null)
  // is processed again; a processed one returns 200 "duplicate".
  const ins = await admin.from("webhook_events").insert({
    id: ev.id,
    type: ev.type,
    app_user_id: ev.app_user_id ?? null,
    environment: ev.environment ?? null,
    payload: body,
  });
  if (ins.error) {
    if (ins.error.code !== "23505") return new Response("db error", { status: 500 });
    const { data } = await admin.from("webhook_events").select("processed_at").eq("id", ev.id).single();
    if (data?.processed_at) return ok("duplicate");
  }

  try {
    await handle(ev);
    await admin.from("webhook_events").update({ processed_at: new Date().toISOString(), error: null }).eq("id", ev.id);
    return ok();
  } catch (e) {
    // Never log secrets or full payloads; ids + type are enough.
    console.error("webhook failed", ev.type, ev.id, String(e));
    await admin.from("webhook_events").update({ error: String(e).slice(0, 500) }).eq("id", ev.id);
    return new Response("retry", { status: 500 }); // RevenueCat retries non-2xx
  }
});

// deno-lint-ignore no-explicit-any
async function handle(ev: any) {
  if (ev.type === "TEST") return;

  if (ev.type === "TRANSFER") {
    const ids: unknown[] = [...(ev.transferred_from ?? []), ...(ev.transferred_to ?? [])];
    for (const id of ids) if (isUuid(id)) await syncEntitlement(id);
    return;
  }

  const uid = resolveUserId(ev);
  if (!uid) {
    console.warn("no supabase uid on event", ev.type, ev.id);
    return;
  }
  // VERIFY: transaction_id is the store transaction id for App Store events.
  const txn: string = ev.transaction_id ?? ev.id;
  const coin = ev.product_id ? await isCoinProduct(ev.product_id) : false;

  switch (ev.type) {
    case "NON_RENEWING_PURCHASE":
      if (coin) await creditPack(uid, ev.product_id, txn, { env: ev.environment, store: ev.store });
      return;

    case "CANCELLATION":
      if (coin) {
        if (ev.cancel_reason === "CUSTOMER_SUPPORT") await clawbackPack(uid, ev.product_id, txn);
        return;
      }
      await syncEntitlement(uid);
      return;

    case "INITIAL_PURCHASE":
    case "RENEWAL": {
      const isTrial = ev.type === "INITIAL_PURCHASE" && ev.period_type === "TRIAL";
      const { active } = await syncEntitlement(uid, { trialStarted: isTrial });
      // 50 coins on INITIAL_PURCHASE (trial included) and RENEWAL, keyed per
      // calendar month in SQL. No bonus for family-shared access.
      if (active && !ev.is_family_share) await grantPremiumBonus(uid);
      return;
    }

    case "EXPIRATION":
      await syncEntitlement(uid, { lapsed: true });
      return;

    case "UNCANCELLATION":
    case "PRODUCT_CHANGE":
    case "BILLING_ISSUE":
    case "SUBSCRIPTION_EXTENDED":
    case "TEMPORARY_ENTITLEMENT_GRANT":
    case "REFUND_REVERSED":
      await syncEntitlement(uid);
      return;

    default:
      console.log("ignored event type", ev.type);
  }
}
