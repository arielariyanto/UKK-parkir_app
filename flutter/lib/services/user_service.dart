import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class UserService {
  static Future<List<User>> getAllUsers() async {
    final response = await ApiService.get(ApiConfig.users, auth: true);
    final data = ApiService.handleResponse(response);
    
    return (data['data'] as List)
        .map((json) => User.fromJson(json))
        .toList();
  }

  static Future<void> createUser(Map<String, dynamic> userData) async {
    await ApiService.post(
      '${ApiConfig.users}/register',
      userData,
      auth: true,
    );
  }

  static Future<void> updateUser(int id, Map<String, dynamic> userData) async {
    await ApiService.put(
      '${ApiConfig.users}/$id',
      userData,
      auth: true,
    );
  }

  static Future<void> deleteUser(int id) async {
    await ApiService.delete(
      '${ApiConfig.users}/$id',
      auth: true,
    );
  }
}
