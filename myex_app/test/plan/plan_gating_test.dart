import 'package:flutter_test/flutter_test.dart';
import 'package:myex_app/features/plan/domain/plan_models.dart';

/// Display mirror of public.plan_day_status(); the SQL is authoritative and
/// has its own tests in supabase/tests/plan_drafts_test.sql.
void main() {
  PlanDayStatus st(
    int day, {
    Map<int, DateTime> done = const {},
    Set<int> unlocked = const {},
    bool premium = false,
    required DateTime now,
  }) => PlanSchedule.status(
    day: day,
    completions: done,
    unlocked: unlocked,
    premium: premium,
    now: now,
  );

  group('usage day (09:00 local reset)', () {
    test('08:59 belongs to the previous day, 09:00 to the new one', () {
      expect(
        PlanSchedule.usageDay(DateTime(2026, 11, 18, 8, 59)),
        DateTime(2026, 11, 17),
      );
      expect(
        PlanSchedule.usageDay(DateTime(2026, 11, 18, 9)),
        DateTime(2026, 11, 18),
      );
    });

    test('next reset is the next 09:00', () {
      expect(
        PlanSchedule.nextReset(DateTime(2026, 11, 18, 22)),
        DateTime(2026, 11, 19, 9),
      );
      expect(
        PlanSchedule.nextReset(DateTime(2026, 11, 18, 7)),
        DateTime(2026, 11, 18, 9),
      );
    });
  });

  group('access: free covers Days 1–3', () {
    final now = DateTime(2026, 11, 18, 12);
    test('day 1 is open for everyone', () {
      expect(st(1, now: now), PlanDayStatus.open);
    });
    test('day 4 is locked for free users, even with day 3 done', () {
      final done = {
        1: DateTime(2026, 11, 14, 12),
        2: DateTime(2026, 11, 15, 12),
        3: DateTime(2026, 11, 16, 12),
      };
      expect(st(4, done: done, now: now), PlanDayStatus.locked);
      expect(st(4, done: done, premium: true, now: now), PlanDayStatus.open);
      expect(st(4, done: done, unlocked: {4}, now: now), PlanDayStatus.open);
      expect(
        st(5, done: done, unlocked: {4}, now: now),
        PlanDayStatus.locked,
        reason: 'a coin unlock opens one day only',
      );
    });
  });

  group('time gate: one new day per day', () {
    test('day 2 waits when day 1 was done in the same usage day', () {
      final done = {1: DateTime(2026, 11, 18, 10)};
      expect(
        st(2, done: done, now: DateTime(2026, 11, 18, 23)),
        PlanDayStatus.waiting,
      );
      expect(
        st(2, done: done, now: DateTime(2026, 11, 19, 8, 59)),
        PlanDayStatus.waiting,
        reason: 'still before 09:00 the next day',
      );
      expect(
        st(2, done: done, now: DateTime(2026, 11, 19, 9)),
        PlanDayStatus.open,
      );
    });

    test('a day done at 08:00 counts for the previous usage day', () {
      final done = {1: DateTime(2026, 11, 18, 8)};
      expect(
        st(2, done: done, now: DateTime(2026, 11, 18, 9, 30)),
        PlanDayStatus.open,
      );
    });

    test('a day can’t open before the previous one is done', () {
      expect(
        st(3, done: {1: DateTime(2026, 11, 10)}, now: DateTime(2026, 11, 18)),
        PlanDayStatus.waiting,
      );
    });

    test('premium does not skip the time gate', () {
      final done = {1: DateTime(2026, 11, 18, 10)};
      expect(
        st(2, done: done, premium: true, now: DateTime(2026, 11, 18, 11)),
        PlanDayStatus.waiting,
      );
    });

    test('done days stay done', () {
      final done = {1: DateTime(2026, 11, 18, 10)};
      expect(
        st(1, done: done, now: DateTime(2026, 11, 18, 11)),
        PlanDayStatus.done,
      );
    });
  });

  test('current day is the first day not done', () {
    expect(PlanSchedule.currentDay({}), 1);
    expect(PlanSchedule.currentDay({1: DateTime(2026), 2: DateTime(2026)}), 3);
    expect(
      PlanSchedule.currentDay({
        for (var d = 1; d <= planTotalDays; d++) d: DateTime(2026),
      }),
      planTotalDays,
    );
  });

  test('PlanDayDetail: locked content arrives without a prompt', () {
    final d = PlanDayDetail.fromJson({
      'day': 5,
      'minutes': 6,
      'title': 'The unsent letter',
      'promise': 'Say it, without sending it.',
      'status': 'locked',
      'prompt': null,
    });
    expect(d.status, PlanDayStatus.locked);
    expect(d.prompt, isNull);
  });
}
