import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:propay/core/config/payment_config.dart';

class PaymentService {
  static Future<void> initStripe() async {
    Stripe.publishableKey = PaymentConfig.stripePublishableKey;
    await Stripe.instance.applySettings();
  }

  Future<void> makeStripePayment({
    required double amount,
    required String currency,
    required Function(String clientSecret) onPaymentIntentCreated,
    required Function() onPaymentSuccess,
    required Function(String error) onPaymentError,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createStripePaymentIntent');
      final result = await callable.call({
        'amount': (amount * 100).toInt(),
        'currency': currency,
      });

      final clientSecret = result.data['clientSecret'];
      if (clientSecret == null) throw Exception('Failed to create PaymentIntent');
      
      onPaymentIntentCreated(clientSecret);

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: PaymentConfig.merchantDisplayName,
          style: ThemeMode.system,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      onPaymentSuccess();
    } catch (e) {
      if (e is StripeException) {
        onPaymentError('Payment failed: ${e.error.localizedMessage}');
      } else {
        onPaymentError(e.toString());
      }
    }
  }

  Future<void> initiateChapaPayment({
    required double amount,
    required String email,
    required String firstName,
    required String lastName,
    required String txRef,
    required Function(String checkoutUrl) onReady,
    required Function(String error) onError,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.chapa.co/v1/transaction/initialize'),
        headers: {
          'Authorization': 'Bearer ${PaymentConfig.chapaSecretKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount.toString(),
          'currency': PaymentConfig.localCurrency,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'tx_ref': txRef,
          'callback_url': PaymentConfig.chapaWebhookUrl,
          'return_url': 'proterminal://payment-complete',
          'customization[title]': 'Wallet Top-up',
          'customization[description]': 'Deposit to ProTerminal Wallet',
        }),
      );

      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        onReady(data['data']['checkout_url']);
      } else {
        onError(data['message'] ?? 'Initialization failed');
      }
    } catch (e) {
      onError('Network error: ${e.toString()}');
    }
  }
}
