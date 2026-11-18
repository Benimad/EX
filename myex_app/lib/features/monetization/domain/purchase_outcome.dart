import 'package:purchases_flutter/purchases_flutter.dart';

/// Result of a purchase or restore, as the UI needs it.
sealed class PurchaseOutcome {
  const PurchaseOutcome();
}

/// Purchase completed. [premiumActive] reflects the fresh CustomerInfo.
class PurchaseSuccess extends PurchaseOutcome {
  const PurchaseSuccess({this.premiumActive = false, this.isTrial = false});
  final bool premiumActive;
  final bool isTrial;
}

/// The user cancelled the Apple sheet. UI: silent no-op.
class PurchaseCancelled extends PurchaseOutcome {
  const PurchaseCancelled();
}

/// Ask to Buy / deferred. UI: calm message.
class PurchasePending extends PurchaseOutcome {
  const PurchasePending();
}

/// Already owned. UI: treat as restored.
class PurchaseAlreadyOwned extends PurchaseOutcome {
  const PurchaseAlreadyOwned();
}

class PurchaseFailed extends PurchaseOutcome {
  const PurchaseFailed(this.code, [this.message]);
  final String code;
  final String? message;
}

/// Pure mapping from RevenueCat error codes (unit tested).
PurchaseOutcome mapPurchasesErrorCode(
  PurchasesErrorCode code, [
  String? message,
]) {
  return switch (code) {
    PurchasesErrorCode.purchaseCancelledError => const PurchaseCancelled(),
    PurchasesErrorCode.paymentPendingError => const PurchasePending(),
    PurchasesErrorCode.productAlreadyPurchasedError =>
      const PurchaseAlreadyOwned(),
    _ => PurchaseFailed(code.name, message),
  };
}

/// Pure trial-eligibility mapping (unit tested).
///
/// Only an explicit `eligible` status AND a zero-price intro offer count.
/// `unknown` is treated as NOT eligible: we never say "free" unless sure.
bool mapTrialEligibility({
  required IntroEligibilityStatus? status,
  required double? introPrice,
}) {
  return status == IntroEligibilityStatus.introEligibilityStatusEligible &&
      introPrice != null &&
      introPrice == 0;
}

/// Intro (paid) offer eligibility, e.g. the exit offer.
bool mapIntroEligibility(IntroEligibilityStatus? status) =>
    status == IntroEligibilityStatus.introEligibilityStatusEligible;
