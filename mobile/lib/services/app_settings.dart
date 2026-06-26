import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart' show kDailyGoalMinutes;

/// User preferences, persisted locally via shared_preferences.
///
/// Loaded once at startup ([init]); values are read synchronously thereafter.
/// Tabs re-read on rebuild (the shell rebuilds each tab on switch), so changes
/// made on the Settings screen show up the next time a tab is shown.
class AppSettings {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const _kAutoStart = 'auto_start_next';
  static const _kSound = 'sound_enabled';
  static const _kVibration = 'vibration_enabled';
  static const _kGoal = 'daily_goal_minutes';

  SharedPreferences? _prefs;

  /// Automatically begin the next focus session when a break ends.
  bool autoStartNext = true;

  /// Play a sound when a focus session or break ends.
  bool soundEnabled = true;

  /// Vibrate when a focus session or break ends.
  bool vibrationEnabled = true;

  /// Target focused minutes per day (drives the dashboard goal ring).
  int dailyGoalMinutes = kDailyGoalMinutes;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _prefs = p;
    autoStartNext = p.getBool(_kAutoStart) ?? autoStartNext;
    soundEnabled = p.getBool(_kSound) ?? soundEnabled;
    vibrationEnabled = p.getBool(_kVibration) ?? vibrationEnabled;
    dailyGoalMinutes = p.getInt(_kGoal) ?? dailyGoalMinutes;
  }

  Future<void> setAutoStartNext(bool v) async {
    autoStartNext = v;
    await _prefs?.setBool(_kAutoStart, v);
  }

  Future<void> setSoundEnabled(bool v) async {
    soundEnabled = v;
    await _prefs?.setBool(_kSound, v);
  }

  Future<void> setVibrationEnabled(bool v) async {
    vibrationEnabled = v;
    await _prefs?.setBool(_kVibration, v);
  }

  Future<void> setDailyGoalMinutes(int v) async {
    dailyGoalMinutes = v;
    await _prefs?.setInt(_kGoal, v);
  }
}
