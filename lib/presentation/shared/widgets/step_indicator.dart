import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

// ── StepIndicator ─────────────────────────────────────────────────────────────
// Horizontal wizard progress indicator.
//
// Spec:
//   Steps connected by 24px hairline lines.
//   Num circle 22×22px.
//     Pending:  hairline border, no fill.
//     Done:     ink-1 bg, paper-0 text, tick icon.
//     Current:  crimson bg, paper-0 text.
//   Labels: f-mono 11px uppercase, ink-3 (pending/done) / ink-1 (current).

class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  /// Step labels in order, e.g. ['Type', 'Personal', 'Emergency', ...].
  final List<String> steps;

  /// 1-indexed current step.
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            _StepItem(index: i + 1, label: steps[i], state: _stateFor(i + 1)),
            if (i < steps.length - 1) _StepLine(),
          ],
        ],
      ),
    );
  }

  _StepState _stateFor(int step) {
    if (step < currentStep) return _StepState.done;
    if (step == currentStep) return _StepState.current;
    return _StepState.pending;
  }
}

enum _StepState { pending, done, current }

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.index,
    required this.label,
    required this.state,
  });

  final int index;
  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final isDone = state == _StepState.done;
    final isCurrent = state == _StepState.current;

    final numBg = isDone
        ? AppColors.ink1
        : isCurrent
        ? AppColors.crimson
        : Colors.transparent;

    final numBorder = isDone
        ? AppColors.ink1
        : isCurrent
        ? AppColors.crimson
        : AppColors.hairline;

    final numFg = (isDone || isCurrent) ? AppColors.paper0 : AppColors.ink3;

    final labelColor = isCurrent ? AppColors.ink1 : AppColors.ink3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: numBg,
            shape: BoxShape.circle,
            border: Border.all(color: numBorder),
          ),
          child: Center(
            child: isDone
                ? Icon(Icons.check, size: 12, color: numFg)
                : Text(
                    '$index',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: numFg,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.ibmPlexMono(
            fontSize: 11,
            letterSpacing: 0.1 * 11,
            color: labelColor,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 1,
      margin: const EdgeInsets.only(bottom: AppSpacing.s4 + 4),
      color: AppColors.hairline,
    );
  }
}
