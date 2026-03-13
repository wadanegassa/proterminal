class PaymentConfig {
  /// Stripe Publishable Key from Dashboard
  static const String stripePublishableKey = "pk_test_51Sw5aJRS7mYoTDD94bfCNrCfTDJyyYCKLq4R8alP1fJ7ISUHhXFYHbfhGWlOXUHuknsdE6tFnQ6ZPdiqHa4iwnOp00UeQEwanp";
  
  /// Chapa Secret Key from Dashboard
  /// IMPORTANT: In a production app, the Secret Key should NEVER be stored
  /// on the client side. Use Firebase Functions as a proxy.
  static const String chapaSecretKey = "CHASECK_TEST-moHlOhHtJYrfANEhuilGuvgVnMuYyJOW";

  /// Chapa Public Key from Dashboard
  static const String chapaPublicKey = "CHAPUBK_TEST-aL8FyyUEpAn7rYQKg6ZvrGquZHgtYJtU";
}
