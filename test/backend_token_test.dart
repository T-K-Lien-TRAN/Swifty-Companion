import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import '../backend/server.dart' as backend;

void main() {
  late HttpServer fake42;
  late Future<void> Function(HttpRequest) handle;
  var tokenRequests = 0;

  setUpAll(() {
    backend.credentials = {
      '42_CLIENT_ID': 'test-id',
      '42_CLIENT_SECRET': 'test-secret',
    };
  });

  setUp(() async {
    backend.cachedToken = null;
    backend.pendingTokenRequest = null;
    backend.tokenExpiresAt = DateTime.fromMillisecondsSinceEpoch(0);
    tokenRequests = 0;
    fake42 = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    backend.apiBaseUri = Uri.parse('http://127.0.0.1:${fake42.port}/');
    handle = (request) async {
      if (request.uri.path == '/oauth/token') {
        tokenRequests++;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'access_token': 'token-$tokenRequests',
          'expires_in': 3600,
        }));
      } else {
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"login":"student"}');
      }
      await request.response.close();
    };
    fake42.listen((request) => handle(request));
  });

  tearDown(() async {
    await fake42.close(force: true);
  });

  test('reuses a token then renews it after expiry', () async {
    expect((await backend.fetchStudent('student'))['login'], 'student');
    await backend.fetchStudent('student');
    expect(tokenRequests, 1);

    backend.tokenExpiresAt = DateTime.fromMillisecondsSinceEpoch(0);
    await backend.fetchStudent('student');
    expect(tokenRequests, 2);
  });

  test('one 401 triggers one shared refresh and retries the lookup', () async {
    var firstTokenLookups = 0;
    handle = (request) async {
      if (request.uri.path == '/oauth/token') {
        tokenRequests++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        request.response.write(jsonEncode({
          'access_token': 'token-$tokenRequests',
          'expires_in': 3600,
        }));
      } else if (request.headers.value('authorization') == 'Bearer token-1') {
        firstTokenLookups++;
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.write('{}');
      } else {
        request.response.write('{"login":"student"}');
      }
      await request.response.close();
    };

    final results = await Future.wait([
      backend.fetchStudent('student'),
      backend.fetchStudent('student'),
    ]);
    expect(results.map((user) => user['login']), everyElement('student'));
    expect(firstTokenLookups, 2);
    expect(tokenRequests, 2);
    await backend.fetchStudent('student');
    expect(tokenRequests, 2);
  });

  test('a failed replacement does not leave a stuck refresh', () async {
    handle = (request) async {
      if (request.uri.path == '/oauth/token') {
        tokenRequests++;
        if (tokenRequests == 2) {
          request.response.statusCode = HttpStatus.badGateway;
          request.response.write('{}');
        } else {
          request.response.write(jsonEncode({
            'access_token': 'token-$tokenRequests',
            'expires_in': 3600,
          }));
        }
      } else if (request.headers.value('authorization') == 'Bearer token-1') {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.write('{}');
      } else {
        request.response.write('{"login":"student"}');
      }
      await request.response.close();
    };

    await expectLater(backend.fetchStudent('student'), throwsA(isA<FormatException>()));
    expect(backend.pendingTokenRequest, isNull);
    expect((await backend.fetchStudent('student'))['login'], 'student');
    expect(tokenRequests, 3);
  });
}
