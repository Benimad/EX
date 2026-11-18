/// Build-time configuration, injected with `--dart-define` or
/// `--dart-define-from-file=env/dev.json`. Nothing secret lives here:
/// the Supabase anon key and the RevenueCat *public* SDK key are designed to
/// ship in the app. Server secrets (RevenueCat secret key, webhook token,
/// service role key, LLM key) live ONLY in Supabase Edge Function secrets.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// RevenueCat public Apple SDK key (`appl_...`).
  static const rcApiKeyIos = String.fromEnvironment('RC_API_KEY_IOS');

  /// RevenueCat public Google SDK key (`goog_...`). Optional for v1 (iOS first).
  static const rcApiKeyAndroid = String.fromEnvironment('RC_API_KEY_ANDROID');

  static const termsUrl = String.fromEnvironment('TERMS_URL');

  /// Sent with analytics events (set by CI: --dart-define=APP_VERSION=…).
  static const appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '0.1.0',
  );
  static const privacyUrl = String.fromEnvironment('PRIVACY_URL');
  static const supportEmail = String.fromEnvironment('SUPPORT_EMAIL');

  /// Crisis lines. VERIFY every number against official sources before release.
  static const emergencyTr = String.fromEnvironment(
    'EMERGENCY_TR',
    defaultValue: '112',
  );
  static const emergencyUs = String.fromEnvironment(
    'EMERGENCY_US',
    defaultValue: '911',
  );
  static const helplineTr = String.fromEnvironment('HELPLINE_TR');
  static const helplineUs = String.fromEnvironment(
    'HELPLINE_US',
    defaultValue: '988',
  );

  /// Names of required defines that are missing. Empty = fully configured.
  static List<String> get missingRequired => [
    if (supabaseUrl.isEmpty) 'SUPABASE_URL',
    if (supabasePublishableKey.isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
    if (rcApiKeyIos.isEmpty) 'RC_API_KEY_IOS',
    if (termsUrl.isEmpty) 'TERMS_URL',
    if (privacyUrl.isEmpty) 'PRIVACY_URL',
  ];
}
