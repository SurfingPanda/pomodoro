import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Wraps flutter_local_notifications for the focus/break timer alerts.
///
/// Alerts are *scheduled* at the moment a phase starts (via [scheduleAlert]),
/// not fired from the in-app countdown — so they ring even if the app is
/// backgrounded or the screen is off, when the Dart timer is suspended. The
/// channel is high-importance with the default system sound and vibration.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'focus_timer';
  static const String _channelName = 'Focus timer';
  static const String _channelDescription =
      'Alerts when a focus session or break ends.';

  bool _initialized = false;

  /// Notification ids — stable so a new schedule replaces the previous one.
  static const int focusEndId = 1001;
  static const int breakEndId = 1002;

  Future<void> init() async {
    if (_initialized) return;

    // Timezone database, required by zonedSchedule. We schedule against UTC
    // using each alert's absolute instant (see [scheduleAlert]), so there's no
    // need to resolve the device's named zone.
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: darwinInit),
    );

    // Create the Android channel up front so its sound/vibration settings stick.
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    _initialized = true;
  }

  /// Asks for notification permission where the OS requires it (Android 13+,
  /// iOS). Safe to call repeatedly; returns true if granted (or not needed).
  Future<bool> requestPermissions() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      return granted ?? true;
    }
    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      playSound: true,
      enableVibration: true,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );

  /// Schedule an alert to fire at [when]. Uses an exact alarm so the timer is
  /// punctual; replaces any existing alert with the same [id].
  Future<void> scheduleAlert({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    await init();
    // Schedule by absolute instant in UTC — fires at the right wall-clock time
    // regardless of the device's named timezone.
    final scheduled = tz.TZDateTime.from(when.toUtc(), tz.UTC);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  Future<void> cancelAll() => _plugin.cancelAll();
}
