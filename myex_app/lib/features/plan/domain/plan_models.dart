import 'package:flutter/foundation.dart';

import '../../monetization/domain/monetization_ids.dart';

const planTotalDays = 30;

/// Display mirror of public.plan_day_status() (the server decides).
enum PlanDayStatus {
  done,
  open,

  /// Accessible, but not yet: the previous day isn't done, or it was done
  /// today and the next day opens at 09:00 local tomorrow.
  waiting,

  /// Needs Premium or a coin unlock.
  locked,
}

enum PlanStage { week1, week2, week3, rebuild }

@immutable
class PlanDayTeaser {
  const PlanDayTeaser({
    required this.day,
    required this.stage,
    required this.minutes,
    required this.title,
    required this.promise,
  });

  factory PlanDayTeaser.fromRow(Map<String, dynamic> r, String lang) =>
      PlanDayTeaser(
        day: (r['day'] as num).toInt(),
        stage: PlanStage.values.firstWhere(
          (s) => s.name == r['stage'],
          orElse: () => PlanStage.week1,
        ),
        minutes: (r['minutes'] as num).toInt(),
        title: (lang == 'tr' ? r['title_tr'] : r['title_en']) as String,
        promise: (lang == 'tr' ? r['promise_tr'] : r['promise_en']) as String,
      );

  final int day;
  final PlanStage stage;
  final int minutes;
  final String title;
  final String promise;
}

/// One day's full content (from rpc get_plan_day).
@immutable
class PlanDayDetail {
  const PlanDayDetail({
    required this.day,
    required this.minutes,
    required this.title,
    required this.promise,
    required this.status,
    this.prompt,
    this.entries,
  });

  factory PlanDayDetail.fromJson(Map<String, dynamic> j) => PlanDayDetail(
    day: (j['day'] as num).toInt(),
    minutes: (j['minutes'] as num).toInt(),
    title: j['title'] as String,
    promise: j['promise'] as String,
    status: PlanDayStatus.values.firstWhere(
      (s) => s.name == j['status'],
      orElse: () => PlanDayStatus.locked,
    ),
    prompt: j['prompt'] as String?,
    entries: (j['entries'] as List<dynamic>?)?.cast<String>(),
  );

  final int day;
  final int minutes;
  final String title;
  final String promise;
  final PlanDayStatus status;

  /// Null when locked: locked content never reaches the client.
  final String? prompt;
  final List<String>? entries;
}

/// Pure plan gating (unit tested). Mirrors the SQL functions
/// can_access_plan_day / plan_day_status / usage_day_for.
abstract final class PlanSchedule {
  /// The daily reset hour (09:00 local), same as the message limit.
  static const resetHour = 9;

  /// The usage day a local moment belongs to (resets at 09:00 local).
  static DateTime usageDay(DateTime local) {
    final shifted = local.subtract(const Duration(hours: resetHour));
    return DateTime(shifted.year, shifted.month, shifted.day);
  }

  /// When the next usage day starts (the next 09:00 local after [now]).
  static DateTime nextReset(DateTime now) {
    final d = usageDay(now);
    return DateTime(d.year, d.month, d.day + 1, resetHour);
  }

  static bool canAccess({
    required int day,
    required bool premium,
    required Set<int> unlocked,
  }) =>
      day <= MonetizationDisplay.freePlanDays ||
      premium ||
      unlocked.contains(day);

  static PlanDayStatus status({
    required int day,
    required Map<int, DateTime> completions,
    required Set<int> unlocked,
    required bool premium,
    required DateTime now,
  }) {
    if (completions.containsKey(day)) return PlanDayStatus.done;
    if (!canAccess(day: day, premium: premium, unlocked: unlocked)) {
      return PlanDayStatus.locked;
    }
    if (day == 1) return PlanDayStatus.open;
    final prev = completions[day - 1];
    if (prev == null) return PlanDayStatus.waiting;
    return usageDay(prev.toLocal()).isBefore(usageDay(now))
        ? PlanDayStatus.open
        : PlanDayStatus.waiting;
  }

  /// The day the user is on: the first day that isn't done (1…30).
  static int currentDay(Map<int, DateTime> completions) {
    for (var d = 1; d <= planTotalDays; d++) {
      if (!completions.containsKey(d)) return d;
    }
    return planTotalDays;
  }
}

/// Everything the Plan tab shows.
@immutable
class PlanState {
  const PlanState({
    required this.teasers,
    required this.completions,
    required this.unlocked,
    required this.premium,
    required this.now,
  });

  final List<PlanDayTeaser> teasers;
  final Map<int, DateTime> completions;
  final Set<int> unlocked;
  final bool premium;
  final DateTime now;

  PlanDayStatus statusOf(int day) => PlanSchedule.status(
    day: day,
    completions: completions,
    unlocked: unlocked,
    premium: premium,
    now: now,
  );

  int get currentDay => PlanSchedule.currentDay(completions);
  int get doneCount => completions.length;
  bool get finished => doneCount >= planTotalDays;
}
