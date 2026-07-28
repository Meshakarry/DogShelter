class Environment {
  Environment._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5265',
  );

  // Stripe publishable keys are meant to be embedded client-side (unlike the secret key, which
  // never leaves the backend) - defaults to this project's own sandbox test key from the
  // backend's .env, overridable via --dart-define=STRIPE_PUBLISHABLE_KEY=... for a different key.
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue:
        'pk_test_51TsBTyIG5K18kdJFvIY4FszeiClWa9rX0vFS3EgaXCzyHAyUsrGWXrNdOk57ZwgK69Dpl4nubINg8JcnZrS58azE00C5Y77kfA',
  );
}
