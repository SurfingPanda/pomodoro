import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_settings.dart';
import '../services/notification_service.dart';
import '../services/pomodoro_service.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/primary_button.dart';

enum _Phase { focus, breakTime, awaitingFocus, done }

/// The immersive focus countdown. Started from [FocusTab] with focus/break
/// durations, a cycle length, and an optional task; it runs full-screen (no
/// bottom nav) to keep the user undistracted.
///
/// Flow: focus → break → focus → … with a *long* break after every
/// [sessionsPerCycle] focus blocks. Each completed focus block is logged via
/// the API. Whether the next focus auto-starts after a break is controlled by
/// [AppSettings.autoStartNext]; otherwise the user confirms from an interstitial.
///
/// Each phase boundary fires a notification (sound + vibration per the user's
/// [AppSettings]) scheduled at phase start, so alerts ring even when the app is
/// backgrounded or the screen is off.
class TimerScreen extends StatefulWidget {
  final int focusMinutes;
  final int breakMinutes;
  final int longBreakMinutes;
  final int sessionsPerCycle;
  final String task;

  const TimerScreen({
    super.key,
    required this.focusMinutes,
    this.breakMinutes = 0,
    this.longBreakMinutes = 0,
    this.sessionsPerCycle = 4,
    this.task = '',
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  final _pomodoro = PomodoroService();
  final _notifications = NotificationService.instance;
  final _settings = AppSettings.instance;

  _Phase _phase = _Phase.focus;

  int _totalSeconds = 0;
  int _remaining = 0;
  bool _running = false;
  Timer? _timer;
  DateTime? _endTime; // wall-clock end of the current phase; null while paused

  // Cycle tracking.
  int _round = 0; // current focus block number (1-based), increments each focus
  bool _longBreakNext = false; // is the break after the current focus a long one
  int _completedFocus = 0; // focus blocks finished + logged this run
  int _completedMinutes = 0;

  bool _logging = false;
  int _offlineCount = 0; // focus blocks queued offline (sync pending)

  static const int _secondsPerMinute = 60;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notifications.requestPermissions();
    _startFocus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    if (_phase != _Phase.done) _notifications.cancelAll();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On resume, the suspended periodic timer may have missed the phase
    // boundary — recompute immediately from the wall clock.
    if (state == AppLifecycleState.resumed && _running) _tick();
  }

  int get _notificationId =>
      _phase == _Phase.focus ? NotificationService.focusEndId : NotificationService.breakEndId;

  bool get _hasBreak => widget.breakMinutes > 0;

  // --- Phase transitions ---------------------------------------------------

  void _startFocus() {
    _round++;
    _longBreakNext =
        widget.sessionsPerCycle > 0 && _round % widget.sessionsPerCycle == 0;
    setState(() {
      _phase = _Phase.focus;
      _totalSeconds = widget.focusMinutes * _secondsPerMinute;
      _remaining = _totalSeconds;
    });
    _beginCountdown();
  }

  void _startBreak() {
    final minutes = _longBreakNext ? widget.longBreakMinutes : widget.breakMinutes;
    setState(() {
      _phase = _Phase.breakTime;
      _totalSeconds = minutes * _secondsPerMinute;
      _remaining = _totalSeconds;
    });
    _beginCountdown();
  }

  /// What happens once a break finishes (or is skipped): either auto-start the
  /// next focus block, or wait for the user to confirm.
  void _afterBreak() {
    if (_settings.autoStartNext) {
      _startFocus();
    } else {
      setState(() {
        _phase = _Phase.awaitingFocus;
        _running = false;
        _endTime = null;
      });
    }
  }

  void _beginCountdown() {
    _timer?.cancel();
    final end = DateTime.now().add(Duration(seconds: _remaining));
    setState(() {
      _running = true;
      _endTime = end;
    });
    _scheduleCurrentAlert(end);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!_running || _endTime == null) return;
    final left = _endTime!.difference(DateTime.now()).inSeconds;
    if (left <= 0) {
      setState(() => _remaining = 0);
      _onPhaseEnd();
    } else {
      setState(() => _remaining = left);
    }
  }

  Future<void> _onPhaseEnd() async {
    _timer?.cancel();
    if (_settings.vibrationEnabled) HapticFeedback.heavyImpact();
    if (_phase == _Phase.focus) {
      await _logSession();
      if (!mounted) return;
      _completedFocus++;
      _completedMinutes += widget.focusMinutes;
      if (_hasBreak) {
        _startBreak();
      } else {
        _afterBreak();
      }
    } else {
      _afterBreak();
    }
  }

  void _scheduleCurrentAlert(DateTime end) {
    final sound = _settings.soundEnabled;
    final vibrate = _settings.vibrationEnabled;
    if (_phase == _Phase.focus) {
      final next = !_hasBreak
          ? 'Nice work — you stayed focused!'
          : _longBreakNext
              ? 'Great cycle! Time for a long break.'
              : 'Nice work! Time for a ${widget.breakMinutes}-minute break.';
      _notifications.scheduleAlert(
        id: NotificationService.focusEndId,
        when: end,
        title: 'Focus session complete 🎉',
        body: next,
        playSound: sound,
        vibrate: vibrate,
      );
    } else if (_phase == _Phase.breakTime) {
      _notifications.scheduleAlert(
        id: NotificationService.breakEndId,
        when: end,
        title: _longBreakNext ? 'Long break over ⏰' : 'Break over ⏰',
        body: 'Ready for another focused session?',
        playSound: sound,
        vibrate: vibrate,
      );
    }
  }

