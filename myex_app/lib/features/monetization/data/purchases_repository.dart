import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../domain/coin_pack.dart';
import '../domain/monetization_ids.dart';
import '../domain/paywall_offer.dart';
import '../domain/premium_state.dart';
import '../domain/purchase_outcome.dart';

/// Purchase operations. UI depends on this interface; the RevenueCat
/// implementation is below, tests use fakes.
abstract interface class PurchasesRepository {
  Stream<PremiumState> premiumStream();
  Future<PaywallOffer> getPaywall();

  /// Null if the user is not eligible (never show an unreachable offer).
  Future<ExitOffer?> getExitOffer();
  Future<List<CoinPack>> getCoinPacks(
    Map<String, ({int coins, int bonus})> packs,
  );

  /// Win-back promotional offer (offering "winback"), or null if missing.
  Future<PromoOffer?> getWinback();

  /// "save50_annual" on the annual product (cancel survey), or null.
  Future<PromoOffer?> getSave50Annual();
  Future<PurchaseOutcome> buy(Object handle);
  Future<PurchaseOutcome> buyWithPromo(Object handle, String promoOfferId);
  Future<PurchaseOutcome> restore();
}

/// Called after each successful purchase/restore (the `sync-purchases`
/// Edge Function). Failure must not turn a successful purchase into an error.
typedef ServerSync = Future<void> Function();

class RevenueCatPurchasesRepository implements PurchasesRepository {
  RevenueCatPurchasesRepository({
    required ServerSync serverSync,
    required bool storeAvailable,
  }) : _serverSync = serverSync,
       _storeAvailable = storeAvailable;

  final ServerSync _serverSync;

  /// False when RevenueCat isn't configured for this platform (web, missing
  /// key). Then nothing calls the native SDK and the paywall shows its error
  /// state with "Continue with the free plan".
  final bool _storeAvailable;

  void _requireStore() {
    if (!_storeAvailable) throw const PaywallUnavailable('store unavailable');
  }

  // ---------------------------------------------------------------------------
  // Entitlement
  // ---------------------------------------------------------------------------

  @override
  Stream<PremiumState> premiumStream() {
    if (!_storeAvailable) return Stream.value(const PremiumState.free());
    late final StreamController<PremiumState> controller;
    void onUpdate(CustomerInfo info) => controller.add(premiumFrom(info));
    controller = StreamController<PremiumState>(
      onListen: () {
        Purchases.addCustomerInfoUpdateListener(onUpdate);
        Purchases.getCustomerInfo().then(
          onUpdate,
          onError: controller.addError,
        );
      },
      onCancel: () async {
        Purchases.removeCustomerInfoUpdateListener(onUpdate);
        await controller.close();
      },
    );
    return controller.stream;
  }

  static PremiumState premiumFrom(CustomerInfo info) {
    final e = info.entitlements.active[MonetizationIds.entitlement];
    if (e == null) return const PremiumState.free();
    return PremiumState(
      isActive: true,
      isTrial: e.periodType == PeriodType.trial,
      willRenew: e.willRenew,
      expiresAt: e.expirationDate == null
          ? null
          : DateTime.tryParse(e.expirationDate!)?.toLocal(),
      billingIssue: e.billingIssueDetectedAt != null,
      productId: e.productIdentifier,
      managementUrl: info.managementURL,
    );
  }

  // ---------------------------------------------------------------------------
  // Offerings
  // ---------------------------------------------------------------------------

  @override
  Future<PaywallOffer> getPaywall() async {
    _requireStore();
    final current = (await Purchases.getOfferings()).current;
    final annual = current?.annual;
    final monthly = current?.monthly;
    if (current == null || annual == null || monthly == null) {
      throw const PaywallUnavailable();
    }
    final id = annual.storeProduct.identifier;
    final elig = await Purchases.checkTrialOrIntroductoryPriceEligibility([id]);
    return PaywallOffer(
      offeringId: current.identifier,
      variant: PaywallVariant.parse(
        current.metadata[MonetizationIds.metaPaywallVariant],
      ),
      annual: planFrom(annual),
      monthly: planFrom(monthly),
      trialEligible: mapTrialEligibility(
        status: elig[id]?.status,
        introPrice: annual.storeProduct.introductoryPrice?.price,
      ),
    );
  }

  @override
  Future<ExitOffer?> getExitOffer() async {
    if (!_storeAvailable) return null;
    final offerings = await Purchases.getOfferings();
    final pkg = offerings.all[MonetizationIds.offeringExit]?.annual;
    final regular = offerings.current?.annual;
    if (pkg == null || regular == null) return null;
    if (pkg.storeProduct.introductoryPrice == null) return null;
    final id = pkg.storeProduct.identifier;
    final elig = await Purchases.checkTrialOrIntroductoryPriceEligibility([id]);
    if (!mapIntroEligibility(elig[id]?.status)) return null;
    return ExitOffer(plan: planFrom(pkg), regularAnnual: planFrom(regular));
  }

