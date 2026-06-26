import 'package:flutter/material.dart';

import '../models/pomodoro_session.dart';
import '../theme.dart';
import '../utils.dart';

/// A 7-day focus bar chart with today highlighted. Wrapped in a white card.
class WeeklyChart extends StatelessWidget {
  final List<DailyStat> daily;
  final int weekMinutes;

  const WeeklyChart({super.key, required this.daily, required this.weekMinutes});

  @override
  Widget build(BuildContext context) {
    final maxMin = daily.fold<int>(1, (m, d) => d.minutes > m ? d.minutes : m);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('This week',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 15)),
              Text('${fmtMinutes(weekMinutes)} focused',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(daily.length, (i) {
                final d = daily[i];
                final isToday = i == daily.length - 1;
                final frac = (d.minutes / maxMin).clamp(0.0, 1.0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (d.minutes > 0)
                          Text('${d.minutes}',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isToday ? AppColors.accent : AppColors.muted)),
                        const SizedBox(height: 4),
                        Container(
                          height: 6 + frac * 78,
                          decoration: BoxDecoration(
                            color: d.minutes == 0
                                ? AppColors.field
                                : (isToday
                                    ? AppColors.accent
                                    : AppColors.accent.withValues(alpha: 0.35)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(d.label,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                                color: isToday ? AppColors.ink : AppColors.muted)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
