import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Local notification ids (one slot each, re-scheduling replaces).
abstract final class NotificationIds {
  static const trialReminder = 1001;
  static const nightlyCheckin = 1002;
}

/// Payloads route taps (see [NotificationService.taps]).
abstract final class NotificationPayloads {
  static const trialStatus = 'trial_status';
  static const coach = 'coach';
}

/// Thin interface so scheduling logic is testable without the plugin.
abstract interface class NotificationService {
  Future<void> init();

  /// iOS permission prompt. Call only after an honest in-app pre-prompt.
  Future<bool> requestPermission();
  Future<bool> hasPermission();
  Future<void> scheduleAt({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
  });

  /// Repeats every day at [hour]:[minute] local.
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String payload,
  });
  Future<void> cancel(int id);

  /// Payloads of tapped notifications (including the one that launched us).
  Stream<String> get taps;
}

class LocalNotificationService implements NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<String>.broadcast();
  bool _ready = false;
  String? _launchPayload;

  static const _details = NotificationDetails(
    iOS: DarwinNotificationDetails(),
    android: AndroidNotificationDetails('lifecycle', 'Reminders'),
  );

  @override
  Future<void> init() async {
    if (_ready || kIsWeb) return;
    tzdata.initializeTimeZones();
    try {
      final name = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint('timezone init failed, using UTC: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        // Never prompt at launch: permission is asked on Welcome after an
        // honest in-app explanation.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (r) {
        final p = r.payload;
        if (p != null) _taps.add(p);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _launchPayload = launch?.notificationResponse?.payload;
    }
    _ready = true;
  }

  /// The payload that launched the app, consumed once.
  String? takeLaunchPayload() {
    final p = _launchPayload;
    _launchPayload = null;
    return p;
  }

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> requestPermission() async {
    await init();
    final ios = _ios;
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<bool> hasPermission() async {
    await init();
    final ios = _ios;
    if (ios != null) return (await ios.checkPermissions())?.isEnabled ?? false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.areNotificationsEnabled() ?? false;
  }

  @override
  Future<void> scheduleAt({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
  }) async {
    await init();
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      payload: payload,
    );
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String payload,
  }) async {
    await init();
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: at,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id: id);
  }

  @override
  Stream<String> get taps => _taps.stream;

  Future<void> dispose() => _taps.close();
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final s = LocalNotificationService();
  ref.onDispose(s.dispose);
  return s;
});
