import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../workspace/fee_format.dart';

class MonthlyFeeReminders {
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static const _enabledKey = 'monthly_fee_reminders_enabled';
  static const _notificationId = 8101;
  final _notifications = FlutterLocalNotificationsPlugin();
  final _preferences = SharedPreferencesAsync();
  Future<void>? _initialization;

  Future<void> _initialize() => _initialization ??= _setup();

  Future<void> _setup() async {
    tz_data.initializeTimeZones();
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_fee_reminder'),
      ),
    );
  }

  Future<bool> enabled() async =>
      supported && (await _preferences.getBool(_enabledKey) ?? false);

  Future<bool> setEnabled(bool value) async {
    await _initialize();
    if (value) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final allowed = await android?.requestNotificationsPermission();
      if (allowed != true) return false;
    } else {
      await _notifications.cancel(id: _notificationId);
    }
    await _preferences.setBool(_enabledKey, value);
    return true;
  }

  /// Replaces the same repeating notification each time the local balance changes.
  Future<void> schedule(int remainingPaise) async {
    if (!await enabled()) return;
    await _initialize();
    if (remainingPaise <= 0) {
      await _notifications.cancel(id: _notificationId);
      return;
    }
    final zone = await FlutterTimezone.getLocalTimezone();
    final local = tz.getLocation(zone.identifier);
    final now = tz.TZDateTime.now(local);
    final thisMonth = tz.TZDateTime(local, now.year, now.month, 1, 9);
    final next = thisMonth.isAfter(now)
        ? thisMonth
        : tz.TZDateTime(local, now.year, now.month + 1, 1, 9);
    await _notifications.zonedSchedule(
      id: _notificationId,
      title: 'Monthly fee reminder',
      body:
          '${rupees(remainingPaise)} in fees remains unpaid. Open Class Desk for details.',
      scheduledDate: next,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'monthly_fee_reminders',
          'Monthly fee reminders',
          visibility: NotificationVisibility.private,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }
}
