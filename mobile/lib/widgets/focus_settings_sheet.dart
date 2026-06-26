import 'package:flutter/material.dart';

import '../theme.dart';
import 'primary_button.dart';

/// A custom focus configuration: focus length, break length, and how many
/// focus sessions to run before a longer break.
class FocusSettings {
  final int focusMinutes;
  final int breakMinutes;
  final int sessionsBeforeLongBreak;

  const FocusSettings({
    required this.focusMinutes,
    required this.breakMinutes,
    required this.sessionsBeforeLongBreak,
  });

  FocusSettings copyWith({int? focusMinutes, int? breakMinutes, int? sessionsBeforeLongBreak}) {
    return FocusSettings(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      sessionsBeforeLongBreak: sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
    );
  }
}

/// Opens the "Customize session" bottom sheet, seeded with [initial]. Returns
/// the edited settings, or null if dismissed.
Future<FocusSettings?> showFocusSettingsSheet(BuildContext context, FocusSettings initial) {
  return showModalBottomSheet<FocusSettings>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _FocusSettingsSheet(initial: initial),
  );
}

class _FocusSettingsSheet extends StatefulWidget {
  final FocusSettings initial;
  const _FocusSettingsSheet({required this.initial});

  @override
  State<_FocusSettingsSheet> createState() => _FocusSettingsSheetState();
}

class _FocusSettingsSheetState extends State<_FocusSettingsSheet> {
  late FocusSettings _settings = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Customize session',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tune the rhythm of your focus and rest.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          _StepperRow(
            icon: Icons.center_focus_strong_rounded,
            color: AppColors.accent,
            title: 'Focus duration',
            subtitle: 'Length of each focus block',
            value: _settings.focusMinutes,
            unit: 'min',
            min: 5,
            max: 120,
            step: 5,
            onChanged: (v) => setState(() => _settings = _settings.copyWith(focusMinutes: v)),
          ),
          const SizedBox(height: 12),
          _StepperRow(
            icon: Icons.coffee_rounded,
            color: AppColors.week,
            title: 'Break duration',
            subtitle: 'Short rest between sessions',
            value: _settings.breakMinutes,
            unit: 'min',
            min: 1,
            max: 45,
            step: 1,
            onChanged: (v) => setState(() => _settings = _settings.copyWith(breakMinutes: v)),
          ),
          const SizedBox(height: 12),
          _StepperRow(
            icon: Icons.repeat_rounded,
            color: AppColors.total,
            title: 'Sessions per cycle',
            subtitle: 'Focus blocks before a long break',
            value: _settings.sessionsBeforeLongBreak,
            unit: _settings.sessionsBeforeLongBreak == 1 ? 'session' : 'sessions',
            min: 2,
            max: 8,
            step: 1,
            onChanged: (v) =>
                setState(() => _settings = _settings.copyWith(sessionsBeforeLongBreak: v)),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Apply',
            onPressed: () => Navigator.of(context).pop(_settings),
          ),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final int value;
  final String unit;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  const _StepperRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
          _RoundButton(
            icon: Icons.remove_rounded,
            enabled: value > min,
            onTap: () => onChanged((value - step).clamp(min, max)),
          ),
          SizedBox(
            width: 58,
            child: Column(
              children: [
                Text('$value',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                Text(unit, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
          _RoundButton(
            icon: Icons.add_rounded,
            enabled: value < max,
            onTap: () => onChanged((value + step).clamp(min, max)),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _RoundButton({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(icon, size: 20, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}
