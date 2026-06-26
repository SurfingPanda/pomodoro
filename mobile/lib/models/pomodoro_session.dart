/// A completed pomodoro focus session, as returned by the Laravel API.
class PomodoroSession {
  final int id;
  final String? task;
  final int durationMinutes;
  final DateTime completedAt;

  PomodoroSession({
    required this.id,
    required this.task,
    required this.durationMinutes,
    required this.completedAt,
  });

  factory PomodoroSession.fromJson(Map<String, dynamic> json) {
    return PomodoroSession(
      id: json['id'] as int,
      task: json['task'] as String?,
      durationMinutes: json['duration_minutes'] as int,
      completedAt: DateTime.parse(json['completed_at'] as String).toLocal(),
    );
  }
}

/// One day's focus total, used for the weekly chart.
class DailyStat {
  final String label; // e.g. "Mo"
  final int minutes;

  DailyStat({required this.label, required this.minutes});

  factory DailyStat.fromJson(Map<String, dynamic> json) =>
      DailyStat(label: json['label'] as String, minutes: json['minutes'] as int);
}

/// Aggregate focus stats for the current user's dashboard.
class PomodoroStats {
  final int totalSessions;
  final int totalMinutes;
  final int todaySessions;
  final int todayMinutes;
  final int weekMinutes;
  final int weekSessions;
  final int streakDays;
  final List<DailyStat> daily;

  PomodoroStats({
    required this.totalSessions,
    required this.totalMinutes,
    required this.todaySessions,
    required this.todayMinutes,
    required this.weekMinutes,
    required this.weekSessions,
    required this.streakDays,
    required this.daily,
  });

  factory PomodoroStats.fromJson(Map<String, dynamic> json) {
    return PomodoroStats(
      totalSessions: json['total_sessions'] as int,
      totalMinutes: json['total_minutes'] as int,
      todaySessions: json['today_sessions'] as int,
      todayMinutes: json['today_minutes'] as int,
      weekMinutes: json['week_minutes'] as int,
      weekSessions: json['week_sessions'] as int,
      streakDays: json['streak_days'] as int,
      daily: (json['daily'] as List<dynamic>)
          .map((e) => DailyStat.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
