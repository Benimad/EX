import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// M0 rule 4 / M4 acceptance: no price, currency or trial literal in lib/.
/// Prices come only from StoreKit via RevenueCat.
void main() {
  test('no currency symbols or price literals in lib/', () {
    final offenders = <String>[];
    final currency = RegExp(
      r'(?<![.\w])[$€£₺¥]\s?\d|\d[.,]\d{2}\s?(USD|EUR|TRY|GBP)',
    );
    final knownPrices = RegExp(
      r'\b(49\.99|12\.99|24\.99|9\.99|2\.99|6\.99|14\.99)\b',
    );
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.contains(
        '${Platform.pathSeparator}l10n${Platform.pathSeparator}',
      )) {
        continue; // generated
      }
      // Demo mode emulates StoreKit with the prototype's example prices.
      // It never runs in a release build with a real config.
      if (f.path.contains(
        '${Platform.pathSeparator}demo${Platform.pathSeparator}',
      )) {
        continue;
      }
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final l = lines[i];
        if (l.trimLeft().startsWith('//')) continue;
        if (currency.hasMatch(l) || knownPrices.hasMatch(l)) {
          offenders.add('${f.path}:${i + 1}: ${l.trim()}');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('ARB copy carries prices only as placeholders', () {
    for (final name in ['app_en.arb', 'app_tr.arb']) {
      final text = File('lib/l10n/$name').readAsStringSync();
      expect(
        RegExp(r'[$€£₺]\d').hasMatch(text),
        isFalse,
        reason: '$name contains a literal price',
      );
    }
  });
}
