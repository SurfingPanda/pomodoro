import 'package:flutter/material.dart';

import '../../models/pomodoro_session.dart';
import '../../services/auth_service.dart';
import '../../services/pomodoro_service.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/weekly_chart.dart';

class DashboardTab extends StatefulWidget {
  /// Called when the user taps "Start focus"; the shell switches to the
  /// Focus tab so the bottom navigation bar stays consistent.
  final VoidCallback? onStartFocus;

  const DashboardTab({super.key, this.onStartFocus});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final _auth = AuthService();
  final _pomodoro = PomodoroService();

  bool _loading = true;
  String? _error;
  PomodoroStats? _stats;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _error = null);
    try {
      final stats = await _pomodoro.stats();
      if (mounted) setState(() => _stats = stats);
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't reach the API. Is the server running?");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        titleSpacing: 20,
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        onPressed: widget.onStartFocus,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start focus'),
      ),
      body: AppBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                _greeting(),
                const SizedBox(height: 16),
                if (_loading && _stats == null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      SkeletonHero(),
                      SizedBox(height: 14),
                      SkeletonTilesRow(),
                      SizedBox(height: 20),
                      SkeletonChart(),
                    ],
                  )
                else if (_error != null)
                  _errorCard(_error!)
                else ...[
                  _heroCard(),
                  const SizedBox(height: 14),
                  _statTiles(),
                  const SizedBox(height: 20),
                  WeeklyChart(
                    daily: _stats!.daily,
                    weekMinutes: _stats!.weekMinutes,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _greeting() {
    final name = _auth.currentUser?.userMetadata?['name'] as String? ?? 'there';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hi, $name 👋',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 2),
        Text(dateLabel(), style: const TextStyle(color: AppColors.muted, fontSize: 13)),
      ],
    );
  }

  Widget _heroCard() {
    final mins = _stats?.todayMinutes ?? 0;
    final sessions = _stats?.todaySessions ?? 0;
    final progress = (mins / kDailyGoalMinutes).clamp(0.0, 1.0);
    final pct = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.accentDark],
        ),
        boxShadow: [
          BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.bolt, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text('Focused today',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(fmtMinutes(mins),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, height: 1)),
                const SizedBox(height: 6),
                Text('$sessions ${sessions == 1 ? 'session' : 'sessions'} · goal ${fmtMinutes(kDailyGoalMinutes)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 92, height: 92,
                  child: CircularProgressIndicator(
                      value: 1, strokeWidth: 9, color: Colors.white.withValues(alpha: 0.25)),
                ),
                SizedBox(
                  width: 92, height: 92,
                  child: CircularProgressIndicator(
                      value: progress, strokeWidth: 9, strokeCap: StrokeCap.round, color: Colors.white),
                ),
                Text('$pct%',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTiles() {
    final s = _stats;
    return Row(
      children: [
        Expanded(child: _statTile(Icons.local_fire_department, AppColors.streak, '${s?.streakDays ?? 0}', 'day streak')),
        const SizedBox(width: 12),
        Expanded(child: _statTile(Icons.calendar_today_rounded, AppColors.week, fmtMinutes(s?.weekMinutes ?? 0), 'this week')),
        const SizedBox(width: 12),
        Expanded(child: _statTile(Icons.workspace_premium_rounded, AppColors.total, '${s?.totalSessions ?? 0}', 'sessions')),
      ],
    );
  }

  Widget _statTile(IconData icon, Color color, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          FittedBox(
            child: Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink)),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _errorCard(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: AppColors.muted),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.muted))),
        ],
      ),
    );
  }
}
