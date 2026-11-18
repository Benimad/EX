import 'package:flutter/foundation.dart';

/// Client-side view of the "premium" entitlement, for DISPLAY only.
/// The server (`public.is_premium`) decides every unlock (M0 rule 2).
@immutable
class PremiumState {
  const PremiumState({
    required this.isActive,
    this.isTrial = false,
    this.willRenew = false,
    this.expiresAt,
    this.billingIssue = false,
    this.productId,
    this.managementUrl,
  });

  const PremiumState.free()
    : isActive = false,
      isTrial = false,
      willRenew = false,
      expiresAt = null,
      billingIssue = false,
      productId = null,
      managementUrl = null;

  final bool isActive;
  final bool isTrial;
  final bool willRenew;
  final DateTime? expiresAt;
  final bool billingIssue;
  final String? productId;
  final String? managementUrl;

  @override
  bool operator ==(Object other) =>
      other is PremiumState &&
      other.isActive == isActive &&
      other.isTrial == isTrial &&
      other.willRenew == willRenew &&
      other.expiresAt == expiresAt &&
      other.billingIssue == billingIssue &&
      other.productId == productId &&
      other.managementUrl == managementUrl;

  @override
  int get hashCode => Object.hash(
    isActive,
    isTrial,
    willRenew,
    expiresAt,
    billingIssue,
    productId,
    managementUrl,
  );
}