  @override
  Future<List<CoinPack>> getCoinPacks(
    Map<String, ({int coins, int bonus})> packs,
  ) async {
    _requireStore();
    final offering =
        (await Purchases.getOfferings()).all[MonetizationIds.offeringCoins];
    if (offering == null) return const [];
    final popular = offering.metadata[MonetizationIds.metaPopular];
    final best = offering.metadata[MonetizationIds.metaBestValue];
    final result = <CoinPack>[];
    for (final p in offering.availablePackages) {
      final productId = p.storeProduct.identifier;
      final def = packs[productId];
      if (def == null) continue; // unknown to the server → never sell it
      result.add(
        CoinPack(
          productId: productId,
          coins: def.coins,
          bonus: def.bonus,
          priceString: p.storeProduct.priceString,
          tag: productId == best
              ? CoinPackTag.bestValue
              : productId == popular
              ? CoinPackTag.popular
              : CoinPackTag.none,
          handle: p,
        ),
      );
    }
    result.sort((a, b) => a.total.compareTo(b.total));
    return result;
  }

  @override
  Future<PromoOffer?> getWinback() async {
    if (!_storeAvailable) return null;
    final offering =
        (await Purchases.getOfferings()).all[MonetizationIds.offeringWinback];
    final pkg = offering?.monthly;
    if (offering == null || pkg == null) return null;
    final id = offering.getMetadataString(
      MonetizationIds.metaPromoOfferId,
      MonetizationIds.promoWinback3m,
    );
    return _promo(pkg, id);
  }

  @override
  Future<PromoOffer?> getSave50Annual() async {
    if (!_storeAvailable) return null;
    final pkg = (await Purchases.getOfferings()).current?.annual;
    if (pkg == null) return null;
    return _promo(pkg, MonetizationIds.promoSave50Annual);
  }

  static PromoOffer? _promo(Package pkg, String offerId) {
    final d = pkg.storeProduct.discounts
        ?.where((d) => d.identifier == offerId)
        .firstOrNull;
    if (d == null) return null;
    final unit = d.periodUnit.toUpperCase();
    final count = d.periodNumberOfUnits * (d.cycles < 1 ? 1 : d.cycles);
    return PromoOffer(
      plan: planFrom(pkg),
      offerId: offerId,
      priceString: d.priceString,
      months: switch (unit) {
        'MONTH' => count,
        'YEAR' => count * 12,
        _ => null,
      },
    );
  }

  static PlanOption planFrom(Package p) {
    final s = p.storeProduct;
    final intro = s.introductoryPrice;
    return PlanOption(
      productId: s.identifier,
      period: switch (p.packageType) {
        PackageType.annual => PlanPeriod.annual,
        PackageType.monthly => PlanPeriod.monthly,
        _ => PlanPeriod.other,
      },
      price: s.price,
      priceString: s.priceString,
      currencyCode: s.currencyCode,
      intro: intro == null
          ? null
          : IntroOffer(
              price: intro.price,
              priceString: intro.priceString,
              unit: switch (intro.periodUnit) {
                PeriodUnit.day => IntroPeriodUnit.day,
                PeriodUnit.week => IntroPeriodUnit.week,
                PeriodUnit.month => IntroPeriodUnit.month,
                PeriodUnit.year => IntroPeriodUnit.year,
                _ => IntroPeriodUnit.unknown,
              },
              unitCount: intro.periodNumberOfUnits,
              cycles: intro.cycles,
            ),
      handle: p,
    );
  }

  // ---------------------------------------------------------------------------
  // Purchases
  // ---------------------------------------------------------------------------

  @override
  Future<PurchaseOutcome> buy(Object handle) => _guard(() async {
    final result = await Purchases.purchase(
      PurchaseParams.package(handle as Package),
    );
    return result.customerInfo;
  });

  @override
  Future<PurchaseOutcome> buyWithPromo(Object handle, String promoOfferId) =>
      _guard(() async {
        final pkg = handle as Package;
        final discount = pkg.storeProduct.discounts
            ?.where((d) => d.identifier == promoOfferId)
            .firstOrNull;
        if (discount == null) {
          throw PlatformException(
            code: '${PurchasesErrorCode.ineligibleError.index}',
            message: 'promo $promoOfferId unavailable',
          );
        }
        final promo = await Purchases.getPromotionalOffer(
          pkg.storeProduct,
          discount,
        );
        final result = await Purchases.purchase(
          PurchaseParams.package(pkg, promotionalOffer: promo),
        );
        return result.customerInfo;
      });

  @override
  Future<PurchaseOutcome> restore() => _guard(Purchases.restorePurchases);

  Future<PurchaseOutcome> _guard(Future<CustomerInfo> Function() run) async {
    if (!_storeAvailable) return const PurchaseFailed('storeUnavailable');
    final CustomerInfo info;
    try {
      info = await run();
    } on PlatformException catch (e) {
      return mapPurchasesErrorCode(
        PurchasesErrorHelper.getErrorCode(e),
        e.message,
      );
    }
    try {
      await _serverSync();
    } catch (e) {
      // The purchase succeeded; the webhook will catch up.
      debugPrint('sync-purchases failed (non-fatal): $e');
    }
    final premium = premiumFrom(info);
    return PurchaseSuccess(
      premiumActive: premium.isActive,
      isTrial: premium.isTrial,
    );
  }
}
