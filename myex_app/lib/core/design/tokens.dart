import 'package:flutter/widgets.dart';

// =============================================================================
// DESIGN TOKENS — the ONLY place colors, radii, spacing, sizes and shadows are
// defined. Feature widgets reference these, never literals.
//
// Source: MyEx_Design_Spec.md §13 "Final design tokens" (iOS 26 Love theme).
// One accent (#D81B60, #B0124F for small text), wine-tinted neutrals, flat
// white surfaces, glass only on floating chrome, ONE gradient (streak hero).
// =============================================================================

abstract final class MyExColors {
  // ---- Surfaces ----
  /// Grouped page background.
  static const bg = Color(0xFFFFF5F7);

  /// Cells, cards, bubbles.
  static const bgElev = Color(0xFFFFFFFF);

  // ---- Labels (wine-tinted neutrals) ----
  /// Primary label (≈15:1 on bg).
  static const ink = Color(0xFF3A0F22);

  /// Secondary label (5.8:1 on bg).
  static const ink2 = Color(0xFF86506A);

  /// Tertiary: chevrons, placeholders. Glyphs only, NEVER text.
  static const ink3 = Color(0x4D3A0F22); // rgba(58,15,34,.30)

  /// 0.5pt hairlines.
  static const sep = Color(0x1F3A0F22); // rgba(58,15,34,.12)

  /// Pressed cells, tracks, neutral fills.
  static const fill = Color(0x0F3A0F22); // rgba(58,15,34,.06)

  /// Tab selection capsule.
  static const capsule = Color(0x143A0F22); // rgba(58,15,34,.08)

  /// Neutral icon square (secondary rows).
  static const neutralIcon = Color(0xFF8E7280);

  // ---- Accent (one) ----
  /// Fills, icons, text ≥17pt semibold (4.94:1 on white).
  static const accent = Color(0xFFD81B60);

  /// Small accent text and links (6.9:1).
  static const accentInk = Color(0xFFB0124F);

  /// Tinted fills; text on it uses [accentInk], never [accent].
  static const accentSoft = Color(0x1AD81B60); // rgba(216,27,96,.10)

  static const onAccent = Color(0xFFFFFFFF);

  // ---- Semantic ----
  static const success = Color(0xFF0B7A55);
  static const successSoft = Color(0x1A0B7A55); // rgba(11,122,85,.10)
  static const danger = Color(0xFFD70015);

  /// Switches only.
  static const switchOn = Color(0xFF34C759);

  // ---- Coin (the object's real colour) ----
  static const coinGold = Color(0xFFF6C25B);
  static const coinFace = Color(0xFFFFE7A8);

  // ---- Scrims ----
  /// Sheet backdrop rgba(20,4,12,.22).
  static const scrim = Color(0x3814040C);

  /// Push dim #14040C at 12%.
  static const pushDim = Color(0x1F14040C);

  /// Behind a scaled page while a sheet is presented.
  static const presentingBackdrop = Color(0xFF0B0A10);

  // ---- Glass (floating chrome only) ----
  /// Transparent bg, for fades into the page (dock, nav edge).
  static const bgClear = Color(0x00FFF5F7);

  static const glassFill = Color(0x8CFFFFFF); // white 55%
  static const glassRim = Color(0xBFFFFFFF); // white 75%, 0.5pt
  static const glassHighlight = Color(0x80FFFFFF); // specular top-left

  // ---- Page background: static glows over bg ----
  static const pageGlowTop = Color(0x29FF78A0); // rgba(255,120,160,.16)
  static const pageGlowBottom = Color(0x24FFAAC3); // rgba(255,170,195,.14)

  // ---- The ONLY gradient: Home streak hero (+ app icon) ----
  static const heroStart = Color(0xFFB3134F);
  static const heroEnd = Color(0xFFD81B60);
  static const heroHighlight = Color(0x73FF96B4); // rgba(255,150,180,.45)
  static const onHero = Color(0xFFFFFFFF);
  static const heroTrack = Color(0x4DFFFFFF); // white 30%

  static const heroGradient = LinearGradient(
    // 160°
    begin: Alignment(-0.34, -0.94),
    end: Alignment(0.34, 0.94),
    colors: [heroStart, heroEnd],
  );
  static const heroHighlightGradient = RadialGradient(
    center: Alignment(0.8, -1),
    radius: 1.1,
    colors: [heroHighlight, Color(0x00FF96B4)],
    stops: [0, 0.6],
  );

  // ---- Mira orb (faceless) ----
  static const miraOrb = RadialGradient(
    center: Alignment(-0.24, -0.4),
    radius: 0.8,
    colors: [Color(0xFFFFE3EC), Color(0xFFF06A95), Color(0xFFB3134F)],
    stops: [0, 0.5, 1],
  );
  static const miraRim = Color(0x59FFFFFF); // white 35%

