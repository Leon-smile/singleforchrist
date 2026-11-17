import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Daily "3 o'clock prayer" reminder.
///
/// It is a LOCAL notification: the phone schedules it itself, so it needs no
/// internet, no Wi-Fi and no server. It fires with or without a connection.
class NotificationService {
  NotificationService._();

  /// 24-hour clock. 15 = 3 PM. Change these to move the reminder.
  static const prayerHour = 15;
  static const prayerMinute = 0;

  static const _dailyId = 15;
  static const _testId = 1;
  static const _prefKey = 'prayer_reminder_on';

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'prayer_time',
      'Prayer time',
      channelDescription: "Daily 3 o'clock prayer reminder",
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Repeating scheduled notifications are supported on Android and iOS.
  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Call once in main() before runApp().
  static Future<void> init() async {
    if (!supported || _ready) return;

    // Needed so "3 PM" means 3 PM on THIS phone's clock.
    tzdata.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _ready = true;

    // Re-arm on every launch (also picks up a changed time zone).
    if (await isEnabled()) {
      try {
        await _schedule();
      } catch (e) {
        debugPrint('Could not re-arm the prayer reminder: $e');
      }
    }
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  /// Turns the daily reminder on. Returns false if the user refused the
  /// notification permission.
  static Future<bool> enable() async {
    if (!supported) return false;
    await init();
    if (!await _requestPermission()) return false;
    await _schedule();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    return true;
  }

  static Future<void> disable() async {
    if (supported) {
      await init();
      await _plugin.cancel(id: _dailyId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, false);
  }

  /// Shows a notification right now, so you can check it works without
  /// waiting for 3 PM.
  static Future<void> sendTest() async {
    if (!supported) return;
    await init();
    if (!await _requestPermission()) return;
    await _plugin.show(
      id: _testId,
      title: "3 o'clock prayer",
      body: 'Prayer time. This is a test notification.',
      notificationDetails: _details,
    );
  }

  // ------------------------------------------------------------ internals

  static Future<bool> _requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  /// Next 3:00 PM on the phone's clock (today if it is still ahead,
  /// otherwise tomorrow).
  static tz.TZDateTime _nextPrayerTime() {
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      prayerHour,
      prayerMinute,
    );
    if (!at.isAfter(now)) {
      at = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + 1,
        prayerHour,
        prayerMinute,
      );
    }
    return at;
  }

  static Future<void> _schedule() async {
    // Exact timing needs the "alarms & reminders" permission on Android 12+.
    // Without it the reminder still works but can be a few minutes late.
    var mode = AndroidScheduleMode.inexactAllowWhileIdle;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      var canExact = await android.canScheduleExactNotifications() ?? false;
      if (!canExact) {
        await android.requestExactAlarmsPermission();
        canExact = await android.canScheduleExactNotifications() ?? false;
      }
      if (canExact) mode = AndroidScheduleMode.exactAllowWhileIdle;
    }

    await _plugin.zonedSchedule(
      id: _dailyId,
      title: "3 o'clock prayer",
      body: 'Prayer time, 3 PM.',
      scheduledDate: _nextPrayerTime(),
      notificationDetails: _details,
      androidScheduleMode: mode,
      matchDateTimeComponents: DateTimeComponents.time, // repeat every day
    );
  }
}
