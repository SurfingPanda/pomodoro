import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../theme.dart';
import '../utils.dart';

/// User preferences: auto-start cycling, alert sound/vibration, and the daily
/// focus goal. Reads and writes [AppSettings] (persisted locally).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = AppSettings.instance;

  static const int _goalMin = 30;
  static const int _goalMax = 480;
  static const int _goalStep = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              _sectionLabel('Sessions'),
              const SizedBox(height: 10),
              _card([
                _switchRow(
                  icon: Icons.play_circle_outline,
                  color: AppColors.accent,
                  title: 'Auto-start next session',
                  subtitle: 'Begin the next focus block automatically after a break',
                  value: _settings.autoStartNext,
                  onChanged: (v) {
                    setState(() => _settings.autoStartNext = v);
                    _settings.setAutoStartNext(v);
                  },
                ),
              ]),
              const SizedBox(height: 22),
              _sectionLabel('Alerts'),
              const SizedBox(height: 10),
              _card([
                _switchRow(
                  icon: Icons.volume_up_rounded,
                  color: AppColors.week,
                  title: 'Sound',
                  subtitle: 'Play a sound when a session or break ends',
                  value: _settings.soundEnabled,
                  onChanged: (v) {
                    setState(() => _settings.soundEnabled = v);
                    _settings.setSoundEnabled(v);
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0x11222933)),
                _switchRow(
                  icon: Icons.vibration_rounded,
                  color: AppColors.total,
                  title: 'Vibration',
                  subtitle: 'Vibrate when a session or break ends',
                  value: _settings.vibrationEnabled,
                  onChanged: (v) {
                    setState(() => _settings.vibrationEnabled = v);
                    _settings.setVibrationEnabled(v);
                  },
                ),
              ]),
              const SizedBox(height: 22),
              _sectionLabel('Daily goal'),
              const SizedBox(height: 10),
              _card([_goalRow()]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.5)),
      );

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(children: children),
      );

  Widget _switchRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 11.5, height: 1.3)),
              ],
            ),
          ),
          Switch(value: value, activeThumbColor: AppColors.accent, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _goalRow() {
    final goal = _settings.dailyGoalMinutes;
    void setGoal(int v) {
      final clamped = v.clamp(_goalMin, _goalMax);
      setState(() => _settings.dailyGoalMinutes = clamped);
      _settings.setDailyGoalMinutes(clamped);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: AppColors.streak.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.flag_rounded, color: AppColors.streak, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Focus target',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 15)),
                SizedBox(height: 2),
                Text('Goal shown on your dashboard',
                    style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
              ],
            ),
          ),
          _roundBtn(Icons.remove_rounded, goal > _goalMin, () => setGoal(goal - _goalStep)),
          SizedBox(
            width: 64,
            child: Text(fmtMinutes(goal),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
          ),
          _roundBtn(Icons.add_rounded, goal < _goalMax, () => setGoal(goal + _goalStep)),
        ],
      ),
    );
  }

  Widget _roundBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Material(
        color: AppColors.field,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Padding(padding: const EdgeInsets.all(7), child: Icon(icon, size: 20, color: AppColors.ink)),
        ),
      ),
    );
  }
}