  Future<void> _logSession() async {
    setState(() => _logging = true);
    final outcome = await _pomodoro.logOrQueue(
      task: widget.task,
      durationMinutes: widget.focusMinutes,
    );
    if (!mounted) return;
    setState(() {
      _logging = false;
      if (outcome == LogOutcome.queued) _offlineCount++;
    });
  }

  // --- User actions --------------------------------------------------------

  void _pause() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _endTime = null;
    });
    _notifications.cancel(_notificationId);
  }

  void _resume() => _beginCountdown();

  Future<void> _giveUp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Give up this session?'),
        content: const Text("This focus block won't be logged."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: const Text('Give up'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      _timer?.cancel();
      _notifications.cancelAll();
      Navigator.of(context).pop(_completedFocus > 0);
    }
  }

  void _skipBreak() {
    _timer?.cancel();
    _notifications.cancel(NotificationService.breakEndId);
    _afterBreak();
  }

  void _finish() {
    _timer?.cancel();
    _notifications.cancelAll();
    setState(() => _phase = _Phase.done);
  }

  String get _formatted {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(
          _phase == _Phase.breakTime ? 'Break' : 'Focus',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: switch (_phase) {
              _Phase.focus => _runningView(isBreak: false),
              _Phase.breakTime => _runningView(isBreak: true),
              _Phase.awaitingFocus => _awaitingView(),
              _Phase.done => _doneView(),
            },
          ),
        ),
      ),
    );
  }

  // --- Running (focus or break) --------------------------------------------

  Widget _runningView({required bool isBreak}) {
    final progress = _totalSeconds == 0 ? 0.0 : _remaining / _totalSeconds;
    final ringColor = isBreak ? AppColors.streak : AppColors.accent;
    final task = widget.task;
    final statusLabel = _running ? (isBreak ? 'on a break…' : 'focusing…') : 'paused';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _phaseBadge(isBreak: isBreak),
        const SizedBox(height: 18),
        SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 260,
                height: 260,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 14,
                  color: ringColor.withValues(alpha: 0.12),
                ),
              ),
              SizedBox(
                width: 260,
                height: 260,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 14,
                  strokeCap: StrokeCap.round,
                  color: ringColor,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isBreak)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.local_cafe_rounded, color: AppColors.streak, size: 28),
                    ),
                  Text(_formatted,
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        fontFeatures: [FontFeature.tabularFigures()],
                      )),
                  Text(statusLabel, style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (isBreak)
          const Text('Step away and recharge 🐼',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink))
        else if (task.isNotEmpty)
          Text(task,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: isBreak ? _skipBreak : _giveUp,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.muted,
                side: const BorderSide(color: AppColors.muted),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(isBreak ? Icons.skip_next : Icons.stop),
              label: Text(isBreak ? 'Skip break' : 'Give up'),
            ),
            const SizedBox(width: 14),
            FilledButton.icon(
              onPressed: _running ? _pause : _resume,
              style: FilledButton.styleFrom(
                backgroundColor: ringColor,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(_running ? Icons.pause : Icons.play_arrow),
              label: Text(_running ? 'Pause' : 'Resume'),
            ),
          ],
        ),
      ],
    );
  }

  /// Small pill above the ring showing round progress / break type.
  Widget _phaseBadge({required bool isBreak}) {
    final String text;
    if (isBreak) {
      text = _longBreakNext ? 'Long break' : 'Short break';
    } else {
      text = 'Focus $_round of ${widget.sessionsPerCycle}';
    }
    final color = isBreak ? AppColors.streak : AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12.5),
      ),
    );
  }

  // --- Awaiting next focus (auto-start off) --------------------------------

  Widget _awaitingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.self_improvement_rounded, size: 64, color: AppColors.streak),
        const SizedBox(height: 16),
        const Text('Break complete',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 8),
        Text('$_completedFocus focus ${_completedFocus == 1 ? 'block' : 'blocks'} done so far. '
            'Ready for the next one?',
            textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 32),
        SizedBox(
          width: 220,
          child: PrimaryButton(label: 'Start next focus', onPressed: _startFocus),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _finish,
          style: TextButton.styleFrom(foregroundColor: AppColors.muted),
          child: const Text('Finish for now'),
        ),
      ],
    );
  }

  // --- Done ----------------------------------------------------------------

  Widget _doneView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.celebration, size: 72, color: AppColors.accent),
        const SizedBox(height: 16),
        const Text('Session complete!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 8),
        if (_logging)
          const Text('Saving…', style: TextStyle(color: AppColors.muted))
        else if (_offlineCount > 0)
          const Text("Saved offline — we'll sync automatically when you're back online. 🐼",
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted))
        else
          Text(
            _completedFocus <= 1
                ? 'Logged ${widget.focusMinutes} minutes of focus. Nice work! 🐼'
                : 'Logged $_completedFocus focus blocks · ${fmtMinutes(_completedMinutes)}. Nice work! 🐼',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
        const SizedBox(height: 32),
        SizedBox(
          width: 200,
          child: PrimaryButton(
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ),
      ],
    );
  }
}
