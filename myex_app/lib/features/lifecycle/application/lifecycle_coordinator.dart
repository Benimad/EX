import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../monetization/application/monetization_providers.dart';
import '../../monetization/domain/premium_state.dart';
import '../../onboarding/application/onboarding_controller.dart';
import '../data/lifecycle_repository.dart';
import 'trial_reminder_service.dart';

/// App-level lifecycle glue (M7), mounted once above the router:
/// * re-syncs the trial reminder on every foreground and entitlement change
///   (fresh recap numbers, cancel on convert/cancel/expiry);
/// * routes notification taps (launch included) to Trial status;
/// * shows Win-back once per user, 7–14 days after Premium lapsed.
class LifecycleCoordinator extends ConsumerStatefulWidget {
  const LifecycleCoordinator({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<LifecycleCoordinator> createState() =>
      _LifecycleCoordinatorState();
}

class _LifecycleCoordinatorState extends ConsumerState<LifecycleCoordinator> {
  AppLifecycleListener? _life;
  StreamSubscription<String>? _taps;
  bool _winbackChecked = false;

  @override
  void initState() {
    super.initState();
    _life = AppLifecycleListener(onResume: _syncReminder);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (uid != null) ref.read(analyticsProvider).identify(uid);
    final notifications = ref.read(notificationServiceProvider);
    try {
      await notifications.init();
    } catch (e) {
      debugPrint('notifications init failed: $e');
    }
    if (!mounted) return;
    _taps = notifications.taps.listen(_route);
    if (notifications is LocalNotificationService) {
      final p = notifications.takeLaunchPayload();
      if (p != null) _route(p);
    }
    await _syncReminder();
    if (!mounted) return;
    await _maybeWinback();
  }

  void _route(String payload) {
    if (!mounted) return;
    final router = ref.read(appRouterProvider);
    switch (payload) {
      case NotificationPayloads.trialStatus:
        router.push(Routes.trial);
      case NotificationPayloads.coach:
        router.go(Routes.coach);
    }
  }

  Future<void> _syncReminder([PremiumState? p]) async {
    if (!mounted) return;
    final premium = p ?? ref.read(premiumProvider).value;
    if (premium == null) return;
    try {
      await ref.read(trialReminderServiceProvider).sync(premium);
    } catch (e) {
      debugPrint('reminder sync failed: $e');
    }
  }

  Future<void> _maybeWinback() async {
    if (_winbackChecked || !ref.read(onboardingProvider).completed) return;
    _winbackChecked = true;
    try {
      final repo = ref.read(lifecycleRepositoryProvider);
      if (!await repo.winbackEligible() || !mounted) return;
      if (!await repo.markWinbackShown()) return; // shown elsewhere already
      if (!mounted) return;
      unawaited(ref.read(appRouterProvider).push(Routes.winback));
    } catch (e) {
      debugPrint('winback check failed: $e');
    }
  }

  @override
  void dispose() {
    _life?.dispose();
    _taps?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(premiumProvider, (prev, next) {
      final v = next.value;
      if (v != null && v != prev?.value) _syncReminder(v);
    });
    return widget.child;
  }
}
