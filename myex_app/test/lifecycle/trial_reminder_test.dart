import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:myex_app/core/notifications/notification_service.dart';
import 'package:myex_app/features/lifecycle/application/trial_reminder_service.dart';
import 'package:myex_app/features/lifecycle/domain/reminder_plan.dart';
import 'package:myex_app/features/monetization/domain/premium_state.dart';

void main() {
  group(
    'ReminderPlan.clampedFireAt (48h before, 10:00–20:00, never later)',
    () {
      test('midday stays exactly 48h before', () {
        expect(
          ReminderPlan.clampedFireAt(DateTime(2026, 11, 24, 14, 30)),
          DateTime(2026, 11, 22, 14, 30),
        );
      });
      test('late evening moves earlier to 20:00 the same day', () {
        expect(
          ReminderPlan.clampedFireAt(DateTime(2026, 11, 24, 23, 15)),
          DateTime(2026, 11, 22, 20),
        );
      });
      test('early morning moves to 20:00 the evening before (not later)', () {
        final end = DateTime(2026, 11, 24, 7);
        final at = ReminderPlan.clampedFireAt(end);
        expect(at, DateTime(2026, 11, 21, 20));
        expect(end.difference(at) >= ReminderPlan.leadTime, isTrue);
      });
    },
  );

  group('ReminderPlan.decide', () {
    final now = DateTime(2026, 11, 18, 12);
    final end = DateTime(2026, 11, 25, 12);
    ReminderDecision d({
      bool active = true,
      bool trial = true,
      bool renew = true,
      bool remind = true,
      bool granted = true,
      DateTime? expires,
    }) => ReminderPlan.decide(
      isActive: active,
      isTrial: trial,
      willRenew: renew,
      expiresAt: expires ?? end,
      remindOn: remind,
      permissionGranted: granted,
      now: now,
    );

    test('active trial → schedule the value-recap reminder', () {
      expect(
        d(),
        ScheduleReminder(DateTime(2026, 11, 23, 12), ReminderKind.trialEnding),
      );
    });
    test('trial cancelled → "Premium ends" copy instead', () {
      expect(
        d(renew: false),
        isA<ScheduleReminder>().having(
          (s) => s.kind,
          'kind',
          ReminderKind.premiumEnding,
        ),
      );
    });
    test(
      'converted (no longer trial), expired, remind off, no permission → cancel',
      () {
        expect(d(trial: false), isA<CancelReminder>());
        expect(d(active: false), isA<CancelReminder>());
        expect(d(remind: false), isA<CancelReminder>());
        expect(d(granted: false), isA<CancelReminder>());
      },
    );
    test('too late to remind → cancel (never a surprise ping at the end)', () {
      expect(
        d(expires: now.add(const Duration(hours: 30))),
        isA<CancelReminder>(),
      );
    });
  });

  group('TrialReminderService', () {
    late _FakeNotifications n;
    DateTime? recorded;
    var remind = true;
    TrialReminderService service() => TrialReminderService(
      notifications: n,
      recap: () async => const ValueRecap(talks: 13, draftsNotSent: 2),
      recordLocalAt: (at) async => recorded = at,
      language: () => 'en',
      remindOn: () => remind,
      clock: () => DateTime(2026, 11, 18, 12),
    );
    final trial = PremiumState(
      isActive: true,
      isTrial: true,
      willRenew: true,
      expiresAt: DateTime(2026, 11, 25, 12),
    );

    tearDown(() => n.close());

    setUp(() {
      n = _FakeNotifications();
      recorded = null;
      remind = true;
    });

    test('schedules once with the real recap numbers', () async {
      await service().sync(trial);
      expect(n.scheduled, hasLength(1));
      final s = n.scheduled.single;
      expect(s.id, NotificationIds.trialReminder);
      expect(s.at, DateTime(2026, 11, 23, 12));
      expect(s.title, 'Your trial ends in 2 days');
      expect(s.body, contains('13 talks with Mira and 2 unsent texts'));
      expect(s.payload, NotificationPayloads.trialStatus);
      expect(recorded, DateTime(2026, 11, 23, 12));
    });

    test('re-sync replaces the same slot (no duplicates)', () async {
      await service().sync(trial);
      await service().sync(trial);
      expect(n.pendingIds, {NotificationIds.trialReminder});
    });

    test('converting cancels it', () async {
      await service().sync(trial);
      await service().sync(
        PremiumState(
          isActive: true,
          willRenew: true,
          expiresAt: DateTime(2027),
        ),
      );
      expect(n.pendingIds, isEmpty);
      expect(recorded, isNull);
    });

    test('cancelling the trial switches to the "ends" copy', () async {
      await service().sync(
        PremiumState(
          isActive: true,
          isTrial: true,
          expiresAt: DateTime(2026, 11, 25, 12),
        ),
      );
      expect(n.scheduled.last.title, 'Your Premium ends soon');
      expect(n.scheduled.last.body, contains('Nov 25'));
    });

    test('remind toggle off → nothing scheduled', () async {
      remind = false;
      await service().sync(trial);
      expect(n.pendingIds, isEmpty);
    });

    test('no permission → nothing scheduled', () async {
      n.granted = false;
      await service().sync(trial);
      expect(n.pendingIds, isEmpty);
    });
  });
}

class _Scheduled {
  _Scheduled(this.id, this.at, this.title, this.body, this.payload);
  final int id;
  final DateTime at;
  final String title;
  final String body;
  final String payload;
}

class _FakeNotifications implements NotificationService {
  bool granted = true;
  final scheduled = <_Scheduled>[];
  final pendingIds = <int>{};
  final _taps = StreamController<String>.broadcast();

  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => granted;
  @override
  Future<bool> hasPermission() async => granted;
  @override
  Future<void> scheduleAt({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
  }) async {
    scheduled.add(_Scheduled(id, at, title, body, payload));
    pendingIds.add(id);
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String payload,
  }) async => pendingIds.add(id);

  @override
  Future<void> cancel(int id) async => pendingIds.remove(id);
  @override
  Stream<String> get taps => _taps.stream;

  Future<void> close() => _taps.close();
}
