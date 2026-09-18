// Run on a trusted server with .env in the working directory or process credentials.
// Never distribute these credentials with the Flutter app.
import 'dart:convert';
import 'dart:io';

final client = HttpClient();
String? cachedToken;
DateTime tokenExpiresAt = DateTime.fromMillisecondsSinceEpoch(0);

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
    throw HttpException('42 returned ${response.statusCode}', uri: uri);
  }
  final json = jsonDecode(content);
  if (json is! Map<String, dynamic>) throw const FormatException('Invalid 42 response');
  return json;
}

Future<String> accessToken() async {
  if (cachedToken != null && DateTime.now().isBefore(tokenExpiresAt)) return cachedToken!;
  final id = credentials['42_CLIENT_ID'];
  final secret = credentials['42_CLIENT_SECRET'];
  if (id == null || secret == null) throw StateError('Missing 42 credentials');
  final result = await requestJson(
    Uri.https('api.intra.42.fr', '/oauth/token'),
    method: 'POST',
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {'grant_type': 'client_credentials', 'client_id': id, 'client_secret': secret}
        .entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&'),
  );
  final token = result['access_token'];
  if (token is! String) throw const FormatException('No access token');
  cachedToken = token;
  final seconds = (result['expires_in'] as num?)?.toInt() ?? 3600;
  tokenExpiresAt = DateTime.now().add(Duration(seconds: seconds > 60 ? seconds - 60 : 0));
  return token;
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
      final token = await accessToken();
      final user = await requestJson(
        Uri.https('api.intra.42.fr', '/v2/users/${path[1]}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      jsonResponse(request.response, 200, user);
    } on HttpException catch (e) {
      // Avoid sending credentials or token details back to the device.
      final status = e.message.contains('404') ? 404 : 502;
      jsonResponse(request.response, status,
          {'error': status == 404 ? 'Student not found.' : '42 API is unavailable.'});
    } catch (e) {
      stderr.writeln('Request failed: ${e.runtimeType}');
      jsonResponse(request.response, 502, {'error': 'Profile lookup failed.'});
    }
  }
}
