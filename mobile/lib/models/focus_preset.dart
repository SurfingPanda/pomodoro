import 'package:flutter/material.dart';

/// A ready-made focus/break configuration shown as a selectable preset card on
/// the Focus screen. The "Custom" option is handled separately by the screen.
class FocusPreset {
  final String name;
  final String tagline;
  final int focusMinutes;
  final int breakMinutes;
  final IconData icon;

  const FocusPreset({
    required this.name,
    required this.tagline,
    required this.focusMinutes,
    required this.breakMinutes,
    required this.icon,
  });
}

/// The built-in presets, in display order. Index 1 (Classic) is the default.
const List<FocusPreset> kFocusPresets = [
  FocusPreset(
    name: 'Quick',
    tagline: 'Warm up',
    focusMinutes: 15,
    breakMinutes: 3,
    icon: Icons.bolt_rounded,
  ),
  FocusPreset(
    name: 'Classic',
    tagline: 'The Pomodoro',
    focusMinutes: 25,
    breakMinutes: 5,
    icon: Icons.local_cafe_rounded,
  ),
  FocusPreset(
    name: 'Deep Work',
    tagline: 'Stay in flow',
    focusMinutes: 50,
    breakMinutes: 10,
    icon: Icons.psychology_rounded,
  ),
  FocusPreset(
    name: 'Flow',
    tagline: 'Long haul',
    focusMinutes: 90,
    breakMinutes: 20,
    icon: Icons.waves_rounded,
  ),
];
