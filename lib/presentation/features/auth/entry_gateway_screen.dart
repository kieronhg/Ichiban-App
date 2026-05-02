import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Shown briefly at app launch while Firebase Auth state is being determined.
/// The router redirects away as soon as auth state resolves.
class EntryGatewayScreen extends StatelessWidget {
  const EntryGatewayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.brandSurface,
      body: Center(child: _SplashMark()),
    );
  }
}

class _SplashMark extends StatelessWidget {
  const _SplashMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withAlpha(64), width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: const Center(
            child: Text(
              '壱',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Ichiban',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.white.withAlpha(140),
          ),
        ),
      ],
    );
  }
}
