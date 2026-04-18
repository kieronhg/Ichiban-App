import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/profile_providers.dart';
import '../../../core/providers/student_session_provider.dart';
import '../../../core/router/route_names.dart';

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
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  static const _pinLength = 4;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_pin.length >= _pinLength || _isVerifying) return;
    setState(() {
      _pin += digit;
      _hasError = false;
    });
    if (_pin.length == _pinLength) {
      _verify();
    }
  }

  void _onDelete() {
    if (_pin.isEmpty || _isVerifying) return;
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
      await _shakeController.forward(from: 0);
      setState(() {
        _pin = '';
        _isVerifying = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(studentSessionProvider);
    final profileAsync = session.profileId != null
        ? ref.watch(profileProvider(session.profileId!))
        : null;

    final profileName = profileAsync?.value?.firstName ?? '';

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
            const Spacer(),

            // ── Greeting ────────────────────────────────────────────────
            Text(
              profileName.isNotEmpty ? 'Hi, $profileName' : 'Enter your PIN',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your 4-digit PIN',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 40),

            // ── PIN dots ─────────────────────────────────────────────────
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: child,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (i) {
                  final filled = i < _pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hasError
                          ? AppColors.error
                          : filled
                              ? AppColors.primary
                              : AppColors.surfaceVariant,
                      border: Border.all(
                        color: _hasError
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
            if (_hasError) ...[
              const SizedBox(height: 12),
              Text(
                'Incorrect PIN. Please try again.',
                style: TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ],

            const Spacer(),

            // ── Numpad ───────────────────────────────────────────────────
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
                      const SizedBox(width: 72), // spacer for alignment
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
                                      strokeWidth: 2),
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
