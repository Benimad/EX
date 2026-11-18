import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../monetization/domain/premium_state.dart';
import '../../onboarding/application/onboarding_controller.dart';
import '../data/lifecycle_repository.dart';
import '../domain/reminder_plan.dart';

/// Keeps the "2 days before your trial ends" local notification in sync
/// with the entitlement (M7). Called after purchase, on every foreground and
/// whenever CustomerInfo changes. Cancelled on convert, cancel or expiry; the
/// copy switches to "Premium ends on…" when the trial won't renew.
class TrialReminderService {
  TrialReminderService({
    required this.notifications,
    required this.recap,
    required this.recordLocalAt,
    required this.language,
    required this.remindOn,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final NotificationService notifications;
  final Future<ValueRecap> Function() recap;
  final Future<void> Function(DateTime? at) recordLocalAt;
  final String Function() language;
  final bool Function() remindOn;
  final DateTime Function() _now;

  /// Returns the decision that was applied (handy for tests and logs).
  Future<ReminderDecision> sync(PremiumState premium) async {
    final granted = await notifications.hasPermission();
    final decision = ReminderPlan.decide(
      isActive: premium.isActive,
      isTrial: premium.isTrial,
      willRenew: premium.willRenew,
      expiresAt: premium.expiresAt,
      remindOn: remindOn(),
      permissionGranted: granted,
      now: _now(),
    );
    switch (decision) {
      case CancelReminder():
        await notifications.cancel(NotificationIds.trialReminder);
        await _record(null);
      case ScheduleReminder(:final fireAt, :final kind):
        final l = lookupAppLocalizations(Locale(language()));
        // May run outside the widget tree (foreground resume): make sure the
        // date symbols for this locale are loaded.
        await initializeDateFormatting(l.localeName);
        final (title, body) = switch (kind) {
          ReminderKind.trialEnding => await _trialCopy(l),
          ReminderKind.premiumEnding => (
            l.reminderEndingTitle,
            l.reminderEndingBody(
              DateFormat.MMMd(
                l.localeName,
              ).format(premium.expiresAt!.toLocal()),
            ),
          ),
        };
        // Same id → re-scheduling replaces, with fresh recap numbers.
        await notifications.scheduleAt(
          id: NotificationIds.trialReminder,
          at: fireAt,
          title: title,
          body: body,
          payload: NotificationPayloads.trialStatus,
        );
        await _record(fireAt);
    }
    return decision;
  }

  Future<(String, String)> _trialCopy(AppLocalizations l) async {
    try {
      final r = await recap();
      if (r.talks + r.draftsNotSent > 0) {
        return (
          l.reminderTrialTitle,
          l.reminderTrialBody(r.talks, r.draftsNotSent),
        );
      }
    } catch (e) {
      debugPrint('recap failed, generic reminder copy: $e');
    }
    return (l.reminderTrialTitle, l.reminderTrialBodyEmpty);
  }

  Future<void> _record(DateTime? at) async {
    try {
      await recordLocalAt(at);
    } catch (_) {
      // Bookkeeping only.
    }
  }
}

final trialReminderServiceProvider = Provider<TrialReminderService>((ref) {
  final repo = ref.watch(lifecycleRepositoryProvider);
  return TrialReminderService(
    notifications: ref.watch(notificationServiceProvider),
    recap: repo.recap,
    recordLocalAt: repo.setTrialReminderLocalAt,
    language: () =>
        ref.read(appLocaleProvider)?.languageCode ??
        ref.read(onboardingProvider).language ??
        'en',
    remindOn: () => ref.read(remindTrialProvider),
  );
});
