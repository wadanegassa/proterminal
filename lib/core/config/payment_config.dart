class PaymentConfig {
  // Stripe Configuration
  static const String stripePublishableKey = 'pk_test_51Sw5aJRS7mYoTDD94bfCNrCfTDJyyYCKLq4R8alP1fJ7ISUHhXFYHbfhGWlOXUHuknsdE6tFnQ6ZPdiqHa4iwnOp00UeQEwanp'; // Placeholder
  static const String stripeSecretKey = 'sk_test_51Sw5aJRS7mYoTDD963zxwHJuVLidqagJNkplor6Nyhrl2A5JKhzFgu8cy3WF4WlDYDXvkycuidoi0rjvZc3zkzCx00amLqOuX7'; // Placeholder - Replace with your Stripe Secret Key
  
  // Chapa Configuration
  static const String chapaSecretKey = 'CHASECK_TEST-moHlOhHtJYrfANEhuilGuvgVnMuYyJOW'; // Placeholder - Replace with real key
  static const String chapaWebhookUrl = 'https://your-firebase-region-project.cloudfunctions.net/chapaWebhook';
  
  // App Specific
  static const String currency = 'USD';
  static const String localCurrency = 'ETB';
  static const String merchantDisplayName = 'ProTerminal Global';
}
