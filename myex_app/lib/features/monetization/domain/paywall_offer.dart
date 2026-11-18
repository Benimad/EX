import 'package:flutter/foundation.dart';

/// Where a paywall was opened from (analytics + routing). M9 trigger list.
enum PaywallTrigger {
  onboarding,
  homeChip,
  planLock,
  coachLimit,
  analysisLock,
  coins,
  me,
  trialStatus,
  winback,
  deepLink;

  static PaywallTrigger parse(String? raw) => PaywallTrigger.values.firstWhere(
    (t) => t.name == raw,
    orElse: () => PaywallTrigger.deepLink,
  );
}

/// A/B variant from RevenueCat offering metadata `paywall_variant`.
enum PaywallVariant {
  timeline,
  compare;

  static PaywallVariant parse(Object? raw) =>
      raw == 'compare' ? PaywallVariant.compare : PaywallVariant.timeline;
}

enum IntroPeriodUnit { day, week, month, year, unknown }

/// Introductory offer as reported by StoreKit (via RevenueCat).
@immutable
class IntroOffer {
  const IntroOffer({
    required this.price,
    required this.priceString,
    required this.unit,
    required this.unitCount,
    required this.cycles,
  });

  final double price;
  final String priceString;
  final IntroPeriodUnit unit;
  final int unitCount;
  final int cycles;

  bool get isFreeTrial => price == 0;
}

enum PlanPeriod { annual, monthly, other }

/// A purchasable subscription option, mapped from a RevenueCat Package.
/// Prices are ONLY StoreKit values (M0 rule 4).
@immutable
class PlanOption {
  const PlanOption({
    required this.productId,
    required this.period,
    required this.price,
    required this.priceString,
    required this.currencyCode,
    this.intro,
    this.handle,
  });

  final String productId;
  final PlanPeriod period;
  final double price;

  /// `storeProduct.priceString` — the billed price, verbatim.
  final String priceString;
  final String currencyCode;
  final IntroOffer? intro;

  /// Opaque SDK object (RevenueCat `Package`) used to purchase.
  final Object? handle;
}

/// Everything the paywall needs.
@immutable
class PaywallOffer {
  const PaywallOffer({
    required this.offeringId,
    required this.variant,
    required this.annual,
    required this.monthly,
    required this.trialEligible,
  });

  final String offeringId;
  final PaywallVariant variant;
  final PlanOption annual;
  final PlanOption monthly;

  /// True ONLY if StoreKit says eligible AND the intro offer is a free trial.
  /// When false, the paywall must not say "free" anywhere.
  final bool trialEligible;
}

/// The one-time exit offer (annual with a pay-up-front intro price).
@immutable
class ExitOffer {
  const ExitOffer({required this.plan, required this.regularAnnual});

  /// The intro product. `plan.intro` holds the first-year price.
  final PlanOption plan;

  /// The regular annual plan, for "instead of {annual}".
  final PlanOption regularAnnual;
}

/// An App Store promotional offer on a subscription (win-back, save-50).
/// Prices are StoreKit strings only.
@immutable
class PromoOffer {
  const PromoOffer({
    required this.plan,
    required this.offerId,
    required this.priceString,
    required this.months,
  });

  /// The subscription the offer applies to (its priceString is the price
  /// after the offer period).
  final PlanOption plan;
  final String offerId;

  /// Discounted price for the offer period, verbatim from StoreKit.
  final String priceString;

  /// Offer length in months (null if StoreKit reports another unit).
  final int? months;
}

class PaywallUnavailable implements Exception {
  const PaywallUnavailable([this.reason = 'offering missing']);
  final String reason;
  @override
  String toString() => 'PaywallUnavailable($reason)';
}
