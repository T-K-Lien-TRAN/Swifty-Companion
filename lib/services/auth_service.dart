// The client secret belongs on the server, never inside a Flutter build.
// Supply the server URL with --dart-define=API_BASE_URL=...
class AuthService {
  static const baseUrl = String.fromEnvironment('API_BASE_URL');
}
