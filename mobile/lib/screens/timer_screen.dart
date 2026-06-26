import 'dart:async';

import 'package:flutter/material.dart';

import '../services/pomodoro_service.dart';
import '../theme.dart';
import '../widgets/primary_button.dart';

enum _Phase { running, done }

/// The immersive focus countdown. Started from [FocusTab] with a chosen
/// duration and optional task; it runs full-screen (no bottom nav) to keep the
/// user undistracted. On completion it auto-logs the session via the API and
/// pops `true` so callers can refresh.
class TimerScreen extends StatefulWidget {
  final int focusMinutes;
  final String task;

  const TimerScreen({super.key, required this.focusMinutes, this.task = ''});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final _pomodoro = PomodoroService();

  _Phase _phase = _Phase.running;

  int _totalSeconds = 0;
  int _remaining = 0;
  bool _running = false;
  Timer? _timer;

  bool _logging = false;
  bool _logFailed = false;

  // Seconds-per-minute. Kept as a constant so the timer logic reads naturally.
  static const int _secondsPerMinute = 60;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.focusMinutes * _secondsPerMinute;
    _remaining = _totalSeconds;
    _resume();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resume() {
    _timer?.cancel();
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 1) {
        setState(() => _remaining = 0);
        _complete();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
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
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _complete() async {
    _timer?.cancel();
    setState(() {
      _phase = _Phase.done;
      _running = false;
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
        title: const Text('Focus', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: switch (_phase) {
              _Phase.running => _runningView(),
              _Phase.done => _doneView(),
            },
          ),
        ),
      ),
    );
  }

  // --- Running -------------------------------------------------------------

  Widget _runningView() {
    final progress = _totalSeconds == 0 ? 0.0 : _remaining / _totalSeconds;
    final task = widget.task;
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
                  color: AppColors.accent.withValues(alpha: 0.12),
                ),
              ),
              SizedBox(
                width: 260,
                height: 260,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 14,
                  strokeCap: StrokeCap.round,
                  color: AppColors.accent,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_formatted,
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        fontFeatures: [FontFeature.tabularFigures()],
                      )),
                  Text(_running ? 'focusing…' : 'paused',
                      style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (task.isNotEmpty)
          Text(task,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _giveUp,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.muted,
                side: const BorderSide(color: AppColors.muted),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.stop),
              label: const Text('Give up'),
            ),
            const SizedBox(width: 14),
            FilledButton.icon(
              onPressed: _running ? _pause : _resume,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
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
