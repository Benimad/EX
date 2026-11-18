/// Identifiers shared with App Store Connect, RevenueCat and the Supabase
/// schema. They MUST match exactly. No prices here, ever (M0 rule 4).
abstract final class MonetizationIds {
  // Entitlement
  static const entitlement = 'premium';

  // Subscription products (group "MyEx Premium")
  static const annual = 'myex_premium_annual';
  static const monthly = 'myex_premium_monthly';
  static const annualIntroExit = 'myex_annual_intro_50';

  // Consumable coin packs
  static const coins30 = 'coins_30';
  static const coins80 = 'coins_80';
  static const coins200 = 'coins_200';
  static const coinProducts = [coins30, coins80, coins200];

  // Offerings
  static const offeringDefault = 'default';
  static const offeringDefaultCompare = 'default_compare';
  static const offeringExit = 'exit_offer';
  static const offeringWinback = 'winback';
  static const offeringCoins = 'coins';

  // Offering metadata keys
  static const metaPaywallVariant = 'paywall_variant';
  static const metaPopular = 'popular';
  static const metaBestValue = 'best_value';
  static const metaPromoOfferId = 'promo_offer_id';

  // Promotional offers
  static const promoSave50Annual = 'save50_annual';
  static const promoWinback3m = 'winback_3m';

  // Coin catalog items (server prices in public.coin_catalog)
  static const itemMsgs20 = 'msgs_20';
  static const itemPlanDay = 'plan_day';
  static const itemAnalysis = 'analysis';

  // Edge functions / RPCs
  static const fnSyncPurchases = 'sync-purchases';
  static const rpcSpendCoins = 'spend_coins';
  static const rpcGetLimits = 'get_limits';
  static const rpcMarkExitOfferShown = 'mark_exit_offer_shown';
}

/// Display-only product facts that the UI copy needs. The server
/// (`coin_packs`, `consume_quota`, `grant_premium_bonus`) is authoritative.
abstract final class MonetizationDisplay {
  /// Free plan covers days 1..freePlanDays.
  static const freePlanDays = 3;
  static const freeMessagesPerDay = 3;
  static const freeDraftsPerDay = 1;
  static const premiumMonthlyBonusCoins = 50;
}
