import '../../../l10n/app_localizations.dart';
import '../domain/paywall_offer.dart';
import '../domain/price_format.dart';

/// All price-bearing paywall strings, derived from StoreKit values only.
/// Pure (no widgets) so it is unit tested in EN and TR.
///
/// Price hierarchy (spec P2, App Store 3.1.2): the billed price is the main
/// price on each row; the yearly plan's monthly equivalent is small secondary
/// text. There is no per-week price anywhere.
class PaywallCopy {
  PaywallCopy({required this.offer, required this.l10n, DateTime? now})
    : fmt = PriceFormat(l10n.localeName),
      now = now ?? DateTime.now();

  final PaywallOffer offer;
  final AppLocalizations l10n;
  final PriceFormat fmt;
  final DateTime now;

  /// Trial length in days, or null when the user must NOT see "free".
  late final int? trialDays = () {
    final intro = offer.annual.intro;
    if (!offer.trialEligible || intro == null || !intro.isFreeTrial) {
      return null;
    }
    final d = TrialMath.days(intro, now);
    return (d == null || d <= 0) ? null : d;
  }();

  bool get showsTrial => trialDays != null;

  late final int? savingsPct = PriceFormat.savingsPercent(
    annualPrice: offer.annual.price,
    monthlyPrice: offer.monthly.price,
  );

  /// Inline green "Save 67%" / "%67 tasarruf" next to "Yearly".
  String? get saveLabel =>
      savingsPct == null ? null : l10n.paywallSave(fmt.percent(savingsPct!));

  /// Small text: the yearly price per month, rounded up.
  late final String yearlyMonthlyEquivalent = fmt.perMonthFromYearly(
    offer.annual.price,
    offer.annual.currencyCode,
    storePriceString: offer.annual.priceString,
  );

  /// "7 days free · $4.17/month" (trial part only if eligible).
  String get yearlyDetail => trialDays != null
      ? l10n.paywallYearlyDetailTrial(trialDays!, yearlyMonthlyEquivalent)
      : l10n.paywallYearlyDetail(yearlyMonthlyEquivalent);

  /// Main price on each row, verbatim from StoreKit.
  String get yearlyPrice => offer.annual.priceString;
  String get monthlyPrice => offer.monthly.priceString;

  /// R14: restates the billed price in the subtitle (body size).
  String subtitle(PlanPeriod selected) {
    if (selected == PlanPeriod.monthly) {
      return l10n.paywallSubMonthly(offer.monthly.priceString);
    }
    final days = trialDays;
    return days != null
        ? l10n.paywallSubTrial(days, offer.annual.priceString)
        : l10n.paywallSubYearly(offer.annual.priceString);
  }

  String cta(PlanPeriod selected) => selected == PlanPeriod.annual && showsTrial
      ? l10n.paywallCtaTrial
      : l10n.paywallCtaSubscribe;

  /// Fine print under the CTA: always states the billed amount.
  String fine(PlanPeriod selected) {
    if (selected == PlanPeriod.monthly) {
      return l10n.paywallFineMonthly(offer.monthly.priceString);
    }
    final days = trialDays;
    return days != null
        ? l10n.paywallFineTrial(days, offer.annual.priceString)
        : l10n.paywallFineYearly(offer.annual.priceString);
  }

  /// Timeline dates (Today / end − 2 days / end). Null when not eligible.
  ({DateTime remind, DateTime end})? get timeline {
    final days = trialDays;
    if (days == null) return null;
    final today = DateTime(now.year, now.month, now.day);
    return (
      remind: DateTime(today.year, today.month, today.day + days - 2),
      end: DateTime(today.year, today.month, today.day + days),
    );
  }

  /// VoiceOver: name, billed price, detail (selection state comes from the
  /// radio semantics).
  String yearlySemantics() => l10n.paywallPlanSemantics(
    [l10n.paywallYearly, ?saveLabel].join(', '),
    '$yearlyPrice ${l10n.paywallPerYear}',
    yearlyDetail,
  );

  String monthlySemantics() => l10n.paywallPlanSemantics(
    l10n.paywallMonthly,
    '$monthlyPrice ${l10n.paywallPerMonth}',
    l10n.paywallNoTrial,
  );
}
