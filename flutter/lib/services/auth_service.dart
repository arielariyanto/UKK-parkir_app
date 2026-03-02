import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

// Service untuk mengelola autentikasi pengguna
// Menangani proses login, logout, dan penyimpanan sesi pengguna secara lokal
class AuthService {
  // Melakukan login dengan username dan password
  // Jika berhasil, menyimpan token JWT dan data user ke SharedPreferences
  // Mengembalikan data user termasuk token dan info profil
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
        // Simpan token dan data user ke penyimpanan lokal agar sesi tetap ada
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['data']['token']); // Token JWT untuk autentikasi API
        await prefs.setString('user', jsonEncode(data['data']['user'])); // Data user sebagai JSON string
        
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Login gagal');
      }
    } catch (e) {
      // Tangani berbagai jenis error jaringan dengan pesan yang ramah pengguna
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Koneksi timeout. Silakan coba lagi.');
      } else if (e is Exception) {
        rethrow; // Teruskan Exception yang sudah memiliki pesan (misal dari handleResponse)
      } else {
        throw Exception('Terjadi kesalahan: ${e.toString()}');
      }
    }
  }

  // Melakukan logout pengguna
  // Memanggil endpoint logout di server (untuk mengupdate status_aktif ke 0)
  // lalu menghapus token dan data user dari penyimpanan lokal
  static Future<void> logout() async {
    try {
      // Panggil API logout untuk set status_aktif = 0 di database
      await ApiService.post(ApiConfig.logout, {}, auth: true);
    } catch (e) {
      // Abaikan error API - tetap lanjutkan proses logout lokal
      print('Logout API error: $e');
    }
    
    // Hapus token dan data user dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); // Hapus token JWT
    await prefs.remove('user');  // Hapus data profil user
  }

  // Mengambil token JWT dari penyimpanan lokal
  // Mengembalikan null jika pengguna belum login
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Mengambil informasi pengguna yang sedang login dari penyimpanan lokal
  // Data user disimpan sebagai JSON string, diparsing ke objek User
  // Mengembalikan null jika tidak ada data user tersimpan
  static Future<User?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    
    if (userJson != null) {
      final userMap = jsonDecode(userJson); // Parse JSON string ke Map
      return User.fromJson(userMap);        // Buat objek User dari Map
    }
    
    return null; // Belum ada sesi login
  }

  // Mengecek apakah pengguna sedang dalam keadaan login
  // Pengecekan dilakukan berdasarkan keberadaan token di penyimpanan lokal
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null; // true jika token ada, false jika token tidak ditemukan
  }
}
