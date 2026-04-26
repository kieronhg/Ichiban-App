import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../core/providers/student_session_provider.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';

class PinEntryScreen extends ConsumerStatefulWidget {
  const PinEntryScreen({super.key});

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _isVerifying = false;
  bool _hasError = false;

  /// Ticks every second while the screen is locked to update the countdown.
  Timer? _countdownTimer;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 12, end: -8), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── Lockout countdown ──────────────────────────────────────────────────

  void _ensureCountdownTimer(bool isLocked) {
    if (isLocked && _countdownTimer == null) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final session = ref.read(studentSessionProvider);
        if (!session.isLockedOut) {
          // Lockout just expired — clean up.
          _countdownTimer?.cancel();
          _countdownTimer = null;
          ref.read(studentSessionProvider.notifier).resetAttempts();
          setState(() => _hasError = false);
        } else {
          setState(() {}); // Rebuild to refresh countdown display.
        }
      });
    } else if (!isLocked && _countdownTimer != null) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
    }
  }

  // ── Input handling ─────────────────────────────────────────────────────

  void _onDigit(String digit) {
    final session = ref.read(studentSessionProvider);
    if (session.isLockedOut ||
        _pin.length >= AppConstants.pinLength ||
        _isVerifying) {
      return;
    }
    setState(() {
      _pin += digit;
      _hasError = false;
    });
    if (_pin.length == AppConstants.pinLength) {
      _verify();
    }
  }

  void _onDelete() {
    final session = ref.read(studentSessionProvider);
    if (session.isLockedOut || _pin.isEmpty || _isVerifying) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verify() async {
    setState(() => _isVerifying = true);

    final session = ref.read(studentSessionProvider);
    final profileId = session.profileId;
    if (profileId == null) return;

    final useCase = ref.read(setPinUseCaseProvider);
    final correct = await useCase.verify(profileId: profileId, pin: _pin);

    if (!mounted) return;

    if (correct) {
      ref.read(studentSessionProvider.notifier).authenticate();
      context.go(RouteNames.studentHome);
    } else {
      ref.read(studentSessionProvider.notifier).recordFailedAttempt();
      await _shakeController.forward(from: 0);
      if (mounted) {
        setState(() {
          _pin = '';
          _isVerifying = false;
          _hasError = true;
        });
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(studentSessionProvider);
    final isLocked = session.isLockedOut;
    _ensureCountdownTimer(isLocked);

    final profileAsync = session.profileId != null
        ? ref.watch(profileProvider(session.profileId!))
        : null;
    final profile = profileAsync?.asData?.value;
    final profileName = profile?.firstName ?? '';
    final noPinSet = profile != null && profile.pinHash == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(studentSessionProvider.notifier).signOut();
            context.go(RouteNames.studentSelect);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Lockout banner ─────────────────────────────────────────
            if (isLocked) _LockoutBanner(remaining: session.lockoutRemaining),

            const Spacer(),

            // ── Greeting ───────────────────────────────────────────────
            Text(
              profileName.isNotEmpty ? 'Hi, $profileName' : 'Enter your PIN',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // ── No-PIN-set notice ──────────────────────────────────────
            if (noPinSet)
              _NoPinBanner()
            else
              Text(
                isLocked
                    ? 'Too many incorrect attempts'
                    : 'Enter your 4-digit PIN',
                style: TextStyle(
                  color: isLocked ? AppColors.error : AppColors.textSecondary,
                ),
              ),

            const SizedBox(height: 40),

            // ── PIN dots ───────────────────────────────────────────────
            if (!noPinSet) ...[
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: child,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(AppConstants.pinLength, (i) {
                    final filled = i < _pin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _hasError || isLocked
                            ? AppColors.error
                            : filled
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        border: Border.all(
                          color: _hasError || isLocked
                              ? AppColors.error
                              : filled
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          width: 1.5,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (_hasError && !isLocked) ...[
                const SizedBox(height: 12),
                Text(
                  session.failedAttempts >= AppConstants.pinMaxAttempts - 1
                      ? 'Incorrect PIN — 1 attempt remaining'
                      : 'Incorrect PIN. Please try again.',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],

            const Spacer(),

            // ── Numpad (hidden while locked or no PIN set) ─────────────
            if (!isLocked && !noPinSet)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  children: [
                    _NumRow(digits: const ['1', '2', '3'], onDigit: _onDigit),
                    const SizedBox(height: 16),
                    _NumRow(digits: const ['4', '5', '6'], onDigit: _onDigit),
                    const SizedBox(height: 16),
                    _NumRow(digits: const ['7', '8', '9'], onDigit: _onDigit),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(width: 72),
                        _NumButton(digit: '0', onTap: () => _onDigit('0')),
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: _isVerifying
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  iconSize: 28,
                                  onPressed: _pin.isNotEmpty ? _onDelete : null,
                                  icon: const Icon(Icons.backspace_outlined),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Lockout banner ─────────────────────────────────────────────────────────

class _LockoutBanner extends StatelessWidget {
  const _LockoutBanner({required this.remaining});

  final Duration remaining;

  String get _formatted {
    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      color: AppColors.error.withAlpha(26),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Too many incorrect attempts. Try again in $_formatted.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── No-PIN banner ──────────────────────────────────────────────────────────

class _NoPinBanner extends StatelessWidget {
  const _NoPinBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.warning.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withAlpha(102)),
        ),
        child: Column(
          children: [
            const Icon(Icons.pin_outlined, color: AppColors.warning, size: 32),
            const SizedBox(height: 12),
            Text(
              'No PIN set',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'An admin needs to set a PIN for this profile '
              'before you can log in.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Numpad widgets ─────────────────────────────────────────────────────────

class _NumRow extends StatelessWidget {
  const _NumRow({required this.digits, required this.onDigit});

  final List<String> digits;
  final void Function(String) onDigit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map((d) => _NumButton(digit: d, onTap: () => onDigit(d)))
          .toList(),
    );
  }
}

class _NumButton extends StatelessWidget {
  const _NumButton({required this.digit, required this.onTap});

  final String digit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
