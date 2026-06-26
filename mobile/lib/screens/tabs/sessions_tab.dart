import 'package:flutter/material.dart';

import '../../models/pomodoro_session.dart';
import '../../services/pomodoro_service.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets/log_session_sheet.dart';
import '../../widgets/skeleton.dart';

class SessionsTab extends StatefulWidget {
  const SessionsTab({super.key});

  @override
  State<SessionsTab> createState() => _SessionsTabState();
}

class _SessionsTabState extends State<SessionsTab> {
  final _pomodoro = PomodoroService();

  bool _loading = true;
  String? _error;
  List<PomodoroSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _error = null);
    try {
      final list = await _pomodoro.list();
      if (mounted) setState(() => _sessions = list);
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't load sessions.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logPast() async {
    final result = await showLogSessionSheet(context);
    if (result == null) return;
    try {
      await _pomodoro.log(task: result.task, durationMinutes: result.minutes);
      await _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to log session.')));
      }
    }
  }

  Future<void> _delete(PomodoroSession s) async {
    setState(() => _sessions.remove(s));
    try {
      await _pomodoro.delete(s.id);
    } catch (_) {
      await _refresh();
    }
  }

  int get _totalMinutes => _sessions.fold(0, (sum, s) => sum + s.durationMinutes);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        titleSpacing: 20,
        title: const Text('Sessions', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        onPressed: _logPast,
        icon: const Icon(Icons.add),
        label: const Text('Log session'),
      ),
      body: AppBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: _loading && _sessions.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    children: const [
                      Skeleton(width: double.infinity, height: 84, radius: 20),
                      SizedBox(height: 16),
                      SkeletonList(count: 6),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    children: [
                      if (_error != null)
                        _infoCard(_error!, Icons.cloud_off)
                      else if (_sessions.isEmpty)
                        _infoCard('No sessions yet. Start a focus timer to begin.',
                            Icons.self_improvement)
                      else ...[
                        _summary(),
                        const SizedBox(height: 16),
                        ..._sessions.map(_tile),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _summary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          _summaryItem('${_sessions.length}', 'sessions'),
          Container(width: 1, height: 36, color: AppColors.field),
          _summaryItem(fmtMinutes(_totalMinutes), 'total focus'),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _tile(PomodoroSession s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.timer_outlined, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((s.task == null || s.task!.isEmpty) ? 'Focus session' : s.task!,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text('${s.durationMinutes} min · ${agoLabel(s.completedAt)}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
            onPressed: () => _delete(s),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.muted),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.muted))),
        ],
      ),
    );
  }
}
