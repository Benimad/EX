import 'dart:async';

import 'package:intl/intl.dart';

import '../features/monetization/data/purchases_repository.dart';
import '../features/monetization/domain/coin_pack.dart';
import '../features/monetization/domain/monetization_ids.dart';
import '../features/monetization/domain/paywall_offer.dart';
import '../features/monetization/domain/premium_state.dart';
import '../features/monetization/domain/purchase_outcome.dart';
import 'demo_store.dart';

// DEMO MODE ONLY. Example prices from the prototype CFG, standing in for
// StoreKit. Real builds take every price from RevenueCat (M0 rule 4); this
// folder is excluded from the no-price-literals test for that reason.

const _annual = 49.99;
const _monthly = 12.99;
const _exitIntro = 24.99;
const _winbackPromo = 9.99;
const _winbackMonths = 3;
const _coinPrices = {'coins_30': 2.99, 'coins_80': 6.99, 'coins_200': 14.99};

final _usd = NumberFormat.simpleCurrency(locale: 'en_US', name: 'USD');
String _p(double v) => _usd.format(v);

/// What the simulated App Store sheet shows.
class DemoPurchaseRequest {
  const DemoPurchaseRequest({
    required this.title,
    required this.price,
    this.detail,
  });
  final String title;
  final String price;
  final String? detail;
}

typedef DemoConfirm = Future<bool> Function(DemoPurchaseRequest request);

enum _Kind { annual, monthly, exit, coins }

class _Handle {
  const _Handle(this.kind, this.productId);
  final _Kind kind;
  final String productId;
}

class DemoPurchasesRepository implements PurchasesRepository {
  DemoPurchasesRepository(this.store, {required this.confirm});

  final DemoStore store;
  final DemoConfirm confirm;

  static const _week = IntroOffer(
    price: 0,
    priceString: r'$0.00',
    unit: IntroPeriodUnit.week,
    unitCount: 1,
    cycles: 1,
  );

  PlanOption get _annualPlan => PlanOption(
    productId: MonetizationIds.annual,
    period: PlanPeriod.annual,
    price: _annual,
    priceString: _p(_annual),
    currencyCode: 'USD',
    intro: _week,
    handle: const _Handle(_Kind.annual, MonetizationIds.annual),
  );

  PlanOption get _monthlyPlan => PlanOption(
    productId: MonetizationIds.monthly,
    period: PlanPeriod.monthly,
    price: _monthly,
    priceString: _p(_monthly),
    currencyCode: 'USD',
    handle: const _Handle(_Kind.monthly, MonetizationIds.monthly),
  );

  @override
  Stream<PremiumState> premiumStream() {
    late final StreamController<PremiumState> c;
    void emit() => c.add(store.premium);
    c = StreamController<PremiumState>(
      onListen: () {
        emit();
        store.addListener(emit);
      },
      onCancel: () async {
        store.removeListener(emit);
        await c.close();
      },
    );
    return c.stream;
  }

  @override
  Future<PaywallOffer> getPaywall() async => PaywallOffer(
    offeringId: store.variant == PaywallVariant.compare
        ? MonetizationIds.offeringDefaultCompare
        : MonetizationIds.offeringDefault,
    variant: store.variant,
    annual: _annualPlan,
    monthly: _monthlyPlan,
    trialEligible: !store.hadTrial,
  );

  @override
  Future<ExitOffer?> getExitOffer() async {
    if (store.hadIntro || store.isPremium) return null;
    return ExitOffer(
      plan: PlanOption(
        productId: MonetizationIds.annualIntroExit,
        period: PlanPeriod.annual,
        price: _annual,
        priceString: _p(_annual),
        currencyCode: 'USD',
        intro: IntroOffer(
          price: _exitIntro,
          priceString: _p(_exitIntro),
          unit: IntroPeriodUnit.year,
          unitCount: 1,
          cycles: 1,
        ),
        handle: const _Handle(_Kind.exit, MonetizationIds.annualIntroExit),
      ),
      regularAnnual: _annualPlan,
    );
  }

