// Supply the server URL with --dart-define=API_BASE_URL=...
/*
class AuthService {
  static const baseUrl = String.fromEnvironment('API_BASE_URL');
}
*/
class AuthService {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );
}