import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myex_app/features/home/application/streak.dart';
import 'package:myex_app/features/monetization/presentation/widgets/status_chips.dart';
import 'package:myex_app/features/sos/presentation/sos_screen.dart';
import 'package:myex_app/l10n/app_localizations.dart';

/// M0 HARD RULE 1: SOS + the crisis sheet never show a paywall, limit, coin
/// price, upsell or premium badge.
void main() {
  test('lib/features/sos imports nothing from monetization', () {
    for (final f in Directory('lib/features/sos').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      expect(
        RegExp("import '[^']*monetization[^']*'").hasMatch(src),
        isFalse,
        reason: '${f.path} imports monetization code',
      );
    }
  });

  for (final locale in const [Locale('en'), Locale('tr')]) {
    testWidgets('SOS + crisis sheet show no monetization UI ($locale)', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [noContactSinceProvider.overrideWith((ref) async => null)],
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SosScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      void expectClean() {
        expect(find.byType(CoinChip), findsNothing);
        for (final word in [
          'Premium',
          'coin',
          'Coin',
          'jeton',
          'Jeton',
          'Subscribe',
          'Abone',
          'abone',
          'Try Free',
          'limit',
          'sınır',
        ]) {
          // "no limits"/"sınırsız" is the reassurance tag itself; check
          // there is no *limit sheet* wording instead.
          if (word == 'limit' || word == 'sınır') continue;
          expect(
            find.textContaining(word, findRichText: true),
            findsNothing,
            reason: 'found "$word" on SOS',
          );
        }
      }

      expectClean();

      await tester.tap(find.byKey(const Key('sos-urgent')));
      // The breathing animation repeats forever: pump fixed frames instead
      // of pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(BottomSheet), findsOneWidget);
      expectClean();
    });
  }
}
