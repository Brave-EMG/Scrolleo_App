class Environment {
  //static const bool isProduction = true; // Changez à true pour la production
  static const String env = String.fromEnvironment('ENV', defaultValue: 'production');
  static bool get isProduction => env == 'production';
  // API URLs
  // flutter run --dart-define=ENV=local
 // static const String localApi = 'http://localhost:3000/api';
  // flutter run --dart-define=ENV=production
 // static const String productionApi = 'https://scrolleo-backend.onrender.com/api'; // À changer avec l'URL Render
  static const String productionApi = 'https://scrolleo.onrender.com/api'; // À changer avec l'URL Render
  static const String localApi = 'https://scrolleo.onrender.com/api'; // À changer avec l'URL Render

  // Configuration actuelle
  static String get apiBaseUrl => isProduction ? productionApi : localApi;

  // Upload configurations
  static String get uploadBaseUrl => '$apiBaseUrl/uploads';
  static String get cloudFrontUrl => 'https://d2h8q0ttenj5cb.cloudfront.net';

  // Endpoints
  static final endpoints = _Endpoints();
}

class _Endpoints {
  final auth = _AuthEndpoints();
  final movies = _MovieEndpoints();
  final episodes = _EpisodeEndpoints();
  final users = _UserEndpoints();
}

class _AuthEndpoints {
  final String login = '/auth/login';
  final String register = '/auth/register';
  final String logout = '/auth/logout';
  final String realisateurs = '/auth/users/realisateurs';
}

class _MovieEndpoints {
  final String base = '/movies';
  final String popular = '/movies/popular';
  final String search = '/movies/search';
}

class _EpisodeEndpoints {
  final String base = '/episodes';
  final String views = '/views';
  final String favorites = '/favorites';
}

class _UserEndpoints {
  final String profile = '/users/profile';
  final String update = '/users/update';
  final String favorites = '/users/favorites';
}
