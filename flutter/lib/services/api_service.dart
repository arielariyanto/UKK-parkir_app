import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

// Service HTTP dasar yang menyediakan method GET, POST, PUT, DELETE
// Semua service lain (AuthService, AreaService, dll.) menggunakan class ini
// untuk mengirimkan request ke server backend
class ApiService {
  // Mengambil token JWT yang tersimpan di SharedPreferences
  // Token ini diperlukan untuk autentikasi request yang membutuhkan otorisasi
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Membangun header HTTP untuk setiap request
  // Secara default hanya menyertakan Content-Type JSON
  // Jika [includeAuth] = true, tambahkan header Authorization dengan Bearer token
  static Future<Map<String, String>> _getHeaders({bool includeAuth = false}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json', // Semua body request dikirim dalam format JSON
    };

    if (includeAuth) {
      final token = await _getToken();
      if (token != null) {
        // Format standar Bearer token untuk autentikasi JWT
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Mengirim HTTP GET request ke [endpoint]
  // Gunakan [auth: true] jika endpoint memerlukan autentikasi (token JWT)
  static Future<http.Response> get(String endpoint, {bool auth = false}) async {
    final headers = await _getHeaders(includeAuth: auth);
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    return await http.get(url, headers: headers);
  }

  // Mengirim HTTP POST request ke [endpoint] dengan [body] sebagai data
  // Digunakan untuk membuat data baru (create) atau login
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
      body: jsonEncode(body), // Konversi Map ke JSON string
    );
  }

  // Mengirim HTTP PUT request ke [endpoint] dengan [body] sebagai data yang diperbarui
  // Digunakan untuk memperbarui data yang sudah ada
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
      body: jsonEncode(body), // Konversi Map ke JSON string
    );
  }

  // Mengirim HTTP DELETE request ke [endpoint]
  // Digunakan untuk menghapus data di server
  static Future<http.Response> delete(String endpoint, {bool auth = false}) async {
    final headers = await _getHeaders(includeAuth: auth);
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    return await http.delete(url, headers: headers);
  }

  // Memproses respons HTTP dari server
  // Jika status code 2xx (sukses), parse body JSON dan kembalikan sebagai Map
  // Jika status code lain (error), lemparkan Exception dengan pesan yang sesuai
  static Map<String, dynamic> handleResponse(http.Response response) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Request berhasil - parse dan kembalikan data JSON
        final data = jsonDecode(response.body);
        return data;
      } else {
        // Request gagal - coba ambil pesan error dari body respons
        String errorMsg = 'Terjadi kesalahan';
        try {
          final error = jsonDecode(response.body);
          errorMsg = error['message'] ?? errorMsg;
        } catch (_) {
          // Body respons bukan JSON - tampilkan pesan berdasarkan status code
          if (response.statusCode == 401) {
            errorMsg = 'Username atau kata sandi salah';
          } else if (response.statusCode == 403) {
            errorMsg = 'Akses ditolak';
          } else if (response.statusCode == 404) {
            errorMsg = 'Data tidak ditemukan';
          } else {
            errorMsg = 'Terjadi kesalahan (${response.statusCode})';
          }
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow; // Kembalikan Exception yang sudah dibuat di atas
      }
      // Tangani error parsing JSON yang tidak terduga
      throw Exception('Terjadi kesalahan dalam memproses data');
    }
  }
}
