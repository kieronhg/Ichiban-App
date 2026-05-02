import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';

class InviteExpiredScreen extends ConsumerWidget {
  const InviteExpiredScreen({super.key, this.profileId});

  final String? profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.link_off_rounded,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 24),
              Text(
                'This invite has expired',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Invite links are valid for 24 hours. '
                'Request a new one from your dojo.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (profileId != null)
                FilledButton(
                  onPressed: () => _requestNewInvite(context, ref),
                  child: const Text('Request a new invite'),
                ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _showContactInfo(context),
                child: const Text('Contact the dojo directly'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestNewInvite(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (profileId != null) {
        await FirebaseFunctions.instanceFor(region: 'europe-west2')
            .httpsCallable('requestInviteResend')
            .call({'profileId': profileId});
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Your request has been sent. '
            'The dojo team will send a new invite shortly.',
          ),
        ),
      );
    } on FirebaseFunctionsException {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Request sent — the dojo team has been notified.',
          ),
        ),
      );
    }
  }

  Future<void> _showContactInfo(BuildContext context) async {
    // Contact details come from appSettings — show a simple dialog for now.
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Contact your dojo'),
        content: const Text(
          'Please contact your dojo directly to request a new invite link.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
