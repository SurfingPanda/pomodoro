import 'package:flutter/material.dart';

/// A single shimmering placeholder box. Self-animating, no dependencies.
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const Skeleton({super.key, this.width, required this.height, this.radius = 16});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        // A highlight band sweeps left -> right; both sides fade to the base
        // colour, so there is no hard seam.
        final dx = -1.5 + 3.0 * _c.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(dx - 0.5, 0),
              end: Alignment(dx + 0.5, 0),
              colors: const [Color(0xFFEAEBEF), Color(0xFFF6F7F9), Color(0xFFEAEBEF)],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Full-width hero placeholder.
class SkeletonHero extends StatelessWidget {
  final double height;
  const SkeletonHero({super.key, this.height = 128});

  @override
  Widget build(BuildContext context) =>
      Skeleton(width: double.infinity, height: height, radius: 26);
}

/// A row of equal-width stat-tile placeholders.
class SkeletonTilesRow extends StatelessWidget {
  final int count;
  final double height;
  const SkeletonTilesRow({super.key, this.count = 3, this.height = 96});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == count - 1 ? 0 : 12),
            child: Skeleton(height: height, radius: 20),
          ),
        );
      }),
    );
  }
}

/// Chart card placeholder.
class SkeletonChart extends StatelessWidget {
  const SkeletonChart({super.key});

  @override
  Widget build(BuildContext context) =>
      const Skeleton(width: double.infinity, height: 180, radius: 22);
}

/// A vertical stack of list-row placeholders.
class SkeletonList extends StatelessWidget {
  final int count;
  final double height;
  const SkeletonList({super.key, this.count = 5, this.height = 64});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Skeleton(width: double.infinity, height: height, radius: 16),
        ),
      ),
    );
  }
}
