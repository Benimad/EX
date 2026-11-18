import 'package:flutter/foundation.dart';

/// Real usage numbers from rpc get_value_recap.
@immutable
class ValueRecap {
  const ValueRecap({
    this.talks = 0,
    this.draftsNotSent = 0,
    this.daysDone = 0,
    this.streakDays = 0,
  });

  factory ValueRecap.fromJson(Map<String, dynamic> j) => ValueRecap(
    talks: (j['talks'] as num?)?.toInt() ?? 0,
    draftsNotSent: (j['drafts_not_sent'] as num?)?.toInt() ?? 0,
    daysDone: (j['days_done'] as num?)?.toInt() ?? 0,
    streakDays: (j['streak_days'] as num?)?.toInt() ?? 0,
  );

  final int talks;
  final int draftsNotSent;
  final int daysDone;
  final int streakDays;
}

enum ReminderKind {
  /// Trial still set to convert: value recap + price + how to cancel.
  trialEnding,

  /// Trial cancelled (won't renew): "Your Premium ends on {date}".
  premiumEnding,
}

/// What the reminder service should do (pure, unit tested).
sealed class ReminderDecision {
  const ReminderDecision();
}

class ScheduleReminder extends ReminderDecision {
  const ScheduleReminder(this.fireAt, this.kind);
  final DateTime fireAt;
  final ReminderKind kind;

  @override
  bool operator ==(Object other) =>
      other is ScheduleReminder && other.fireAt == fireAt && other.kind == kind;
  @override
  int get hashCode => Object.hash(fireAt, kind);
  @override
  String toString() => 'ScheduleReminder($fireAt, $kind)';
}

class CancelReminder extends ReminderDecision {
  const CancelReminder(this.reason);
  final String reason;
  @override
  String toString() => 'CancelReminder($reason)';
}

/// M7: fire 48h before the trial ends, clamped to 10:00–20:00 local, and
/// NEVER later than 48h before billing (early mornings move to 20:00 the
/// evening before, so the promise "2 days before" always holds).
abstract final class ReminderPlan {
  static const leadTime = Duration(hours: 48);
  static const earliestHour = 10;
  static const latestHour = 20;

  /// Don't schedule something that would fire within this window.
  static const minimumLead = Duration(minutes: 5);

  static DateTime clampedFireAt(DateTime expiresAtLocal) {
    final raw = expiresAtLocal.subtract(leadTime);
    if (raw.hour >= latestHour) {
      return DateTime(raw.year, raw.month, raw.day, latestHour);
    }
    if (raw.hour < earliestHour) {
      return DateTime(raw.year, raw.month, raw.day - 1, latestHour);
    }
    return raw;
  }

  static ReminderDecision decide({
    required bool isActive,
    required bool isTrial,
    required bool willRenew,
    required DateTime? expiresAt,
    required bool remindOn,
    required bool permissionGranted,
    required DateTime now,
  }) {
    if (!remindOn) return const CancelReminder('remind off');
    if (!permissionGranted) return const CancelReminder('no permission');
    if (!isActive || !isTrial || expiresAt == null) {
      return const CancelReminder('not in trial');
    }
    final fireAt = clampedFireAt(expiresAt.toLocal());
    if (fireAt.isBefore(now.add(minimumLead))) {
      return const CancelReminder('too late');
    }
    return ScheduleReminder(
      fireAt,
      willRenew ? ReminderKind.trialEnding : ReminderKind.premiumEnding,
    );
  }
}
