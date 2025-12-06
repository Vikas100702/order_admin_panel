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

}