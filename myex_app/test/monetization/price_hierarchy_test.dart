import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myex_app/core/design/design.dart';
import 'package:myex_app/core/supabase/supabase_providers.dart';
import 'package:myex_app/features/monetization/application/monetization_providers.dart';
import 'package:myex_app/features/monetization/data/purchases_repository.dart';
import 'package:myex_app/features/monetization/domain/coin_pack.dart';
import 'package:myex_app/features/monetization/domain/paywall_offer.dart';
import 'package:myex_app/features/monetization/domain/premium_state.dart';
import 'package:myex_app/features/monetization/domain/purchase_outcome.dart';
import 'package:myex_app/features/monetization/presentation/paywall_screen.dart';
import 'package:myex_app/features/monetization/presentation/widgets/plan_card.dart';
import 'package:myex_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Price hierarchy (M0 + design spec P2, App Store 3.1.2): the billed price is
/// the main price on every plan row, the monthly equivalent is small secondary
/// text, and there is NO per-week price anywhere on the paywall.
void main() {
  test('type tokens: billed price outranks the secondary price line', () {
    expect(
      MyExType.billedPrice.fontSize!,
      greaterThan(MyExType.priceDetail.fontSize!),
    );
    expect(
      MyExType.billedPrice.fontWeight!.value,
      greaterThanOrEqualTo(MyExType.priceDetail.fontWeight!.value),
    );
  });

  testWidgets('PlanPicker row: billed price is the largest price text', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: PlanPicker(
              semanticLabel: 'Choose a plan',
              selected: 0,
              onSelect: (_) {},
              options: const [
                PlanOptionData(
                  title: 'Yearly',
                  saveLabel: 'Save 67%',
                  detail: '7 days free · MONTHLY_EQ/month',
                  price: 'BILLED',
                  period: 'per year',
                  semanticLabel: 'Yearly',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final billed = tester.widget<Text>(find.byKey(const Key('plan-billed')));
    final period = tester.widget<Text>(find.byKey(const Key('plan-period')));
    expect(billed.data, 'BILLED');
    expect(billed.style!.fontSize!, greaterThan(period.style!.fontSize!));
    // The monthly equivalent sits in the small detail line, not the price slot.
    final detail = tester.widget<Text>(find.textContaining('MONTHLY_EQ'));
    expect(detail.style!.fontSize!, lessThan(billed.style!.fontSize!));
  });

  for (final variant in PaywallVariant.values) {
    testWidgets('Paywall ($variant): no per-week price anywhere', (
      tester,
    ) async {
      // Tall surface so the lazy list builds every row (incl. compare table).
      tester.view.physicalSize = const Size(1170, 9000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final offer = _offer(variant);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            purchasesRepositoryProvider.overrideWithValue(_FakeRepo()),
            paywallOfferProvider.overrideWith((ref) async => offer),
            premiumProvider.overrideWith(
              (ref) => Stream.value(const PremiumState.free()),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PaywallScreen(trigger: PaywallTrigger.onboarding),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Prices come from the (fake) StoreKit strings.
      expect(find.text(r'$49.99'), findsOneWidget);
      expect(find.text(r'$12.99'), findsOneWidget);
      expect(find.text('Start Free Trial'), findsOneWidget);
      // No per-week framing anywhere on the screen.
      expect(find.textContaining('week', findRichText: true), findsNothing);
      expect(find.textContaining('Week', findRichText: true), findsNothing);
      // Timeline variant: the trial timeline (with the reminder switch inside)
      // collapses when Monthly is selected, and the CTA/fine print swap.
      // R14: billed price restated in the subtitle; R4: no payment today.
      expect(find.text(r'7 days free, then $49.99/year.'), findsOneWidget);
      expect(find.byKey(const Key('no-payment-today')), findsOneWidget);
      // R13: real cancel steps, expandable.
      await tester.tap(find.byKey(const Key('how-cancel')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const Key('how-cancel-steps')), findsOneWidget);
      if (variant == PaywallVariant.timeline) {
        expect(find.byKey(const Key('trial-timeline')), findsOneWidget);
        // R3: the plan is already built (completed step 0).
        expect(find.byKey(const Key('timeline-built')), findsOneWidget);
        expect(find.byKey(const Key('remind-switch')), findsOneWidget);
        await tester.tap(find.text(r'$12.99'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.byKey(const Key('trial-timeline')), findsNothing);
        expect(find.text('Subscribe'), findsOneWidget);
        expect(find.byKey(const Key('no-payment-today')), findsNothing);
        expect(find.text(r'$12.99/month. No free trial.'), findsOneWidget);
        expect(
          find.text(r'$12.99/month. Cancel anytime in Settings.'),
          findsOneWidget,
        );
      }
      // Close and Restore are present at first frame.
      expect(find.byKey(const Key('paywall-close')), findsOneWidget);
      expect(find.byKey(const Key('paywall-restore')), findsOneWidget);
    });
  }
}

PaywallOffer _offer(PaywallVariant variant) => PaywallOffer(
  offeringId: 'default',
  variant: variant,
  trialEligible: true,
  annual: const PlanOption(
    productId: 'myex_premium_annual',
    period: PlanPeriod.annual,
    price: 49.99,
    priceString: r'$49.99',
    currencyCode: 'USD',
    intro: IntroOffer(
      price: 0,
      priceString: r'$0.00',
      unit: IntroPeriodUnit.week,
      unitCount: 1,
      cycles: 1,
    ),
    handle: 'annual',
  ),
  monthly: const PlanOption(
    productId: 'myex_premium_monthly',
    period: PlanPeriod.monthly,
    price: 12.99,
    priceString: r'$12.99',
    currencyCode: 'USD',
    handle: 'monthly',
  ),
);

class _FakeRepo implements PurchasesRepository {
  @override
  Stream<PremiumState> premiumStream() =>
      Stream.value(const PremiumState.free());
  @override
  Future<PaywallOffer> getPaywall() async => _offer(PaywallVariant.timeline);
  @override
  Future<ExitOffer?> getExitOffer() async => null;
  @override
  Future<List<CoinPack>> getCoinPacks(
    Map<String, ({int coins, int bonus})> packs,
  ) async => const [];
  @override
  Future<PromoOffer?> getWinback() async => null;
  @override
  Future<PromoOffer?> getSave50Annual() async => null;
  @override
  Future<PurchaseOutcome> buy(Object handle) async => const PurchaseCancelled();
  @override
  Future<PurchaseOutcome> buyWithPromo(
    Object handle,
    String promoOfferId,
  ) async => const PurchaseCancelled();
  @override
  Future<PurchaseOutcome> restore() async => const PurchaseCancelled();
}
