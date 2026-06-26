import 'package:flutter/material.dart';

import '../../models/pomodoro_session.dart';
import '../../services/pomodoro_service.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/weekly_chart.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
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
      if (mounted) setState(() => _error = "Couldn't load stats.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _stats;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        titleSpacing: 20,
        title: const Text('Stats', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: _loading && s == null
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    children: const [
                      SkeletonHero(height: 150),
                      SizedBox(height: 16),
                      SkeletonTilesRow(count: 2, height: 96),
                      SizedBox(height: 12),
                      SkeletonTilesRow(count: 2, height: 96),
                      SizedBox(height: 20),
                      SkeletonChart(),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    children: [
                      if (_error != null)
                        _infoCard(_error!)
                      else if (s != null) ...[
                        _totalCard(s),
                        const SizedBox(height: 16),
                        _metricsGrid(s),
                        const SizedBox(height: 20),
                        WeeklyChart(daily: s.daily, weekMinutes: s.weekMinutes),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _totalCard(PomodoroStats s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.total, Color(0xFF4F46E5)],
        ),
        boxShadow: [
          BoxShadow(color: AppColors.total.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.hourglass_bottom, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text('Total focus time', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(fmtMinutes(s.totalMinutes),
              style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800, height: 1)),
          const SizedBox(height: 6),
          Text('across ${s.totalSessions} ${s.totalSessions == 1 ? 'session' : 'sessions'}',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _metricsGrid(PomodoroStats s) {
    final avg = s.totalSessions == 0 ? 0 : (s.totalMinutes / s.totalSessions).round();
    final tiles = [
      _Metric(Icons.local_fire_department, AppColors.streak, '${s.streakDays}', 'Day streak'),
      _Metric(Icons.calendar_today_rounded, AppColors.week, fmtMinutes(s.weekMinutes), 'This week'),
      _Metric(Icons.today_rounded, AppColors.accent, fmtMinutes(s.todayMinutes), 'Today'),
      _Metric(Icons.av_timer_rounded, AppColors.total, '${avg}m', 'Avg session'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: tiles.map(_metricCard).toList(),
    );
  }

  Widget _metricCard(_Metric m) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: m.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
            child: Icon(m.icon, color: m.color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(m.value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
          Text(m.label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _infoCard(String text) {
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

class _Metric {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  _Metric(this.icon, this.color, this.value, this.label);
}
