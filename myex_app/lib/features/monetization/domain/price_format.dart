import 'dart:math' as math;

import 'package:intl/intl.dart';

import 'paywall_offer.dart';

/// Derived price values (per-week, savings %, trial length) computed from
/// StoreKit numbers and formatted with intl in the device locale (M0 rule 4).
///
/// The billed price itself is NEVER formatted here: the UI shows
/// `storeProduct.priceString` verbatim.
class PriceFormat {
  PriceFormat(String locale) : locale = Intl.canonicalizedLocale(locale);

  final String locale;

  /// Formats [amount] in [currencyCode] for this locale.
  ///
  /// [storePriceString] (StoreKit's `priceString` for the same product) is used
  /// to borrow the store's currency symbol: intl renders TRY as "TL" while the
  /// App Store shows "₺", and derived prices must match the billed price.
  String currency(
    double amount,
    String currencyCode, {
    String? storePriceString,
  }) {
    return _currencyFormat(
      currencyCode,
      symbol: symbolFrom(storePriceString),
    ).format(amount);
  }

  /// Currency symbol inside a StoreKit price string ("₺1.999,99" → "₺",
  /// "49,99 €" → "€", "US$49.99" → "US$"). Null if none can be found.
  /// Strips digits, separators and (narrow) no-break spaces.
  static String? symbolFrom(String? priceString) {
    if (priceString == null) return null;
    final s = priceString.replaceAll(RegExp(r'[\d.,\s  ٫٬-]'), '').trim();
    return s.isEmpty ? null : s;
  }

  /// Monthly equivalent of a yearly price: price / 12, rounded UP to the
  /// currency's minor unit so it is never understated. Shown only as small
  /// secondary text; the billed price is always the main price (spec P2).
  String perMonthFromYearly(
    double yearlyPrice,
    String currencyCode, {
    String? storePriceString,
  }) {
    final digits = _currencyFormat(currencyCode).decimalDigits ?? 2;
    return currency(
      ceilTo(yearlyPrice / 12, digits),
      currencyCode,
      storePriceString: storePriceString,
    );
  }

  /// Savings of annual vs 12 × monthly, floored. Null if there is no saving.
  static int? savingsPercent({
    required double annualPrice,
    required double monthlyPrice,
  }) {
    if (annualPrice <= 0 || monthlyPrice <= 0) return null;
    final pct = ((1 - annualPrice / (monthlyPrice * 12)) * 100).floor();
    return pct > 0 ? pct : null;
  }

  /// Discount of an intro price vs the regular price, floored.
  static int? discountPercent({
    required double introPrice,
    required double regularPrice,
  }) {
    if (regularPrice <= 0 || introPrice < 0) return null;
    final pct = ((1 - introPrice / regularPrice) * 100).floor();
    return pct > 0 ? pct : null;
  }

  /// Locale-aware percent ("40%" in en, "%40" in tr).
  String percent(int pct) =>
      NumberFormat.percentPattern(locale).format(pct / 100);

  /// Rounds [value] UP to [digits] decimals, tolerant of float noise
  /// (49.99/12 = 4.1658… → 4.17, and an exact 1.00 must stay 1.00).
  static double ceilTo(double value, int digits) {
    final factor = math.pow(10, digits).toDouble();
    final scaled = value * factor;
    final rounded = scaled.roundToDouble();
    if ((scaled - rounded).abs() < 1e-9) return rounded / factor;
    return scaled.ceilToDouble() / factor;
  }

  NumberFormat _currencyFormat(String currencyCode, {String? symbol}) =>
      symbol == null
      ? NumberFormat.simpleCurrency(locale: locale, name: currencyCode)
      : NumberFormat.currency(
          locale: locale,
          name: currencyCode,
          symbol: symbol,
          decimalDigits: NumberFormat.simpleCurrency(
            locale: locale,
            name: currencyCode,
          ).decimalDigits,
        );
}

/// Trial length helpers.
abstract final class TrialMath {
  /// End of the intro period starting at [start], using calendar math.
  /// Null for unknown units.
  static DateTime? endDate(IntroOffer intro, DateTime start) {
    final n = intro.unitCount * math.max<int>(1, intro.cycles);
    return switch (intro.unit) {
      IntroPeriodUnit.day => DateTime(start.year, start.month, start.day + n),
      IntroPeriodUnit.week => DateTime(
        start.year,
        start.month,
        start.day + 7 * n,
      ),
      IntroPeriodUnit.month => DateTime(start.year, start.month + n, start.day),
      IntroPeriodUnit.year => DateTime(start.year + n, start.month, start.day),
      IntroPeriodUnit.unknown => null,
    };
  }

  /// Trial length in whole days (e.g. 1 week → 7).
  static int? days(IntroOffer intro, DateTime start) {
    final end = endDate(intro, start);
    if (end == null) return null;
    final s = DateTime(start.year, start.month, start.day);
    return end.difference(s).inDays;
  }
}
