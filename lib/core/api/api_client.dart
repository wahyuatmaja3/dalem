import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_result.dart';
import 'auth_interceptor.dart';
import '../secure_storage/token_storage.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.read(tokenStorageProvider);
  final authInterceptor = ref.read(authInterceptorProvider);
  return ApiClient(
    baseUrl: 'https://api.dalem.example.com',
    tokenStorage: tokenStorage,
    authInterceptor: authInterceptor,
  );
});

class ApiClient {
  final String baseUrl;
  final TokenStorage tokenStorage;
  final AuthInterceptor authInterceptor;

  ApiClient({
    required this.baseUrl,
    required this.tokenStorage,
    required this.authInterceptor,
  });

  Future<ApiResult<Map<String, dynamic>>> get(String endpoint) async {
    try {
      final token = await tokenStorage.readAccessToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiFailure('Network error: ${e.toString()}');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final token = await tokenStorage.readAccessToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiFailure('Network error: ${e.toString()}');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> uploadFile(
    String endpoint,
    String filePath,
    String fieldName,
  ) async {
    try {
      final token = await tokenStorage.readAccessToken();
      final uri = Uri.parse('$baseUrl$endpoint');

      final request = http.MultipartRequest('POST', uri);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      return ApiFailure('Upload error: ${e.toString()}');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> _handleResponse(
    http.Response response,
  ) async {
    if (response.statusCode == 401) {
      authInterceptor.notifyUnauthorized();
      return ApiFailure('Unauthorized', statusCode: 401);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiSuccess(json);
    }

    return ApiFailure(
      'Request failed with status ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }
}
