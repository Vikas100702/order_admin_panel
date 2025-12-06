class ApiConfig {
  // 1. Base URL - Change this here, and it updates everywhere
  static const String _baseUrl = "https://taraenter.com";

  // 2. Endpoints
  static const String login = "$_baseUrl/login.php";
  static const String uploadCsv = "$_baseUrl/upload_file.php";
  static const String getData = "$_baseUrl/get_data.php";
  static const String createUser = "$_baseUrl/create_user.php";

  // 3. Headers (Standard headers for JSON)
  static const Map<String, String> headers = {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };
}
