import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class PaymentService {
  // Stripe configuration would normally be in a separate config or environment file
  // For production, the publishableKey should be fetched or stored securely.
  
  static Future<void> initStripe(String publishableKey) async {
    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  }

  // Stripe Payment: This typically involves calling a backend (Firebase Function) 
  // to create a PaymentIntent and then using the client secret to confirm the payment.
  Future<void> makeStripePayment({
    required double amount,
    required String currency,
    required Function(String clientSecret) onPaymentIntentCreated,
    required Function() onPaymentSuccess,
    required Function(String error) onPaymentError,
  }) async {
    try {
      // 1. Create PaymentIntent on server
      final callable = FirebaseFunctions.instance.httpsCallable('createStripePaymentIntent');
      final result = await callable.call({
        'amount': (amount * 100).toInt(),
        'currency': currency,
      });

      final clientSecret = result.data['clientSecret'];
      onPaymentIntentCreated(clientSecret);

      // 2. Initialize and present Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'ProPay',
          style: ThemeMode.light,
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

  // Chapa Payment: Usually involves opening a checkout URL
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
      // Note: In production, this should go through a proxy (Firebase Function) 
      // to avoid exposing the secret key in the app.
      final response = await http.post(
        Uri.parse('https://api.chapa.co/v1/transaction/initialize'),
        headers: {
          'Authorization': 'Bearer YOUR_CHAPA_SECRET_KEY', // Placeholder
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount.toString(),
          'currency': 'ETB',
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'tx_ref': txRef,
          'callback_url': 'https://your-webhook-url.com',
          'return_url': 'propay://payment-complete',
          'customization[title]': 'Wallet Top-up',
          'customization[description]': 'Deposit to ProPay Wallet',
        }),
      );

      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        onReady(data['data']['checkout_url']);
      } else {
        onError(data['message'] ?? 'Initialization failed');
      }
    } catch (e) {
      onError(e.toString());
    }
  }
}
