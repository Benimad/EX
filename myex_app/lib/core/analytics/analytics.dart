import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import 'events.dart';

export 'events.dart';

/// Where events go. Swap in the vendor adapter without touching features.
abstract interface class AnalyticsSink {
  /// The Supabase uid (also the RevenueCat app user id). No PII.
  void identify(String userId);
  void track(String event, Map<String, Object> props);
}

/// Development sink: prints to the console in debug builds only.
class DebugAnalyticsSink implements AnalyticsSink {
  const DebugAnalyticsSink();

  @override
  void identify(String userId) {
    if (kDebugMode) {
      debugPrint('[analytics] identify ${userId.substring(0, 8)}…');
    }
  }

  @override
  void track(String event, Map<String, Object> props) {
    if (kDebugMode) debugPrint('[analytics] $event $props');
  }
}

/// [ANALYTICS_PROVIDER] adapter (PostHog / Mixpanel / Amplitude). No vendor
/// SDK is installed yet: this deliberately does nothing. When the provider
/// is chosen, add its SDK, forward identify/track here, and disable IDFA
/// collection (first-party analytics, no ATT prompt; VERIFY provider settings).
class ProviderAnalyticsSink implements AnalyticsSink {
  const ProviderAnalyticsSink();
  @override
  void identify(String userId) {}
  @override
  void track(String event, Map<String, Object> props) {}
}

class FanOutSink implements AnalyticsSink {
  const FanOutSink(this.sinks);
  final List<AnalyticsSink> sinks;
  @override
  void identify(String userId) {
    for (final s in sinks) {
      s.identify(userId);
    }
  }

  @override
  void track(String event, Map<String, Object> props) {
    for (final s in sinks) {
      s.track(event, props);
    }
  }
}

/// Context added to every event.
@immutable
class AnalyticsContext {
  const AnalyticsContext({
    required this.locale,
    required this.isPremium,
    this.appVersion = Env.appVersion,
  });
  final String locale;
  final bool isPremium;
  final String appVersion;
}

/// Typed analytics facade (M9). One method per event, allowlisted props,
/// no free-form text. Values must be short tokens, numbers or booleans.
class Analytics {
  Analytics(this._sink, this._context);

  final AnalyticsSink _sink;
  final AnalyticsContext Function() _context;

  /// Longest string value accepted (ids, enums). Longer = dropped.
  static const maxValueLength = 40;

  void identify(String userId) => _sink.identify(userId);

  @visibleForTesting
  void send(AnalyticsEvent e, Map<String, Object?> props) {
    final ctx = _context();
    final clean = <String, Object>{
      'locale': ctx.locale,
      'app_version': ctx.appVersion,
      'is_premium': ctx.isPremium,
    };
    for (final entry in props.entries) {
      final v = entry.value;
      if (v == null) continue;
      if (!e.allowedProps.contains(entry.key)) {
        assert(false, '${e.wire}: property "${entry.key}" is not allowlisted');
        continue;
      }
      if (v is String && (v.length > maxValueLength || v.contains(' '))) {
        assert(false, '${e.wire}: "${entry.key}" looks like free text');
        continue;
      }
      if (v is! String && v is! num && v is! bool) continue;
      clean[entry.key] = v;
    }
    _sink.track(e.wire, clean);
  }

  // ---- Onboarding ----
  void onboardingCompleted({
    String? breakupType,
    String? attachmentStyle,
    String? focus,
  }) => send(AnalyticsEvent.onboardingCompleted, {
    'breakup_type': breakupType,
    'attachment_style': attachmentStyle,
    'focus': focus,
  });
  void onboardingStepViewed({required String step}) =>
      send(AnalyticsEvent.onboardingStepViewed, {'step': step});
  void notifPreprompt({required String result, int? hour}) =>
      send(AnalyticsEvent.notifPreprompt, {'result': result, 'hour': hour});
  void planReadyView() => send(AnalyticsEvent.planReadyView, {});

  // ---- Paywall ----
  void paywallView({
    required String variant,
    required String trigger,
    required String offeringId,
    required bool trialEligible,
  }) => send(AnalyticsEvent.paywallView, {
    'variant': variant,
    'trigger': trigger,
    'offering_id': offeringId,
    'trial_eligible': trialEligible,
  });
  void paywallClosed({
    required String? variant,
    required String trigger,
    required int timeOnScreenMs,
  }) => send(AnalyticsEvent.paywallClosed, {
    'variant': variant,
    'trigger': trigger,
    'time_on_screen_ms': timeOnScreenMs,
  });
  void planSelected({required String productId, required String variant}) =>
      send(AnalyticsEvent.planSelected, {
        'product_id': productId,
        'variant': variant,
      });
  void remindToggle({required bool on}) =>
      send(AnalyticsEvent.remindToggle, {'on': on});

