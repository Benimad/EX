import 'package:flutter_test/flutter_test.dart';
import 'package:myex_app/core/analytics/analytics.dart';

void main() {
  late _Recorder sink;
  late Analytics a;

  setUp(() {
    sink = _Recorder();
    a = Analytics(
      sink,
      () => const AnalyticsContext(
        locale: 'tr',
        isPremium: false,
        appVersion: '1.2.3',
      ),
    );
  });

  test('every typed method stays inside its allowlist + common props', () {
    a
      ..onboardingCompleted(
        breakupType: 'they_ended',
        attachmentStyle: 'anxious',
        focus: 'noContact',
      )
      ..onboardingStepViewed(step: 'contact')
      ..notifPreprompt(result: 'allowed', hour: 22)
      ..planReadyView()
      ..paywallView(
        variant: 'timeline',
        trigger: 'onboarding',
        offeringId: 'default',
        trialEligible: true,
      )
      ..paywallClosed(
        variant: 'timeline',
        trigger: 'onboarding',
        timeOnScreenMs: 4200,
      )
      ..planSelected(productId: 'myex_premium_annual', variant: 'timeline')
      ..remindToggle(on: false)
      ..purchaseStarted(
        productId: 'p',
        offeringId: 'default',
        trigger: 'me',
        variant: 'compare',
      )
      ..purchaseCompleted(productId: 'p', isTrial: true)
      ..purchaseCancelled(productId: 'p', trigger: 'me')
      ..purchaseFailed(productId: 'p', errorCode: 'networkError')
      ..purchasePending(productId: 'p')
      ..restoreTapped(source: 'paywall')
      ..restoreCompleted(found: true)
      ..exitOfferShown()
      ..exitOfferClaimed()
      ..exitOfferDismissed()
      ..limitHit(kind: 'message', freeUsed: 3)
      ..limitSheetAction(kind: 'message', action: 'premium')
      ..coinsStoreView(source: 'home')
      ..coinsPurchased(productId: 'coins_80', coins: 90)
      ..coinsSpent(item: 'plan_day', cost: 15, balanceAfter: 5)
      ..planDayCompleted(day: 3)
      ..draftLocked(origin: 'sos')
      ..trialStatusView(daysLeft: 5)
      ..winbackShown()
      ..winbackClaimed()
      ..winbackDismissed()
      ..cancelSurveyShown()
      ..cancelReason(reason: 'price', offerShown: 'save50_annual')
      ..cancelOfferAccepted(reason: 'price')
      ..manageSubscriptionOpened(source: 'me')
      ..sosOpened(from: 'tab_bar');

    expect(
      sink.events.map((e) => e.$1).toSet(),
      AnalyticsEvent.values.map((e) => e.wire).toSet(),
      reason: 'every event has a typed method',
    );
    for (final (name, props) in sink.events) {
      final e = AnalyticsEvent.values.firstWhere((e) => e.wire == name);
      expect(
        props.keys.toSet().difference(AnalyticsEvent.commonProps),
        everyElement(isIn(e.allowedProps)),
        reason: name,
      );
      expect(props['locale'], 'tr');
      expect(props['app_version'], '1.2.3');
      expect(props['is_premium'], isFalse);
      for (final v in props.values) {
        expect(v is String || v is num || v is bool, isTrue);
        if (v is String) {
          expect(v.length, lessThanOrEqualTo(Analytics.maxValueLength));
          expect(v.contains(' '), isFalse, reason: 'no free text in $name');
        }
      }
    }
  });

  test('free text and unknown keys never reach the sink', () {
    // Release behaviour (asserts are off there): the value is dropped.
    expect(
      () => a.send(AnalyticsEvent.cancelReason, {
        'reason': 'price',
        'note': 'I miss him so much',
      }),
      throwsA(isA<AssertionError>()),
      reason: 'debug builds fail loudly',
    );
    expect(
      () =>
          a.send(AnalyticsEvent.draftLocked, {'origin': 'please text me back'}),
      throwsA(isA<AssertionError>()),
    );
  });

  test('null values are omitted', () {
    a.purchaseStarted(productId: 'p');
    expect(sink.events.single.$2.containsKey('offering_id'), isFalse);
  });
}

class _Recorder implements AnalyticsSink {
  final events = <(String, Map<String, Object>)>[];
  @override
  void identify(String userId) {}
  @override
  void track(String event, Map<String, Object> props) =>
      events.add((event, props));
}
