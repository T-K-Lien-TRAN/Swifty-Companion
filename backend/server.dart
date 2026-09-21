// Run on a trusted server with .env in the working directory or process credentials.
// Never distribute these credentials with the Flutter app.
import 'dart:convert';
import 'dart:io';

final client = HttpClient();
Uri apiBaseUri = Uri.https('api.intra.42.fr', '/');
String? cachedToken;
DateTime tokenExpiresAt = DateTime.fromMillisecondsSinceEpoch(0);
Future<String>? pendingTokenRequest;

class ApiHttpException implements Exception {
  const ApiHttpException(this.statusCode);
  final int statusCode;
}

// A shell cannot export names beginning with a digit. Read the supplied .env
// directly, while allowing real process environment variables to override it.
Map<String, String> loadCredentials() {
  final values = <String, String>{};
  final file = File('.env');
  if (file.existsSync()) {
    for (final line in file.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final equals = trimmed.indexOf('=');
      if (equals <= 0) continue;
      final key = trimmed.substring(0, equals).trim();
      var value = trimmed.substring(equals + 1).trim();
      if (value.length >= 2 &&
          ((value.startsWith('"') && value.endsWith('"')) ||
           (value.startsWith("'") && value.endsWith("'")))) {
        value = value.substring(1, value.length - 1);
      }
      values[key] = value;
    }
  }
  values.addAll(Platform.environment);
  return values;
}

late final Map<String, String> credentials;

Future<Map<String, dynamic>> requestJson(Uri uri, {
  String method = 'GET',
  Map<String, String> headers = const {},
  String? body,
}) async {
  final req = await client.openUrl(method, uri);
  headers.forEach(req.headers.set);
  if (body != null) req.write(body);
  final response = await req.close();
  final content = await utf8.decoder.bind(response).join();
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw ApiHttpException(response.statusCode);
  }
  final json = jsonDecode(content);
  if (json is! Map<String, dynamic>) throw const FormatException('Invalid 42 response');
  return json;
}

Future<String> requestNewToken() async {
  final id = credentials['42_CLIENT_ID'];
  final secret = credentials['42_CLIENT_SECRET'];
  if (id == null || secret == null) throw StateError('Missing 42 credentials');
  late final Map<String, dynamic> result;
  try {
    result = await requestJson(
      apiBaseUri.resolve('/oauth/token'),
      method: 'POST',
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'grant_type': 'client_credentials', 'client_id': id, 'client_secret': secret}
          .entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&'),
    );
  } on ApiHttpException {
    throw const FormatException('Token request failed');
  }
  final token = result['access_token'];
  if (token is! String || token.isEmpty) throw const FormatException('No access token');
  final seconds = (result['expires_in'] as num?)?.toInt() ?? 3600;
  //print('NEW 42 TOKEN CREATED at ${DateTime.now()}');
  //final seconds = 10;
  if (seconds <= 0) throw const FormatException('Invalid token lifetime');
  // Renew before expiry; keep a smaller margin for short-lived tokens.
  final margin = seconds ~/ 10 < 60 ? seconds ~/ 10 : 60;
  tokenExpiresAt = DateTime.now().add(Duration(seconds: seconds - margin));
  cachedToken = token;
  return token;
}

Future<String> accessToken({String? rejectedToken}) async {
  // A different request may already have replaced the token rejected by 42.
  if (rejectedToken != null && cachedToken == rejectedToken) {
    cachedToken = null;
    tokenExpiresAt = DateTime.fromMillisecondsSinceEpoch(0);
  }
  if (cachedToken != null && DateTime.now().isBefore(tokenExpiresAt)) {
    return cachedToken!;
  }
  if (pendingTokenRequest != null) return pendingTokenRequest!;

  // Share one refresh among searches that arrive at the same time.
  final refresh = requestNewToken();
  pendingTokenRequest = refresh;
  try {
    return await refresh;
  } finally {
    if (identical(pendingTokenRequest, refresh)) pendingTokenRequest = null;
  }
}

Future<Map<String, dynamic>> fetchStudent(String login) async {
  final uri = apiBaseUri.resolve('/v2/users/$login');
  final token = await accessToken();
  try {
    return await requestJson(uri, headers: {'Authorization': 'Bearer $token'});
  } on ApiHttpException catch (error) {
    if (error.statusCode != HttpStatus.unauthorized) rethrow;
    // The token can be revoked before its advertised expiry. Retry once only.
    final replacement = await accessToken(rejectedToken: token);
    return requestJson(uri, headers: {'Authorization': 'Bearer $replacement'});
  }
}

void jsonResponse(HttpResponse response, int status, Object data) {
  response.statusCode = status;
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(data));
  response.close();
}

void allowDevelopmentBrowser(HttpRequest request) {
  final origin = request.headers.value('origin');
  if (origin == null) return;
  final uri = Uri.tryParse(origin);
  if (uri != null &&
      (uri.host == 'localhost' || uri.host == '127.0.0.1') &&
      (uri.scheme == 'http' || uri.scheme == 'https')) {
    request.response.headers.set('Access-Control-Allow-Origin', origin);
    request.response.headers.set('Vary', 'Origin');
  }
}

Future<void> main() async {
  credentials = loadCredentials();
  if ((credentials['42_CLIENT_ID'] ?? '').isEmpty ||
      (credentials['42_CLIENT_SECRET'] ?? '').isEmpty) {
    stderr.writeln('Set 42_CLIENT_ID and 42_CLIENT_SECRET in .env or the server environment.');
    exitCode = 1;
    return;
  }
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('Listening on port $port');
  await for (final request in server) {
    allowDevelopmentBrowser(request);
    final path = request.uri.pathSegments;
    if (request.method != 'GET' || path.length != 2 || path[0] != 'students' ||
        !RegExp(r'^[a-z][a-z0-9_-]{0,31}$').hasMatch(path[1])) {
      jsonResponse(request.response, 404, {'error': 'Not found'});
      continue;
    }
    try {
      final user = await fetchStudent(path[1]);
      jsonResponse(request.response, 200, user);
    } on ApiHttpException catch (e) {
      // Avoid sending credentials or token details back to the device.
      final status = e.statusCode == HttpStatus.notFound ? 404 : 502;
      jsonResponse(request.response, status,
          {'error': status == 404 ? 'Student not found.' : '42 API is unavailable.'});
    } catch (e) {
      stderr.writeln('Request failed: ${e.runtimeType}');
      jsonResponse(request.response, 502, {'error': 'Profile lookup failed.'});
    }
  }
}
