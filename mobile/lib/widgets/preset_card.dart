import 'package:flutter/material.dart';

import '../theme.dart';

/// A selectable session-preset card for the horizontally scrollable preset
/// row on the Focus screen. Animates its fill, shadow and scale when selected.
class PresetCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String tagline;
  final String focusLabel;
  final String breakLabel;
  final bool selected;
  final VoidCallback onTap;

  const PresetCard({
    super.key,
    required this.icon,
    required this.name,
    required this.tagline,
    required this.focusLabel,
    required this.breakLabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onAccent = selected;
    return AnimatedScale(
      scale: selected ? 1.0 : 0.96,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: 136,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.accent, AppColors.accentDark],
                  )
                : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.ink.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? AppColors.accent.withValues(alpha: 0.35)
                    : AppColors.ink.withValues(alpha: 0.05),
                blurRadius: selected ? 20 : 12,
                offset: Offset(0, selected ? 10 : 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: onAccent
                      ? Colors.white.withValues(alpha: 0.22)
                      : AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 20, color: onAccent ? Colors.white : AppColors.accent),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: onAccent ? Colors.white : AppColors.ink,
                ),
              ),
              Text(
                tagline,
                style: TextStyle(
                  fontSize: 11,
                  color: onAccent ? Colors.white70 : AppColors.muted,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                focusLabel,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: onAccent ? Colors.white : AppColors.ink,
                ),
              ),
              Text(
                breakLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: onAccent ? Colors.white70 : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
