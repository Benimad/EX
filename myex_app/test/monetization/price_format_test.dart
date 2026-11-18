import 'package:flutter_test/flutter_test.dart';
import 'package:myex_app/features/monetization/domain/paywall_offer.dart';
import 'package:myex_app/features/monetization/domain/price_format.dart';
import 'package:myex_app/features/monetization/presentation/paywall_copy.dart';
import 'package:myex_app/l10n/app_localizations_en.dart';
import 'package:myex_app/l10n/app_localizations_tr.dart';

/// Test fixtures only: in the app, every price comes from StoreKit.
PaywallOffer offer({
  required double annual,
  required String annualStr,
  required double monthly,
  required String monthlyStr,
  required String currency,
  bool eligible = true,
  IntroOffer? intro = const IntroOffer(
    price: 0,
    priceString: '0',
    unit: IntroPeriodUnit.week,
    unitCount: 1,
    cycles: 1,
  ),
}) => PaywallOffer(
  offeringId: 'default',
  variant: PaywallVariant.timeline,
  trialEligible: eligible,
  annual: PlanOption(
    productId: 'myex_premium_annual',
    period: PlanPeriod.annual,
    price: annual,
    priceString: annualStr,
    currencyCode: currency,
    intro: intro,
  ),
  monthly: PlanOption(
    productId: 'myex_premium_monthly',
    period: PlanPeriod.monthly,
    price: monthly,
    priceString: monthlyStr,
    currencyCode: currency,
  ),
);

