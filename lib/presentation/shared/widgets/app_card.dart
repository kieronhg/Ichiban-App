import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

// ── AppCardElevation ──────────────────────────────────────────────────────────

enum AppCardElevation { flat, raised, hover }

// ── AppCard ───────────────────────────────────────────────────────────────────
// Base card component.
//
// Spec:
//   bg paper-0, border 1px hairline, border-radius r-md (6px),
//   padding s-5 (20px), shadow sh-1 at rest / sh-2 raised.
//
// Use [onTap] to make the card interactive — adds press animation.

class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation = AppCardElevation.flat,
    this.onTap,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final AppCardElevation elevation;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  List<BoxShadow> get _shadow => switch (widget.elevation) {
    AppCardElevation.flat => AppShadow.sh1,
    AppCardElevation.raised => AppShadow.sh2,
    AppCardElevation.hover => AppShadow.sh2,
  };

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.onTap != null;

    Widget card = AnimatedContainer(
      duration: AppMotion.short,
      curve: Curves.easeOut,
      transform: isInteractive && _pressed
          ? (Matrix4.identity()..translateByDouble(0.0, 1.0, 0.0, 1.0))
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: widget.color ?? AppColors.paper0,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: widget.borderColor ?? AppColors.hairline),
        boxShadow: isInteractive && _pressed ? AppShadow.sh1 : _shadow,
      ),
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.all(AppSpacing.s5),
        child: widget.child,
      ),
    );

    if (!isInteractive) return card;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: card,
    );
  }
}

// ── DotDivider ────────────────────────────────────────────────────────────────
// Dotted horizontal rule used inside cards.

class DotDivider extends StatelessWidget {
  const DotDivider({super.key, this.margin});

  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: CustomPaint(
        size: const Size(double.infinity, 1),
        painter: _DottedLinePainter(),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.hairline
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;
    const dotRadius = 0.5;
    const gap = 6.0;
    double x = dotRadius;
    while (x < size.width) {
      canvas.drawCircle(Offset(x, 0.5), dotRadius, paint);
      x += gap;
    }
  }

  @override
  bool shouldRepaint(_DottedLinePainter _) => false;
}
