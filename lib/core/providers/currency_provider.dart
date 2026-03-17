import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DisplayCurrency { usd, etb }

class CurrencyNotifier extends StateNotifier<DisplayCurrency> {
  CurrencyNotifier() : super(DisplayCurrency.usd);

  void toggle() {
    state = state == DisplayCurrency.usd ? DisplayCurrency.etb : DisplayCurrency.usd;
  }

  void setCurrency(DisplayCurrency currency) {
    state = currency;
  }
}

final displayCurrencyProvider = StateNotifierProvider<CurrencyNotifier, DisplayCurrency>((ref) {
  return CurrencyNotifier();
});

class CurrencyConverter {
  // Current approximate market rates
  static const double usdToEtbRate = 132.50; 
  static const double etbToUsdRate = 1 / usdToEtbRate;

  static double convert({
    required double amount,
    required String from,
    required DisplayCurrency to,
  }) {
    if (from.toUpperCase() == 'USD') {
      return to == DisplayCurrency.usd ? amount : amount * usdToEtbRate;
    } else if (from.toUpperCase() == 'ETB') {
      return to == DisplayCurrency.etb ? amount : amount * etbToUsdRate;
    }
    return amount;
  }

  static String getSymbol(DisplayCurrency currency) {
    return currency == DisplayCurrency.usd ? '\$' : 'ETB ';
  }
}
