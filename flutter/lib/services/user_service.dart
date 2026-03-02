import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

// Service untuk mengelola data Pengguna (User) melalui API
// Digunakan oleh admin untuk mengelola akun petugas dan owner
class UserService {
  // Mengambil semua data pengguna yang terdaftar di sistem
  // Memerlukan autentikasi level admin
  // Mengembalikan List<User> dengan semua akun (admin, petugas, owner)
  static Future<List<User>> getAllUsers() async {
    try {
      final response = await ApiService.get(ApiConfig.users, auth: true);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final data = ApiService.handleResponse(response);
      print('Parsed data: $data');
      
      if (data['success']) {
        // Konversi list JSON menjadi list objek User
        final userList = (data['data'] as List)
            .map((json) => User.fromJson(json))
            .toList();
        print('User list count: ${userList.length}');
        return userList;
      } else {
        throw Exception(data['message'] ?? 'Gagal mengambil data user');
      }
    } catch (e) {
      print('Error in getAllUsers: $e');
      rethrow; // Teruskan error ke pemanggil agar dapat ditangani di UI
    }
  }

  // Membuat akun pengguna baru
  // Memerlukan autentikasi (hanya admin yang dapat menambah pengguna)
  // Parameter: [namaLengkap], [username], [password], [role] ('admin'/'petugas'/'owner')
  static Future<void> createUser({
    required String namaLengkap,
    required String username,
    required String password,
    required String role,
  }) async {
    final response = await ApiService.post(
      ApiConfig.register, // Menggunakan endpoint register untuk membuat user baru
      {
        'nama_lengkap': namaLengkap,
        'username': username,
        'password': password,
        'role': role,
      },
      auth: true, // Butuh token JWT level admin
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal menambahkan user');
    }
  }

  // Memperbarui data pengguna yang sudah ada
  // Memerlukan autentikasi
  // Password bersifat opsional - hanya diupdate jika diisi oleh admin
  static Future<void> updateUser({
    required int idUser,
    required String namaLengkap,
    required String username,
    String? password,
    required String role,
  }) async {
    // Buat body request dengan field wajib
    final body = {
      'nama_lengkap': namaLengkap,
      'username': username,
      'role': role,
    };

    // Hanya tambahkan password jika diisi (kosong = tidak mengubah password)
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }

    final response = await ApiService.put(
      '${ApiConfig.users}/$idUser', // Endpoint dengan ID user di URL
      body,
      auth: true, // Butuh token JWT
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal mengupdate user');
    }
  }

  // Menghapus pengguna berdasarkan ID
  // Memerlukan autentikasi level admin
  // Catatan: pastikan pengguna tidak memiliki transaksi aktif sebelum dihapus
  static Future<void> deleteUser(int idUser) async {
    final response = await ApiService.delete(
      '${ApiConfig.users}/$idUser', // Endpoint dengan ID user di URL
      auth: true, // Butuh token JWT
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal menghapus user');
    }
  }
}
