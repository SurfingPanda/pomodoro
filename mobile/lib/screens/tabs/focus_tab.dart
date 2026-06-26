import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/focus_preset.dart';
import '../../theme.dart';
import '../../widgets/focus_ring.dart';
import '../../widgets/focus_settings_sheet.dart';
import '../../widgets/preset_card.dart';
import '../../widgets/primary_button.dart';
import '../timer_screen.dart';

/// The Focus tab: a calm "set up your session" surface that lives inside the
/// main shell, so the bottom navigation bar stays visible. Starting a session
/// pushes the immersive full-screen countdown ([TimerScreen]).
class FocusTab extends StatefulWidget {
  const FocusTab({super.key});

  @override
  State<FocusTab> createState() => _FocusTabState();
}

class _FocusTabState extends State<FocusTab> {
  final _taskController = TextEditingController();

  // Selection across the preset row. Indices 0..n-1 map to [kFocusPresets];
  // [_customIndex] is the trailing "Custom" card backed by [_custom].
  int _selectedIndex = 1; // Classic
  int get _customIndex => kFocusPresets.length;
  FocusSettings _custom =
      const FocusSettings(focusMinutes: 30, breakMinutes: 8, sessionsBeforeLongBreak: 4);

  int get _focusMinutes => _selectedIndex < kFocusPresets.length
      ? kFocusPresets[_selectedIndex].focusMinutes
      : _custom.focusMinutes;
  int get _breakMinutes => _selectedIndex < kFocusPresets.length
      ? kFocusPresets[_selectedIndex].breakMinutes
      : _custom.breakMinutes;
  int get _sessionsPerCycle => _custom.sessionsBeforeLongBreak;

  FocusSettings get _currentSettings => FocusSettings(
        focusMinutes: _focusMinutes,
        breakMinutes: _breakMinutes,
        sessionsBeforeLongBreak: _sessionsPerCycle,
      );

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _openCustomize() async {
    setState(() => _selectedIndex = _customIndex);
    final result = await showFocusSettingsSheet(context, _currentSettings);
    if (result != null && mounted) setState(() => _custom = result);
  }

  Future<void> _start() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TimerScreen(
          focusMinutes: _focusMinutes,
          breakMinutes: _breakMinutes,
          task: _taskController.text.trim(),
        ),
      ),
    );
  }

  /// Wall-clock time the session would end if started now, e.g. "3:45 PM".
  String _endsAt(int minutes) {
    final t = DateTime.now().add(Duration(minutes: minutes));
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$hour12:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        titleSpacing: 20,
        title: const Text('Focus', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: FocusRing(
                          size: math.min(MediaQuery.of(context).size.width * 0.6, 240).toDouble(),
                          child: _ringCenter(),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Ready to Focus?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pick a session, silence the noise, and give your\n'
                        'full attention to one thing at a time.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, height: 1.4),
                      ),
                      const SizedBox(height: 26),
                      _taskCard(),
                      const SizedBox(height: 24),
                      _sectionLabel('Choose your session'),
                      const SizedBox(height: 12),
                      _presetRow(),
                      const SizedBox(height: 18),
                      _infoCard(),
                    ],
                  ),
                ),
              ),
              _stickyStart(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ringCenter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.bolt_rounded, color: AppColors.accent, size: 22),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
          child: Text(
            '$_focusMinutes',
            key: ValueKey(_focusMinutes),
            style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
        ),
        const Text(
          'MIN FOCUS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$_breakMinutes min break',
            style: const TextStyle(
                color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
    );
  }

  Widget _taskCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.edit_note_rounded, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'What are you working on?',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.field,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Optional',
                    style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _taskController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'e.g. Finish the design review',
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetRow() {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: kFocusPresets.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          if (i < kFocusPresets.length) {
            final p = kFocusPresets[i];
            return PresetCard(
              icon: p.icon,
              name: p.name,
              tagline: p.tagline,
              focusLabel: '${p.focusMinutes} min',
              breakLabel: '${p.breakMinutes} min break',
              selected: _selectedIndex == i,
              onTap: () => setState(() => _selectedIndex = i),
            );
          }
          final selected = _selectedIndex == _customIndex;
          return PresetCard(
            icon: Icons.tune_rounded,
            name: 'Custom',
            tagline: 'Your rhythm',
            focusLabel: selected ? '${_custom.focusMinutes} min' : 'Set up',
            breakLabel: selected ? '${_custom.breakMinutes} min break' : 'Tap to edit',
            selected: selected,
            onTap: _openCustomize,
          );
        },
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.streak.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.lightbulb_rounded, color: AppColors.streak, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('The Pomodoro Technique',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 15)),
                    SizedBox(height: 3),
                    Text(
                      'Work in focused sprints with short breaks in '
                      'between. After a few rounds, take a longer rest to recharge.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0x11222933)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.repeat_rounded, size: 16, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Long break every $_sessionsPerCycle sessions',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                ),
              ),
              TextButton.icon(
                onPressed: _openCustomize,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Customize', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stickyStart() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x11222933))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Stay focused until ${_endsAt(_focusMinutes)}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          PrimaryButton(label: 'Start Focus Session', onPressed: _start),
        ],
      ),
    );
  }
}
