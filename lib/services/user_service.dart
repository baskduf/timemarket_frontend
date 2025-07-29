import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:timemarket_frontend/models/user_model.dart';
import 'auth_service.dart';

class UserService {
  final AuthService authService = AuthService();

  Future<User?> getMyInfo() async {
    final token = await authService.getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/users/me/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<bool> updateMyInfo(String username, String email) async {
    final token = await authService.getToken();
    if (token == null) return false;

    final response = await http.patch(
      Uri.parse('$baseUrl/users/me/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'username': username, 'email': email}),
    );
    return response.statusCode == 200;
  }
}
