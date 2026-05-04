import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

// ── SkeletonBox ───────────────────────────────────────────────────────────────
// A shimmer-animated loading placeholder rectangle.
//
// Spec:
//   Shimmer: paper-3 → paper-2 → paper-3, 200% wide gradient, 1.4s loop.
//   Border-radius 4px.

class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 4,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                AppColors.paper3,
                AppColors.paper2,
                AppColors.paper3,
              ],
              stops: [
                (_animation.value - 0.5).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.5).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── SkeletonText ──────────────────────────────────────────────────────────────
// Convenience: a skeleton box sized for a text line (height 10–14px).

class SkeletonText extends StatelessWidget {
  const SkeletonText({
    super.key,
    required this.widthFraction,
    this.height = 10,
  });

  /// Fraction of available width, e.g. 0.6 for 60%.
  final double widthFraction;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SkeletonBox(
        width: constraints.maxWidth * widthFraction,
        height: height,
      ),
    );
  }
}

// ── SkeletonListTile ──────────────────────────────────────────────────────────
// Skeleton approximating a member list row: avatar circle + two text lines.

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          SkeletonBox(width: 32, height: 32, borderRadius: 16),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(widthFraction: 0.45, height: 12),
                const SizedBox(height: 6),
                SkeletonText(widthFraction: 0.65, height: 9),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SkeletonBox(width: 48, height: 20, borderRadius: 2),
          const SizedBox(width: 8),
          SkeletonBox(width: 48, height: 20, borderRadius: 2),
        ],
      ),
    );
  }
}
