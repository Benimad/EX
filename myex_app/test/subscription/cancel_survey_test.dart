import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myex_app/features/monetization/domain/monetization_ids.dart';
import 'package:myex_app/features/subscription/data/subscription_repository.dart';
import 'package:myex_app/features/subscription/domain/cancel_survey.dart';
import 'package:myex_app/features/subscription/presentation/cancel_survey_sheet.dart';
import 'package:myex_app/l10n/app_localizations.dart';

void main() {
  group('CancelSurvey.offerFor', () {
    CancelOffer offer(
      CancelReason r, {
      String? product = MonetizationIds.annual,
      bool save50 = true,
      int? pct = 67,
    }) => CancelSurvey.offerFor(
      r,
      productId: product,
      save50Available: save50,
      yearlySavingsPct: pct,
    );

    test('price + annual + promo available → half-price promo', () {
      expect(offer(CancelReason.price), isA<Save50Offer>());
    });
    test(
      'price + annual without the promo → no offer (never the intro product)',
      () {
        expect(offer(CancelReason.price, save50: false), isA<ThanksNoOffer>());
      },
    );
    test('price + monthly → switch to yearly with the real savings', () {
      expect(
        offer(CancelReason.price, product: MonetizationIds.monthly),
        isA<SwitchToYearlyOffer>().having((o) => o.savingsPct, 'pct', 67),
      );
      expect(
        offer(CancelReason.price, product: MonetizationIds.monthly, pct: null),
        isA<ThanksNoOffer>(),
      );
    });
    test('better → celebrate, unused → check-in, other → thanks', () {
      expect(offer(CancelReason.better), isA<CelebrateNoOffer>());
      expect(offer(CancelReason.unused), isA<CheckinOffer>());
      expect(offer(CancelReason.other), isA<ThanksNoOffer>());
    });
  });

  group('CancelSurveyBody', () {
    late _Log log;
    late int manageOpened;

    Future<void> pump(
      WidgetTester tester, {
      String? product = MonetizationIds.annual,
      bool withPromo = true,
    }) async {
      log = _Log();
      manageOpened = 0;
      tester.view.physicalSize = const Size(1170, 3000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: CancelSurveyBody(
                  deps: CancelSurveyDeps(
                    productId: product,
                    log: log,
                    openManage: () async => manageOpened++,
                    save50PriceString: withPromo ? r'$24.99' : null,
                    keepWithSave50: withPromo ? () async => true : null,
                    yearlySavingsPct: 67,
                    yearlyPriceString: r'$49.99',
                    switchToYearly: () async => true,
                    enableCheckin: () async => true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('"Continue to Cancel" works at first frame, no reason needed', (
      tester,
    ) async {
      await pump(tester);
      expect(find.byKey(const Key('cancel-continue')), findsOneWidget);
      await tester.tap(find.byKey(const Key('cancel-continue')));
      await tester.pump();
      expect(manageOpened, 1);
      expect(log.records, isEmpty, reason: 'nothing to log without a reason');
    });

    testWidgets('price → promo card; continuing still opens App Store', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('cancel-price')));
      await tester.pump();
      expect(find.byKey(const Key('cancel-offer-save50')), findsOneWidget);
      expect(find.textContaining(r'$24.99'), findsOneWidget);
      await tester.tap(find.byKey(const Key('cancel-continue')));
      await tester.pump();
      expect(manageOpened, 1);
      expect(log.records.single.$1, CancelReason.price);
      expect(log.records.single.$2, MonetizationIds.promoSave50Annual);
      expect(log.records.single.$3, isFalse);
    });

    testWidgets('price without an available promo → no offer shown', (
      tester,
    ) async {
      await pump(tester, withPromo: false);
      await tester.tap(find.byKey(const Key('cancel-price')));
      await tester.pump();
      expect(find.byKey(const Key('cancel-offer-save50')), findsNothing);
      expect(find.byKey(const Key('cancel-continue')), findsOneWidget);
    });

    testWidgets('better → celebrate, no offer; unused → check-in', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('cancel-better')));
      await tester.pump();
      expect(find.textContaining('That’s the whole point'), findsOneWidget);
      await tester.tap(find.byKey(const Key('cancel-unused')));
      await tester.pump();
      expect(find.byKey(const Key('cancel-offer-checkin')), findsOneWidget);
      await tester.tap(find.text('Turn On Check-ins'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3)); // toast
      expect(log.records.last.$1, CancelReason.unused);
      expect(log.records.last.$3, isTrue);
    });
  });
}

class _Log implements CancelSurveyLog {
  final records = <(CancelReason, String?, bool)>[];

  @override
  Future<void> record({
    required CancelReason reason,
    String? offerShown,
    bool offerAccepted = false,
    String? note,
  }) async => records.add((reason, offerShown, offerAccepted));
}
