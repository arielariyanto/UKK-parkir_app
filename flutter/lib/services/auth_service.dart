import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  // Login
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await ApiService.post(
        ApiConfig.login,
        {
          'username': username,
          'password': password,
        },
      );

      final data = ApiService.handleResponse(response);
      
      if (data['success']) {
        // Save token and user info
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['data']['token']);
        await prefs.setString('user', jsonEncode(data['data']['user']));
        
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Login gagal');
      }
    } catch (e) {
      // Handle different types of errors
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Koneksi timeout. Silakan coba lagi.');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Terjadi kesalahan: ${e.toString()}');
      }
    }
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // Get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Get user info
  static Future<User?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    
    if (userJson != null) {
      final userMap = jsonDecode(userJson);
      return User.fromJson(userMap);
    }
    
    return null;
  }

  // Check if logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
