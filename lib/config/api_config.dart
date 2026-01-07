class ApiConfig {
  // Ganti dengan URL server Anda
  static const String baseUrl = 'http://192.168.1.100/anime-api';
  
  // Auth endpoints
  static const String login = '$baseUrl/auth/login.php';
  static const String register = '$baseUrl/auth/register.php';
  static const String logout = '$baseUrl/auth/logout.php';
  
  // Anime endpoints
  static const String getAllAnime = '$baseUrl/anime/get_all.php';
  static const String getAnimeById = '$baseUrl/anime/get_by_id.php';
  static const String createAnime = '$baseUrl/anime/create.php';
  static const String updateAnime = '$baseUrl/anime/update.php';
  static const String deleteAnime = '$baseUrl/anime/delete.php';
  static const String searchAnime = '$baseUrl/anime/search.php';
  
  // Favorites endpoints
  static const String getFavorites = '$baseUrl/favorites/get_all.php';
  static const String addFavorite = '$baseUrl/favorites/add.php';
  static const String removeFavorite = '$baseUrl/favorites/remove.php';
  
  // Headers
  static Map<String, String> getHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}