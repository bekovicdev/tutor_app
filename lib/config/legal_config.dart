/// Legal/compliance URLs used across the app (paywall, settings).
///
/// TODO: Replace these placeholder URLs with the real, published Privacy
/// Policy and Terms of Use pages before submitting to the App Store. Apple
/// requires functional links to both for apps offering auto-renewable
/// subscriptions (see Guideline 3.1.2).
abstract final class LegalConfig {
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://getlessify.com/privacy',
  );

  static const String termsOfUseUrl = String.fromEnvironment(
    'TERMS_OF_USE_URL',
    defaultValue: 'https://getlessify.com/terms',
  );

  static const String supportEmail = 'bekovicdev@gmail.com';
}
