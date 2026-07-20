/// Shared API base URL for all services.
///
/// Override at build/run time:
/// `flutter run --dart-define=API_BASE_URL=https://example.com/api`
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://getlessify.com/api',
  );
}
