import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:order_admin_panel/core/api_config.dart';

class DataRepository {

  // 1. Fetch Data (with optional search)
  Future<List<dynamic>> getOrders(String query) async {
    try {
      // Construct URL: https://taraenter.com/get_data.php?search=query
      final uri = Uri.parse("${ApiConfig.getData}?search=$query");

      final response = await http.get(uri, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        // Parse the JSON list
        return jsonDecode(response.body);
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection Failed: $e");
    }
  }

  // 2. Upload CSV File
  // Note: On Flutter Web, we use 'bytes' instead of 'File' path
  Future<Map<String, dynamic>> uploadCsv(List<int> fileBytes, String filename) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.uploadCsv));

      // Attach the file using bytes (Required for Web)
      request.files.add(
          http.MultipartFile.fromBytes(
              'csv_file',
              fileBytes,
              filename: filename
          )
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print("🛑 SERVER ERROR RAW RESPONSE: $responseBody"); // <--- ADD THIS LINE

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        throw Exception("Upload Failed: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error uploading file: $e");
    }
  }
}