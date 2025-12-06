import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:order_admin_panel/core/api_config.dart';

class AuthRepository {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: ApiConfig.headers,
        body: jsonEncode({"email": email, "password": password}),
      );

      if(response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else {
        return {"status": "error", "message": "Server Error: ${response.statusCode}"};
      }
    } catch (e) {
      return {"status": "error", "message": "Connection Failed: $e"};
    }
  }

  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String role,
    required String creatorRole,
    required String creatorEmail
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createUser),
        headers: ApiConfig.headers,
        body: jsonEncode({
          "email": email,
          "password": password,
          "role": role,
          "creator_role": creatorRole,
          "creator_email": creatorEmail
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"status": "error", "message": "Server Error: ${response.statusCode}"};
      }
    } catch (e) {
      return {"status": "error", "message": "Connection Failed: $e"};
    }
  }

}