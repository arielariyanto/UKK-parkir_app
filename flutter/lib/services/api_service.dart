import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _getHeaders({bool includeAuth = false}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // GET request
  static Future<http.Response> get(String endpoint, {bool auth = false}) async {
    final headers = await _getHeaders(includeAuth: auth);
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    return await http.get(url, headers: headers);
  }

  // POST request
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final headers = await _getHeaders(includeAuth: auth);
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    return await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // PUT request
  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final headers = await _getHeaders(includeAuth: auth);
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    return await http.put(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // DELETE request
  static Future<http.Response> delete(String endpoint, {bool auth = false}) async {
    final headers = await _getHeaders(includeAuth: auth);
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    return await http.delete(url, headers: headers);
  }

  // Handle response
  static Map<String, dynamic> handleResponse(http.Response response) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        // Try to parse error response
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'Terjadi kesalahan');
        } catch (e) {
          // If JSON parsing fails, use status code message
          throw Exception('Terjadi kesalahan: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      // Handle JSON parsing errors
      throw Exception('Terjadi kesalahan dalam memproses data');
    }
  }
}
