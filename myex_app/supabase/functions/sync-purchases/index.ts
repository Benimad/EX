// Called by the app right after a purchase or restore (JWT required).
// Re-reads the subscriber from RevenueCat, mirrors the entitlement and credits
// any coin purchase the webhook hasn't credited yet (same `iap:<txn>` key).
// UNTESTED: see README.md.
import { admin, creditPack, fetchSubscriber, syncEntitlement } from "../_shared/revenuecat.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("method not allowed", { status: 405 });

  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!token) return new Response("unauthorized", { status: 401 });
  const { data: { user }, error: authError } = await admin.auth.getUser(token);
  if (authError || !user) return new Response("unauthorized", { status: 401 });

  try {
    const subscriber = await fetchSubscriber(user.id);
    const ent = await syncEntitlement(user.id, { subscriber });

    // VERIFY shape: non_subscriptions: { [product_id]: [{ id, store_transaction_id, ... }] }
    const nonSubs = (subscriber.non_subscriptions ?? {}) as Record<string, Array<Record<string, unknown>>>;
    for (const [productId, txns] of Object.entries(nonSubs)) {
      for (const t of txns) {
        const txn = t.store_transaction_id;
        if (typeof txn === "string" && txn) {
          await creditPack(user.id, productId, txn, { via: "sync" });
        }
      }
    }

    const { data: wallet } = await admin
      .from("coin_wallets")
      .select("balance")
      .eq("user_id", user.id)
      .maybeSingle();
    return Response.json({
      premium: ent.active,
      expires_at: ent.expires?.toISOString() ?? null,
      coins: wallet?.balance ?? 0,
    });
  } catch (e) {
    console.error("sync-purchases failed", user.id, String(e));
    return new Response("sync failed", { status: 502 });
  }
});
