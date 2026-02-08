import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class UserService {
  // Get all users (admin, petugas, owner only)
  static Future<List<User>> getAllUsers() async {
    try {
      final response = await ApiService.get(ApiConfig.users, auth: true);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final data = ApiService.handleResponse(response);
      print('Parsed data: $data');
      
      if (data['success']) {
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
      rethrow;
    }
  }

  // Create user
  static Future<void> createUser({
    required String namaLengkap,
    required String username,
    required String password,
    required String role,
  }) async {
    final response = await ApiService.post(
      ApiConfig.register,
      {
        'nama_lengkap': namaLengkap,
        'username': username,
        'password': password,
        'role': role,
      },
      auth: true,
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal menambahkan user');
    }
  }

  // Update user
  static Future<void> updateUser({
    required int idUser,
    required String namaLengkap,
    required String username,
    String? password,
    required String role,
  }) async {
    final body = {
      'nama_lengkap': namaLengkap,
      'username': username,
      'role': role,
    };

    // Hanya tambahkan password jika diisi
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }

    final response = await ApiService.put(
      '${ApiConfig.users}/$idUser',
      body,
      auth: true,
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal mengupdate user');
    }
  }

  // Delete user
  static Future<void> deleteUser(int idUser) async {
    final response = await ApiService.delete(
      '${ApiConfig.users}/$idUser',
      auth: true,
    );

    final data = ApiService.handleResponse(response);
    
    if (!data['success']) {
      throw Exception(data['message'] ?? 'Gagal menghapus user');
    }
  }
}
