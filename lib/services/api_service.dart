import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../utils/exeptions.dart';
import 'auth_service.dart';

class ApiService {
  Future<StudentUser> fetchStudent(String login) async {
    if (AuthService.baseUrl.isEmpty) {
      throw const ApiException('Set API_BASE_URL to your server address.');
    }
    final base = Uri.tryParse(AuthService.baseUrl);
    if (base == null || !base.hasScheme || base.host.isEmpty) {
      throw const ApiException('API_BASE_URL is invalid.');
    }
    final uri = base.replace(
      pathSegments: [...base.pathSegments.where((p) => p.isNotEmpty), 'students', login],
    );
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode != 200) {
        final detail = decoded is Map ? decoded['error']?.toString() : null;
        throw ApiException(detail ?? 'Request failed (${response.statusCode}).');
      }
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('Unexpected profile response.');
      }
      return StudentUser.fromJson(decoded);
    } on FormatException {
      throw const ApiException('The server returned invalid JSON.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Cannot reach the profile server. Check its URL and connection.');
    }
  }
}
