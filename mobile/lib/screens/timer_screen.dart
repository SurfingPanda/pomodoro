import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/notification_service.dart';
import '../services/pomodoro_service.dart';
import '../theme.dart';
import '../widgets/primary_button.dart';

enum _Phase { focus, breakTime, done }

/// The immersive focus countdown. Started from [FocusTab] with a chosen focus
/// duration, break duration, and optional task; it runs full-screen (no bottom
/// nav) to keep the user undistracted.
///
/// Flow: focus → break → done. When the focus phase ends the session is
/// auto-logged via the API; the break then counts down automatically. Each
/// phase boundary fires a notification (with sound + vibration) scheduled at
/// phase start, so alerts ring even if the app is backgrounded or the screen is
/// off. On finish it pops `true` so callers can refresh.
class TimerScreen extends StatefulWidget {
  final int focusMinutes;
  final int breakMinutes;
  final String task;

  const TimerScreen({
    super.key,
    required this.focusMinutes,
    this.breakMinutes = 0,
    this.task = '',
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  final _pomodoro = PomodoroService();
  final _notifications = NotificationService.instance;

  _Phase _phase = _Phase.focus;

  int _totalSeconds = 0;
  int _remaining = 0;
  bool _running = false;
  Timer? _timer;

  // Wall-clock instant the current phase should end while running. Remaining is
  // derived from this so the countdown stays accurate across app backgrounding
  // (where the periodic timer is suspended). Null while paused.
  DateTime? _endTime;

  bool _logging = false;
  bool _logFailed = false;

  static const int _secondsPerMinute = 60;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notifications.requestPermissions();
    _totalSeconds = widget.focusMinutes * _secondsPerMinute;
    _remaining = _totalSeconds;
    _resume();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    // Leaving the screen before finishing — drop any pending scheduled alerts.
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

  void _resume() {
    _timer?.cancel();
    final end = DateTime.now().add(Duration(seconds: _remaining));
    setState(() {
      _running = true;
      _endTime = end;
    });
    // (Re)schedule this phase's end alert for the new end time.
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

  void _pause() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _endTime = null;
    });
    // Pausing invalidates the scheduled end time; cancel until resumed.
    _notifications.cancel(_notificationId);
  }

  void _scheduleCurrentAlert(DateTime end) {
    if (_phase == _Phase.focus) {
      _notifications.scheduleAlert(
        id: NotificationService.focusEndId,
        when: end,
        title: 'Focus session complete 🎉',
        body: widget.breakMinutes > 0
            ? 'Nice work! Time for a ${widget.breakMinutes}-minute break.'
            : 'Nice work — you stayed focused!',
      );
    } else if (_phase == _Phase.breakTime) {
      _notifications.scheduleAlert(
        id: NotificationService.breakEndId,
        when: end,
        title: 'Break over ⏰',
        body: 'Ready for another focused session?',
      );
    }
  }

  Future<void> _onPhaseEnd() async {
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    if (_phase == _Phase.focus) {
      await _logSession();
      if (!mounted) return;
      if (widget.breakMinutes > 0) {
        _startBreak();
      } else {
        setState(() {
          _phase = _Phase.done;
          _running = false;
          _endTime = null;
        });
      }
    } else {
      // Break finished.
      setState(() {
        _phase = _Phase.done;
        _running = false;
        _endTime = null;
      });
    }
  }

  void _startBreak() {
    setState(() {
      _phase = _Phase.breakTime;
      _totalSeconds = widget.breakMinutes * _secondsPerMinute;
      _remaining = _totalSeconds;
    });
    _resume();
  }

  Future<void> _logSession() async {
    setState(() {
      _logging = true;
      _logFailed = false;
    });
    try {
      await _pomodoro.log(
        task: widget.task,
        durationMinutes: widget.focusMinutes,
      );
    } catch (_) {
      if (mounted) setState(() => _logFailed = true);
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

  Future<void> _giveUp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Give up this session?'),
        content: const Text("It won't be logged."),
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
      Navigator.of(context).pop(false);
    }
  }

  void _skipBreak() {
    _timer?.cancel();
    _notifications.cancel(NotificationService.breakEndId);
    setState(() {
      _phase = _Phase.done;
      _running = false;
      _endTime = null;
    });
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
    final statusLabel = _running
        ? (isBreak ? 'on a break…' : 'focusing…')
        : 'paused';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
                      child: Icon(Icons.local_cafe_rounded,
                          color: AppColors.streak, size: 28),
                    ),
                  Text(_formatted,
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        fontFeatures: [FontFeature.tabularFigures()],
                      )),
                  Text(statusLabel,
                      style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (isBreak)
          const Text('Step away and recharge 🐼',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink))
        else if (task.isNotEmpty)
          Text(task,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
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
        else if (_logFailed)
          const Text('Saved locally, but logging to the server failed.',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted))
        else
          Text('Logged ${widget.focusMinutes} minutes of focus. Nice work! 🐼',
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
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
