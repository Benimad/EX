import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../l10n/app_localizations.dart';
import '../onboarding/application/onboarding_controller.dart';

/// One short message from Mira every night at 22:00 local (cancel survey,
/// "I'm not using it"). Local notification only; tapping opens Coach.
class NightlyCheckinService {
  NightlyCheckinService(this._ref);
  final Ref _ref;

  static const hour = 22;
  static const minute = 0;
  static const _k = 'checkin.nightly';

  bool get enabled => _ref.read(sharedPreferencesProvider).getBool(_k) ?? false;

  /// Asks permission if needed. Returns true when scheduled.
  /// [atHour] defaults to 22:00 (cancel survey); onboarding passes the
  /// user's hardest time (R9).
  Future<bool> enable({int atHour = hour}) async {
    final n = _ref.read(notificationServiceProvider);
    final granted = await n.hasPermission() || await n.requestPermission();
    if (!granted) return false;
    final lang =
        _ref.read(appLocaleProvider)?.languageCode ??
        _ref.read(onboardingProvider).language ??
        'en';
    final l = lookupAppLocalizations(Locale(lang));
    await n.scheduleDaily(
      id: NotificationIds.nightlyCheckin,
      hour: atHour,
      minute: minute,
      title: l.checkinTitle,
      body: l.checkinBody,
      payload: NotificationPayloads.coach,
    );
    await _ref.read(sharedPreferencesProvider).setBool(_k, true);
    return true;
  }

  Future<void> disable() async {
    await _ref
        .read(notificationServiceProvider)
        .cancel(NotificationIds.nightlyCheckin);
    await _ref.read(sharedPreferencesProvider).setBool(_k, false);
  }
}

final nightlyCheckinProvider = Provider<NightlyCheckinService>(
  NightlyCheckinService.new,
);