  @override
  Future<List<CoinPack>> getCoinPacks(
    Map<String, ({int coins, int bonus})> packs,
  ) async => [
    for (final e in packs.entries)
      CoinPack(
        productId: e.key,
        coins: e.value.coins,
        bonus: e.value.bonus,
        priceString: _p(_coinPrices[e.key] ?? 0),
        tag: e.key == MonetizationIds.coins200
            ? CoinPackTag.bestValue
            : e.key == MonetizationIds.coins80
            ? CoinPackTag.popular
            : CoinPackTag.none,
        handle: _Handle(_Kind.coins, e.key),
      ),
  ]..sort((a, b) => a.total.compareTo(b.total));

  @override
  Future<PromoOffer?> getWinback() async => PromoOffer(
    plan: _monthlyPlan,
    offerId: MonetizationIds.promoWinback3m,
    priceString: _p(_winbackPromo),
    months: _winbackMonths,
  );

  @override
  Future<PromoOffer?> getSave50Annual() async =>
      store.tier == DemoTier.annual || store.tier == DemoTier.trial
      ? PromoOffer(
          plan: _annualPlan,
          offerId: MonetizationIds.promoSave50Annual,
          priceString: _p(_exitIntro),
          months: 12,
        )
      : null;

  @override
  Future<PurchaseOutcome> buy(Object handle) async {
    final h = handle as _Handle;
    final req = switch (h.kind) {
      _Kind.annual when !store.hadTrial => DemoPurchaseRequest(
        title: 'MyEx Premium · Yearly',
        price: '7-day free trial',
        detail: 'Then ${_p(_annual)}/year',
      ),
      _Kind.annual => DemoPurchaseRequest(
        title: 'MyEx Premium · Yearly',
        price: '${_p(_annual)}/year',
      ),
      _Kind.monthly => DemoPurchaseRequest(
        title: 'MyEx Premium · Monthly',
        price: '${_p(_monthly)}/month',
      ),
      _Kind.exit => DemoPurchaseRequest(
        title: 'MyEx Premium · Yearly (intro)',
        price: '${_p(_exitIntro)} for 1 year',
        detail: 'Then ${_p(_annual)}/year',
      ),
      _Kind.coins => DemoPurchaseRequest(
        title: h.productId.replaceAll('_', ' '),
        price: _p(_coinPrices[h.productId] ?? 0),
      ),
    };
    if (!await confirm(req)) return const PurchaseCancelled();
    switch (h.kind) {
      case _Kind.annual:
        store.setTier(store.hadTrial ? DemoTier.annual : DemoTier.trial);
      case _Kind.monthly:
        store.setTier(DemoTier.monthly);
      case _Kind.exit:
        store.hadIntro = true;
        store.setTier(DemoTier.annual);
      case _Kind.coins:
        const total = {'coins_30': 30, 'coins_80': 90, 'coins_200': 240};
        store.addCoins(total[h.productId] ?? 0);
        return const PurchaseSuccess();
    }
    final p = store.premium;
    return PurchaseSuccess(premiumActive: p.isActive, isTrial: p.isTrial);
  }

  @override
  Future<PurchaseOutcome> buyWithPromo(
    Object handle,
    String promoOfferId,
  ) async {
    final h = handle as _Handle;
    final winback = promoOfferId == MonetizationIds.promoWinback3m;
    final ok = await confirm(
      DemoPurchaseRequest(
        title: winback ? 'MyEx Premium · Monthly' : 'MyEx Premium · Yearly',
        price: winback
            ? '${_p(_winbackPromo)} for $_winbackMonths months'
            : '${_p(_exitIntro)} for 1 year',
        detail: 'Promotional offer',
      ),
    );
    if (!ok) return const PurchaseCancelled();
    store.setTier(h.kind == _Kind.monthly ? DemoTier.monthly : DemoTier.annual);
    return const PurchaseSuccess(premiumActive: true);
  }

  @override
  Future<PurchaseOutcome> restore() async => PurchaseSuccess(
    premiumActive: store.isPremium,
    isTrial: store.premium.isTrial,
  );
}