  // ---- Lumi (mascot) ----
  static const lumiTop = Color(0xFFD81B60);
  static const lumiBottom = Color(0xFFFF5C8A);
  static const lumiFace = Color(0xFF3A0F22);
}

/// Corner radii.
abstract final class MyExRadii {
  /// Icon squares.
  static const xs = 8.0;
  static const s = 12.0;

  /// StoreKit boxes.
  static const m = 16.0;

  /// Lists, cards, plan picker.
  static const l = 22.0;

  /// Hero.
  static const xl = 28.0;
  static const sheet = 38.0;
  static const capsule = 999.0;

  static const planRow = 18.0;
  static const tabCapsule = 27.0;
  static const bubble = 18.0;
  static const composer = 22.0;
  static const strip = 4.0;
  static const progress = 2.0;
}

/// Spacing (4/8 grid).
abstract final class MyExSpacing {
  /// Hairline gap (icon → caption in tab cells, orb → name).
  static const tight = 2.0;
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s8 = 32.0;

  /// Screen margin.
  static const margin = 16.0;

  /// Gap between sections.
  static const section = 24.0;

  /// Large title → content.
  static const titleToContent = 8.0;
  static const cardPadding = 16.0;
  static const rowVertical = 11.0;
  static const rowHorizontal = 16.0;

  /// Separator inset (plain / with leading icon).
  static const separatorInset = 16.0;
  static const separatorInsetIcon = 58.0;

  /// Dock bottom padding.
  static const dockBottom = 30.0;

  /// Floating tab bar insets.
  static const tabBarInset = 20.0;
}

/// Component sizes.
abstract final class MyExSizes {
  /// Apple HIG minimum hit target.
  static const minTap = 44.0;
  static const rowMinHeight = 44.0;
  static const buttonHeight = 52.0;
  static const navBarHeight = 52.0;

  /// Large-title collapse threshold (scroll offset).
  static const largeTitleCollapse = 36.0;

  // Tab bar + SOS accessory
  static const tabBarHeight = 62.0;
  static const tabBarPadding = 4.0;
  static const sosCircle = 62.0;
  static const tabIcon = 24.0;

  // Glyphs
  static const iconSm = 14.0;
  static const icon = 18.0;
  static const iconMd = 22.0;
  static const iconLg = 24.0;
  static const iconSquare = 30.0;
  static const radio = 22.0;
  static const radioCheck = 12.0;

  // Chips
  static const chipVisualHeight = 36.0;
  static const coin = 18.0;
  static const coinRow = 30.0;
  static const coinBalance = 32.0;

  // Avatars / mascots
  static const miraHeader = 36.0;
  static const miraSheet = 44.0;
  static const miraInline = 20.0;
  static const lumi = 170.0;
  static const lumiSos = 180.0;
  static const avatar = 56.0;
  static const mascotOrb = 120.0;

  // Paywall
  static const planRowMinHeight = 72.0;
  static const planRowVertical = 14.0;
  static const getCapsulePadding = 14.0;
  static const skeletonList = 156.0;
  static const datePickerHeight = 216.0;
  static const successMark = 96.0;
  static const ring = 100.0;
  static const ringStroke = 8.0;
  static const planHighlightBorder = 2.0;
  static const stripCell = 8.0;
  static const stripColumns = 15;
  static const timelineDot = 28.0;
  static const timelineConnector = 1.0;

  // Coach
  static const sendButton = 32.0;
  static const meterDot = 6.0;

  // Progress
  static const progressHeight = 4.0;

  // Coins "Get" capsule
  static const getCapsuleMinWidth = 76.0;
  static const getCapsuleHeight = 30.0;

  /// 0.5pt hairline.
  static const hairline = 0.5;

  static const grabberWidth = 36.0;
  static const grabberHeight = 5.0;
}

/// Glass recipe (floating chrome only).
abstract final class MyExGlassTokens {
  static const blurSigma = 14.0;

  /// 180% saturation boost behind glass.
  static const saturation = 1.8;
  static const rimWidth = 0.5;
}

/// Sheet presentation: the page behind scales and rounds.
abstract final class MyExPresentation {
  static const backgroundScale = 0.94;
  static const backgroundOffsetY = 14.0;
  static const backgroundRadius = MyExRadii.sheet;
}

/// Shadows: ONLY floating things (glass chrome, sheets). No coloured glows.
abstract final class MyExShadows {
  static const glass = [
    BoxShadow(color: Color(0x1A3A0F22), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0F3A0F22), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const sheet = [
    BoxShadow(color: Color(0x4014040C), blurRadius: 60, offset: Offset(0, 20)),
  ];
  static const pushEdge = [
    BoxShadow(color: Color(0x1A3A0F22), blurRadius: 30, offset: Offset(-10, 0)),
  ];
}
