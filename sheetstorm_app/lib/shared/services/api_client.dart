import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';

class ApiClient {
  final String baseUrl;
  final http.Client httpClient;

  ApiClient({
    this.baseUrl = kApiBaseUrl,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  Future<String> ping() async {
    final uri = Uri.parse('$baseUrl/ping');
    final response = await httpClient.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['message'] as String? ?? 'No message';
    } else {
      throw Exception('Failed to ping: ${response.statusCode}');
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
