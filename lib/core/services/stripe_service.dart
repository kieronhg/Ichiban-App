import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';

/// Client-side Stripe integration.
///
/// All Stripe secret-key operations run in Cloud Functions.
/// This service only handles payment sheet presentation on the device.
class StripeService {
  StripeService._();

  static final _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west2',
  );

  /// Creates or retrieves a Stripe customer for the given profile.
  /// Returns the Stripe customer ID.
  static Future<String> ensureCustomer(String profileId) async {
    final result = await _functions.httpsCallable('createStripeCustomer').call({
      'profileId': profileId,
    });
    return result.data['customerId'] as String;
  }

  /// Creates a Stripe subscription for the given plan and returns the
  /// payment intent client secret needed to confirm the first payment.
  static Future<String> createSubscription({
    required String profileId,
    required String planKey,
  }) async {
    final result = await _functions
        .httpsCallable('createStripeSubscription')
        .call({'profileId': profileId, 'planKey': planKey});
    return result.data['clientSecret'] as String;
  }

  /// Updates an existing Stripe subscription to a new plan (upgrade).
  /// Returns the new payment intent client secret if proration requires
  /// immediate payment, or null if no immediate charge is needed.
  static Future<String?> upgradeSubscription({
    required String profileId,
    required String newPlanKey,
  }) async {
    final result = await _functions
        .httpsCallable('upgradeStripeSubscription')
        .call({'profileId': profileId, 'newPlanKey': newPlanKey});
    return result.data['clientSecret'] as String?;
  }

  /// Cancels a Stripe subscription at the end of the current billing period.
  static Future<void> cancelSubscriptionAtPeriodEnd(String profileId) async {
    await _functions.httpsCallable('cancelStripeSubscription').call({
      'profileId': profileId,
    });
  }

  /// Presents the Stripe payment sheet using [clientSecret].
  ///
  /// Returns `true` if payment was confirmed, `false` if cancelled.
  /// Throws [StripeException] on payment failure.
  static Future<bool> presentPaymentSheet({
    required String clientSecret,
    required String customerEmail,
    String? merchantDisplayName,
  }) async {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: merchantDisplayName ?? 'Ichiban Martial Arts',
        billingDetails: BillingDetails(email: customerEmail),
        googlePay: const PaymentSheetGooglePay(
          merchantCountryCode: 'GB',
          currencyCode: 'gbp',
          testEnv: true,
        ),
        applePay: const PaymentSheetApplePay(merchantCountryCode: 'GB'),
        style: ThemeMode.system,
      ),
    );

    try {
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) return false;
      rethrow;
    }
  }
}