  // ---- Purchases ----
  void purchaseStarted({
    required String productId,
    String? offeringId,
    String? trigger,
    String? variant,
  }) => send(AnalyticsEvent.purchaseStarted, {
    'product_id': productId,
    'offering_id': offeringId,
    'trigger': trigger,
    'variant': variant,
  });
  void purchaseCompleted({
    required String productId,
    String? offeringId,
    String? trigger,
    String? variant,
    required bool isTrial,
  }) => send(AnalyticsEvent.purchaseCompleted, {
    'product_id': productId,
    'offering_id': offeringId,
    'trigger': trigger,
    'variant': variant,
    'is_trial': isTrial,
  });
  void purchaseCancelled({required String productId, String? trigger}) => send(
    AnalyticsEvent.purchaseCancelled,
    {'product_id': productId, 'trigger': trigger},
  );
  void purchaseFailed({required String productId, required String errorCode}) =>
      send(AnalyticsEvent.purchaseFailed, {
        'product_id': productId,
        'error_code': errorCode,
      });
  void purchasePending({required String productId}) =>
      send(AnalyticsEvent.purchasePending, {'product_id': productId});
  void restoreTapped({required String source}) =>
      send(AnalyticsEvent.restoreTapped, {'source': source});
  void restoreCompleted({required bool found}) =>
      send(AnalyticsEvent.restoreCompleted, {'found': found});

  // ---- Exit offer ----
  void exitOfferShown() => send(AnalyticsEvent.exitOfferShown, {});
  void exitOfferClaimed() => send(AnalyticsEvent.exitOfferClaimed, {});
  void exitOfferDismissed() => send(AnalyticsEvent.exitOfferDismissed, {});

  // ---- Limits + coins ----
  void limitHit({required String kind, int? freeUsed}) =>
      send(AnalyticsEvent.limitHit, {'kind': kind, 'free_used': freeUsed});
  void limitSheetAction({required String kind, required String action}) =>
      send(AnalyticsEvent.limitSheetAction, {'kind': kind, 'action': action});
  void coinsStoreView({required String source}) =>
      send(AnalyticsEvent.coinsStoreView, {'source': source});
  void coinsPurchased({required String productId, required int coins}) => send(
    AnalyticsEvent.coinsPurchased,
    {'product_id': productId, 'coins': coins},
  );
  void coinsSpent({required String item, int? cost, int? balanceAfter}) => send(
    AnalyticsEvent.coinsSpent,
    {'item': item, 'cost': cost, 'balance_after': balanceAfter},
  );

  // ---- Product ----
  void planDayCompleted({required int day}) =>
      send(AnalyticsEvent.planDayCompleted, {'day': day});
  void draftLocked({required String origin}) =>
      send(AnalyticsEvent.draftLocked, {'origin': origin});

  // ---- Lifecycle ----
  void trialStatusView({required int daysLeft}) =>
      send(AnalyticsEvent.trialStatusView, {'days_left': daysLeft});
  void winbackShown() => send(AnalyticsEvent.winbackShown, {});
  void winbackClaimed() => send(AnalyticsEvent.winbackClaimed, {});
  void winbackDismissed() => send(AnalyticsEvent.winbackDismissed, {});
  void cancelSurveyShown() => send(AnalyticsEvent.cancelSurveyShown, {});
  void cancelReason({required String reason, String? offerShown}) => send(
    AnalyticsEvent.cancelReason,
    {'reason': reason, 'offer_shown': offerShown},
  );
  void cancelOfferAccepted({required String reason}) =>
      send(AnalyticsEvent.cancelOfferAccepted, {'reason': reason});
  void manageSubscriptionOpened({required String source}) =>
      send(AnalyticsEvent.manageSubscriptionOpened, {'source': source});

  /// Safety monitoring only, never for targeting.
  void sosOpened({required String from}) =>
      send(AnalyticsEvent.sosOpened, {'from': from});
}

/// Replace via override in tests; ProviderAnalyticsSink goes live once a
/// vendor SDK is added.
final analyticsSinkProvider = Provider<AnalyticsSink>(
  (ref) => const FanOutSink([DebugAnalyticsSink(), ProviderAnalyticsSink()]),
);

/// Locale + premium for every event; overridden at app level.
final analyticsContextProvider = Provider<AnalyticsContext>(
  (ref) => AnalyticsContext(
    locale: WidgetsBinding.instance.platformDispatcher.locale.languageCode,
    isPremium: false,
  ),
);

final analyticsProvider = Provider<Analytics>((ref) {
  final sink = ref.watch(analyticsSinkProvider);
  return Analytics(sink, () => ref.read(analyticsContextProvider));
});
