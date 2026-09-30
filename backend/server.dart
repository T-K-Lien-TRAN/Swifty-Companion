import 'dart:convert';
import 'dart:io';

final http = HttpClient();
String? token;
DateTime tokenExpiresAt = DateTime.fromMillisecondsSinceEpoch(0);
Future<String>? tokenRequest;

class ApiException implements Exception {
  ApiException(this.status);
  final int status;
}

Map<String, String> loadCredentials() {
  final values = <String, String>{};
  final file = File('.env');

  if (file.existsSync()) {
    for (final line in file.readAsLinesSync()) {
      final text = line.trim();
      if (text.isEmpty || text.startsWith('#')) continue;

      final separator = text.indexOf('=');
      if (separator < 1) continue;

      final key = text.substring(0, separator).trim();
      var value = text.substring(separator + 1).trim();
      if (value.length >= 2 &&
          ((value.startsWith('"') && value.endsWith('"')) ||
              (value.startsWith("'") && value.endsWith("'")))) {
        value = value.substring(1, value.length - 1);
      }
      values[key] = value;
    }
  }

  return {...values, ...Platform.environment};
}

Future<Map<String, dynamic>> getJson(
  Uri uri, {
  String method = 'GET',
  Map<String, String> headers = const {},
  String? body,
}) async {
  final request = await http.openUrl(method, uri);
  headers.forEach(request.headers.set);
  if (body != null) request.write(body);

  final response = await request.close();
  final content = await utf8.decoder.bind(response).join();

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw ApiException(response.statusCode);
  }
  return jsonDecode(content) as Map<String, dynamic>;
}

Future<String> getToken(
  String clientId,
  String clientSecret, {
  String? rejectedToken,
}) async {
  // If another search has already replaced the rejected token, use the new one.
  if (rejectedToken != null && token == rejectedToken) {
    token = null;
  }

  if (token != null && DateTime.now().isBefore(tokenExpiresAt)) {
    print('Using cached 42 token');
    return token!;
  }

  // Searches arriving together share the same token request.
  if (tokenRequest != null) return tokenRequest!;

  final request = () async {
    final result = await getJson(
      Uri.https('api.intra.42.fr', '/oauth/token'),
      method: 'POST',
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'client_credentials',
        'client_id': clientId,
        'client_secret': clientSecret,
      }.entries.map((e) =>
          '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}'
      ).join('&'),
    );

    final newToken = result['access_token'] as String;
    final seconds = (result['expires_in'] as num).toInt();
    print('42 token valid for $seconds seconds');
    print('NEW 42 TOKEN CREATED at ${DateTime.now()}');
    print('Token value: $newToken');
    //final seconds = 10;
    if (newToken.isEmpty || seconds <= 0) {
      throw const FormatException('Invalid token response');
    }

    // Refresh slightly before the token actually expires.
    final margin = seconds ~/ 10 < 60 ? seconds ~/ 10 : 60;
    tokenExpiresAt = DateTime.now().add(
      Duration(seconds: seconds - margin),
    );
    token = newToken;
    return newToken;
  }();

  tokenRequest = request;
  try {
    return await request;
  } finally {
    tokenRequest = null;
  }
}

Future<Map<String, dynamic>> getStudent(
  String login,
  String clientId,
  String clientSecret,
) async {
  final uri = Uri.https('api.intra.42.fr', '/v2/users/$login');
  final currentToken = await getToken(clientId, clientSecret);

  try {
    return await getJson(
      uri,
      headers: {'Authorization': 'Bearer $currentToken'},
    );
  } on ApiException catch (error) {
    if (error.status != HttpStatus.unauthorized) rethrow;

    final newToken = await getToken(
      clientId,
      clientSecret,
      rejectedToken: currentToken,
    );
    return getJson(uri, headers: {'Authorization': 'Bearer $newToken'});
  }
}

void sendJson(HttpResponse response, int status, Object data) {
  response.statusCode = status;
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(data));
  response.close();
}

Future<void> main() async {
  final credentials = loadCredentials();
  final clientId = credentials['42_CLIENT_ID'];
  final clientSecret = credentials['42_CLIENT_SECRET'];

  if (clientId == null || clientId.isEmpty ||
      clientSecret == null || clientSecret.isEmpty) {
    stderr.writeln('Set 42_CLIENT_ID and 42_CLIENT_SECRET in .env.');
    exitCode = 1;
    return;
  }

  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('Listening on port $port');

  await for (final request in server) {
    final origin = request.headers.value('origin');
    if (origin != null) {
      final uri = Uri.tryParse(origin);
      if (uri != null &&
          (uri.host == 'localhost' || uri.host == '127.0.0.1') &&
          (uri.scheme == 'http' || uri.scheme == 'https')) {
        request.response.headers.set('Access-Control-Allow-Origin', origin);
        request.response.headers.set('Vary', 'Origin');
      }
    }

    final path = request.uri.pathSegments;
    if (request.method != 'GET' ||
        path.length != 2 ||
        path[0] != 'students' ||
        !RegExp(r'^[a-z][a-z0-9_-]{0,31}$').hasMatch(path[1])) {
      sendJson(request.response, 404, {'error': 'Not found'});
      continue;
    }

    try {
      final student = await getStudent(path[1], clientId, clientSecret);
      sendJson(request.response, 200, student);
    } on ApiException catch (error) {
      final status = error.status == 404 ? 404 : 502;
      sendJson(request.response, status, {
        'error': status == 404 ? 'Student not found.' : '42 API is unavailable.',
      });
    } catch (error) {
      stderr.writeln('Request failed: ${error.runtimeType}');
      sendJson(request.response, 502, {'error': 'Profile lookup failed.'});
    }
  }
}
