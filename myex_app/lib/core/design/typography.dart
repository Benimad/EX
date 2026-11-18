import 'package:flutter/widgets.dart';

import 'tokens.dart';

// =============================================================================
// TYPE SCALE — iOS Dynamic Type "Large" metrics (spec §13).
// UI text uses the platform system font (SF Pro on iOS): no fontFamily is set,
// so the theme's platform default applies. Letter-spacing stays normal.
// Instrument Serif (bundled, upright only) is used for ONE display headline per
// emotional screen and for hero numerals. Weights: 400 / 600 / 700 only.
// =============================================================================

abstract final class MyExFonts {
  static const serif = 'InstrumentSerif';
}

abstract final class MyExType {
  static TextStyle _sans(double size, double line, FontWeight w) => TextStyle(
    fontSize: size,
    height: line / size,
    fontWeight: w,
    color: MyExColors.ink,
    letterSpacing: 0,
  );

  // ---- iOS text styles ----
  static final largeTitle = _sans(34, 41, FontWeight.w700);
  static final title1 = _sans(28, 34, FontWeight.w700);
  static final title2 = _sans(22, 28, FontWeight.w700);

  /// Title 3 / prominent section header.
  static final title3 = _sans(20, 25, FontWeight.w600);
  static final headline = _sans(17, 22, FontWeight.w600);
  static final body = _sans(17, 22, FontWeight.w400);
  static final callout = _sans(16, 21, FontWeight.w400);
  static final subheadline = _sans(
    15,
    20,
    FontWeight.w400,
  ).copyWith(color: MyExColors.ink2);
  static final footnote = _sans(
    13,
    18,
    FontWeight.w400,
  ).copyWith(color: MyExColors.ink2);
  static final caption1 = _sans(
    12,
    16,
    FontWeight.w400,
  ).copyWith(color: MyExColors.ink2);

  /// Tab labels.
  static final caption2 = _sans(10, 12, FontWeight.w600);

  /// Buttons: 17/22 semibold, Title Case copy.
  static final button = _sans(17, 22, FontWeight.w600);

  /// Inline nav-bar title.
  static final navTitle = _sans(17, 22, FontWeight.w600);

  // ---- Brand voice: Instrument Serif, upright ----
  /// One per emotional screen (Plan ready, Paywall, Welcome, SOS, Win-back).
  static const display = TextStyle(
    fontFamily: MyExFonts.serif,
    fontSize: 40,
    height: 44 / 40,
    letterSpacing: -0.8, // −0.02em
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.normal,
    color: MyExColors.ink,
  );

  /// Display at sheet size (exit offer).
  static const displaySheet = 34.0;

  /// Display on SOS.
  static const displaySos = 44.0;

  /// Numeral sizes.
  static const numeralHero = 88.0;
  static const numeralBalance = 72.0;
  static const numeralMood = 64.0;
  static const numeralRing = 40.0;

  /// Hero numerals (40–96). Use [numeral] with a size.
  static TextStyle numeral(double size) => TextStyle(
    fontFamily: MyExFonts.serif,
    fontSize: size,
    height: 0.9,
    letterSpacing: -0.03 * size,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.normal,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: MyExColors.ink,
  );

  /// Tabular figures for prices and counters.
  static const tabular = [FontFeature.tabularFigures()];

  // ---- Paywall price hierarchy ----
  /// Billed price on plan rows: the main (largest) price.
  static final billedPrice = headline.copyWith(fontFeatures: tabular);

  /// Billing period / monthly equivalent under it: secondary.
  static final priceDetail = footnote.copyWith(fontFeatures: tabular);

  /// "Save 68%" inline.
  static final save = _sans(
    13,
    18,
    FontWeight.w600,
  ).copyWith(color: MyExColors.success);
}
