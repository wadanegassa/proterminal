import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DisplayCurrency { usd, etb }

class CurrencyConverter {
  // Static exchange rate for the demo
  static const double usdToEtb = 155.0;

  static double convert({
    required double amount,
    required String from,
    required DisplayCurrency to,
  }) {
    if (from.toUpperCase() == 'USD') {
      return to == DisplayCurrency.usd ? amount : amount * usdToEtb;
    } else if (from.toUpperCase() == 'ETB') {
      return to == DisplayCurrency.etb ? amount : amount / usdToEtb;
    }
    return amount;
  }

  static String getSymbol(DisplayCurrency currency) {
    return currency == DisplayCurrency.usd ? '\$' : 'ETB ';
  }
}

final displayCurrencyProvider = StateProvider<DisplayCurrency>((ref) => DisplayCurrency.usd);
