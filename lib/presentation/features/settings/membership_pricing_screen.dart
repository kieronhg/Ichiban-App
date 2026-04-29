import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/admin_session_provider.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/settings_providers.dart';
import '../../../core/theme/app_colors.dart';

// Plan label map — display name for each pricing key
const _planLabels = <String, String>{
  'monthlyAdult': 'Monthly Adult',
  'monthlyJunior': 'Monthly Junior',
  'annualAdult': 'Annual Adult',
  'annualJunior': 'Annual Junior',
  'familyMonthlyUpToThree': 'Family Monthly (up to 3)',
  'familyMonthlyFourOrMore': 'Family Monthly (4 or more)',
  'payAsYouTrainAdult': 'PAYT Adult',
  'payAsYouTrainJunior': 'PAYT Junior',
};

// Default prices for any keys not yet seeded
const _defaults = <String, double>{
  'monthlyAdult': 33.0,
  'monthlyJunior': 25.0,
  'annualAdult': 330.0,
  'annualJunior': 242.0,
  'familyMonthlyUpToThree': 55.0,
  'familyMonthlyFourOrMore': 66.0,
  'payAsYouTrainAdult': 10.0,
  'payAsYouTrainJunior': 7.0,
};

class MembershipPricingScreen extends ConsumerWidget {
  const MembershipPricingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = ref.watch(isOwnerProvider);
    if (!isOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Membership & Pricing')),
        body: const Center(child: Text('Owner access required.')),
      );
    }

    final pricingAsync = ref.watch(pricingFormProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Membership & Pricing')),
      body: pricingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (prices) => _PricingForm(prices: prices),
      ),
    );
  }
}

class _PricingForm extends ConsumerStatefulWidget {
  const _PricingForm({required this.prices});

  final Map<String, double> prices;

  @override
  ConsumerState<_PricingForm> createState() => _PricingFormState();
}

class _PricingFormState extends ConsumerState<_PricingForm> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final key in _planLabels.keys)
        key: TextEditingController(
          text: _format(widget.prices[key] ?? _defaults[key] ?? 0.0),
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _format(double v) => v.toStringAsFixed(2);

  Future<void> _save() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Price Changes'),
        content: const Text(
          'Changing prices will affect all new memberships and renewals '
          'from this point. Existing active memberships are not affected '
          'until their next renewal.\n\nConfirm?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final notifier = ref.read(pricingFormProvider.notifier);
    for (final entry in _controllers.entries) {
      final value = double.tryParse(entry.value.text);
      if (value != null) notifier.setPrice(entry.key, value);
    }

    final adminId = ref.read(currentAdminIdProvider) ?? '';
    try {
      await notifier.save(adminId: adminId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Prices updated.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gbp = NumberFormat.currency(locale: 'en_GB', symbol: '£');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Plan Prices', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'All prices in GBP. Changes take effect immediately for new '
            'memberships and at next renewal for existing ones.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ..._planLabels.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: _controllers[e.key],
                decoration: InputDecoration(
                  labelText: e.value,
                  prefixText: '£ ',
                  helperText: 'Default: ${gbp.format(_defaults[e.key] ?? 0.0)}',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Save Prices')),
        ],
      ),
    );
  }
}
