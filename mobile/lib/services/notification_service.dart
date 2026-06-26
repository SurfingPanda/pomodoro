import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Wraps flutter_local_notifications for the focus/break timer alerts.
///
/// Alerts are *scheduled* at the moment a phase starts (via [scheduleAlert]),
/// not fired from the in-app countdown — so they ring even if the app is
/// backgrounded or the screen is off, when the Dart timer is suspended.
///
/// Sound and vibration are channel-level settings on Android 8+, so each
/// (sound, vibration) combination uses its own high-importance channel; the
/// caller picks one to honour the user's preferences.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  final Set<String> _createdChannels = {};

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

  String _channelId(bool sound, bool vibration) =>
      'focus_timer_s${sound ? 1 : 0}_v${vibration ? 1 : 0}';

  Future<AndroidNotificationDetails> _androidDetails(
      bool sound, bool vibration) async {
    final id = _channelId(sound, vibration);
    final name = 'Focus timer'
        '${sound ? '' : ' (silent)'}${vibration ? '' : ' (no vibration)'}';
    if (!_createdChannels.contains(id)) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(
        AndroidNotificationChannel(
          id,
          name,
          description: 'Alerts when a focus session or break ends.',
          importance: Importance.max,
          playSound: sound,
          enableVibration: vibration,
        ),
      );
      _createdChannels.add(id);
    }
    return AndroidNotificationDetails(
      id,
      name,
      channelDescription: 'Alerts when a focus session or break ends.',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      playSound: sound,
      enableVibration: vibration,
    );
  }

  /// Schedule an alert to fire at [when]. Uses an exact alarm so the timer is
  /// punctual; replaces any existing alert with the same [id]. [playSound] and
  /// [vibrate] honour the user's notification preferences.
  Future<void> scheduleAlert({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    bool playSound = true,
    bool vibrate = true,
  }) async {
    await init();
    final android = await _androidDetails(playSound, vibrate);
    final details = NotificationDetails(
      android: android,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: playSound,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
    // Schedule by absolute instant in UTC — fires at the right wall-clock time
    // regardless of the device's named timezone.
    final scheduled = tz.TZDateTime.from(when.toUtc(), tz.UTC);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  Future<void> cancelAll() => _plugin.cancelAll();
}
