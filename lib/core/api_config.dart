class ApiConfig {
  // 1. Base URL - Change this here, and it updates everywhere
  static const String _baseUrl = "https://taraenter.com";

  // 2. Endpoints
  static const String login = "$_baseUrl/login.php";
  static const String uploadCsv = "$_baseUrl/upload_file.php";
  static const String getData = "$_baseUrl/get_data.php";
  static const String createUser = "$_baseUrl/create_user.php";
  static const String getUsers = "$_baseUrl/get_users.php";
  static const String deleteUser = "$_baseUrl/delete_user.php";
  static const String updateUser = "$_baseUrl/update_user.php";
  static const String getProfile = "$_baseUrl/get_profile.php";
  static const String updateProfile = "$_baseUrl/update_profile.php";
  static const String changePassword = "$_baseUrl/change_password.php";
  static const String forgotPassword = "$_baseUrl/forgot_password.php";

  // 3. Headers (Standard headers for JSON)
  static const Map<String, String> headers = {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };
}