void main() {
  group('PriceFormat', () {
    test('ceilTo rounds up, never understates, tolerates float noise', () {
      expect(PriceFormat.ceilTo(49.99 / 12, 2), 4.17);
      expect(PriceFormat.ceilTo(12 / 12, 2), 1.00);
      expect(PriceFormat.ceilTo(0.961, 2), 0.97);
      expect(PriceFormat.ceilTo(1999.99 / 12, 2), 166.67);
      expect(PriceFormat.ceilTo(1000 / 12, 0), 84);
    });

    test('monthly equivalent in en / USD', () {
      expect(
        PriceFormat(
          'en_US',
        ).perMonthFromYearly(49.99, 'USD', storePriceString: r'$49.99'),
        r'$4.17',
      );
    });

    test('monthly equivalent in tr / TRY uses the StoreKit ₺ symbol', () {
      final s = PriceFormat(
        'tr_TR',
      ).perMonthFromYearly(1999.99, 'TRY', storePriceString: '₺1.999,99');
      expect(s, contains('₺'));
      expect(s, contains('166,67'));
      expect(s, isNot(contains('TL')));
    });

    test('savings % is floored; no saving → null', () {
      expect(
        PriceFormat.savingsPercent(annualPrice: 49.99, monthlyPrice: 12.99),
        67,
      );
      expect(
        PriceFormat.savingsPercent(annualPrice: 120, monthlyPrice: 10),
        isNull,
      );
    });

    test('exit-offer discount %', () {
      expect(
        PriceFormat.discountPercent(introPrice: 24.99, regularPrice: 49.99),
        50,
      );
    });

    test('symbol is taken from the StoreKit price string', () {
      expect(PriceFormat.symbolFrom('₺1.999,99'), '₺');
      expect(PriceFormat.symbolFrom('49,99 €'), '€');
      expect(PriceFormat.symbolFrom('US\$49.99'), 'US\$');
      expect(PriceFormat.symbolFrom(r'$49.99'), r'$');
      expect(PriceFormat.symbolFrom('49.99'), isNull);
    });

    test('percent sign position follows the locale', () {
      expect(PriceFormat('en').percent(40), '40%');
      expect(PriceFormat('tr').percent(40), '%40');
    });

    test('trial length from intro period', () {
      const week = IntroOffer(
        price: 0,
        priceString: '',
        unit: IntroPeriodUnit.week,
        unitCount: 1,
        cycles: 1,
      );
      expect(TrialMath.days(week, DateTime(2026, 11, 17)), 7);
      const month = IntroOffer(
        price: 0,
        priceString: '',
        unit: IntroPeriodUnit.month,
        unitCount: 1,
        cycles: 1,
      );
      expect(TrialMath.days(month, DateTime(2026, 2, 3)), 28);
    });
  });

  group('PaywallCopy', () {
    final now = DateTime(2026, 11, 17);

    test('eligible EN: billed price is the main price, no per-week', () {
      final c = PaywallCopy(
        offer: offer(
          annual: 49.99,
          annualStr: r'$49.99',
          monthly: 12.99,
          monthlyStr: r'$12.99',
          currency: 'USD',
        ),
        l10n: AppLocalizationsEn(),
        now: now,
      );
      expect(c.trialDays, 7);
      expect(c.yearlyPrice, r'$49.99');
      expect(c.monthlyPrice, r'$12.99');
      expect(c.saveLabel, 'Save 67%');
      expect(c.yearlyDetail, r'7 days free · $4.17/month');
      expect(c.cta(PlanPeriod.annual), 'Start Free Trial');
      expect(c.cta(PlanPeriod.monthly), 'Subscribe');
      expect(
        c.fine(PlanPeriod.annual),
        r'7 days free, then $49.99/year. Cancel anytime in Settings.',
      );
      expect(
        c.fine(PlanPeriod.monthly),
        r'$12.99/month. Cancel anytime in Settings.',
      );
      expect(c.timeline!.remind, DateTime(2026, 11, 22));
      expect(c.timeline!.end, DateTime(2026, 11, 24));
      final all = [
        c.yearlyDetail,
        c.fine(PlanPeriod.annual),
        c.yearlySemantics(),
        c.monthlySemantics(),
      ].join(' ').toLowerCase();
      expect(all, isNot(contains('week')));
    });

    test('NOT eligible: the word "free" appears nowhere', () {
      final c = PaywallCopy(
        offer: offer(
          annual: 49.99,
          annualStr: r'$49.99',
          monthly: 12.99,
          monthlyStr: r'$12.99',
          currency: 'USD',
          eligible: false,
        ),
        l10n: AppLocalizationsEn(),
        now: now,
      );
      final all = [
        c.cta(PlanPeriod.annual),
        c.fine(PlanPeriod.annual),
        c.saveLabel ?? '',
        c.yearlyDetail,
        c.yearlySemantics(),
      ].join(' ').toLowerCase();
      expect(all, isNot(contains('free')));
      expect(c.cta(PlanPeriod.annual), 'Subscribe');
      expect(c.yearlyDetail, r'$4.17/month');
      expect(c.timeline, isNull);
    });

    test('eligible but intro is a PAID intro → no "free"', () {
      final c = PaywallCopy(
        offer: offer(
          annual: 49.99,
          annualStr: r'$49.99',
          monthly: 12.99,
          monthlyStr: r'$12.99',
          currency: 'USD',
          intro: const IntroOffer(
            price: 24.99,
            priceString: r'$24.99',
            unit: IntroPeriodUnit.year,
            unitCount: 1,
            cycles: 1,
          ),
        ),
        l10n: AppLocalizationsEn(),
        now: now,
      );
      expect(c.showsTrial, isFalse);
      expect(c.cta(PlanPeriod.annual).toLowerCase(), isNot(contains('free')));
    });

    test('TR: ₺ prices from StoreKit, "%66 tasarruf", Turkish CTA', () {
      final c = PaywallCopy(
        offer: offer(
          annual: 1999.99,
          annualStr: '₺1.999,99',
          monthly: 499.99,
          monthlyStr: '₺499,99',
          currency: 'TRY',
        ),
        l10n: AppLocalizationsTr(),
        now: now,
      );
      expect(c.yearlyPrice, '₺1.999,99');
      expect(c.saveLabel, '%66 tasarruf');
      expect(c.yearlyDetail, '7 gün ücretsiz · aylık ₺166,67');
      expect(c.cta(PlanPeriod.annual), 'Ücretsiz Denemeyi Başlat');
    });
  });
}
