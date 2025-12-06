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
    required String fullName,
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
          "full_name": fullName,
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

  Future<Map<String, dynamic>> updateUser({
    required String userId,
    required String fullName,
    required String role,
    required String requesterRole,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.updateUser),
        headers: ApiConfig.headers,
        body: jsonEncode({
          "id": userId,
          "full_name": fullName, // Matches your DB column
          "role": role,
          "requester_role": requesterRole
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

  Future<List<dynamic>> getUsers(String requesterRole) async {
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      // We pass the role as a query parameter
      final uri = Uri.parse("${ApiConfig.getUsers}?role=$requesterRole&time=$timestamp");

      final response = await http.get(uri, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['data']; // Returns the list of users
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to load users: $e");
    }
  }

  // 2. Delete a User
  Future<Map<String, dynamic>> deleteUser(String userIdToDelete,
      String requesterRole) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.deleteUser),
        headers: ApiConfig.headers,
        body: jsonEncode({
          "id": userIdToDelete,
          "requester_role": requesterRole
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "status": "error",
          "message": "Server Error: ${response.statusCode}"
        };
      }
    } catch (e) {
      return {"status": "error", "message": "Connection Failed: $e"};
    }
  }

  // 1. Get Profile Details
  Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.getProfile}?id=$userId"),
        headers: ApiConfig.headers,
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

  // 2. Update Profile Details
  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String fullName,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.updateProfile),
        headers: ApiConfig.headers,
        body: jsonEncode({
          "id": userId,
          "full_name": fullName,
          "email": email,
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

  // 3. Change Password
  Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.changePassword),
        headers: ApiConfig.headers,
        body: jsonEncode({
          "id": userId,
          "old_password": oldPassword,
          "new_password": newPassword,
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

  // 4. Forgot Password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.forgotPassword),
        headers: ApiConfig.headers,
        body: jsonEncode({"email": email}),
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