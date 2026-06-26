import 'package:flutter/material.dart';

/// Centralized colors + theme for the app.
class AppColors {
  static const ink = Color(0xFF222933); // panda black / primary text
  static const accent = Color(0xFFE94F4F); // pomodoro red
  static const accentDark = Color(0xFFC83B3B);
  static const field = Color(0xFFF4F5F7); // input fill
  static const bgTop = Color(0xFFFFF6EE);
  static const bgBottom = Color(0xFFFDE9E6);
  static const muted = Color(0xFF8A8F98);

  // Stat-tile accents
  static const streak = Color(0xFFF59E0B); // amber — streak / fire
  static const week = Color(0xFF14B8A6); // teal — weekly focus
  static const total = Color(0xFF6366F1); // indigo — all-time
}

/// Daily focus goal in minutes, used by the dashboard progress ring.
const int kDailyGoalMinutes = 120;

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    primary: AppColors.accent,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bgTop,
    fontFamily: 'Roboto',
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      hintStyle: const TextStyle(color: AppColors.muted),
      prefixIconColor: AppColors.muted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
      ),
    ),
  );
}

/// Full-screen soft gradient used behind the auth screens.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgTop, AppColors.bgBottom],
        ),
      ),
      child: child,
    );
  }
}
