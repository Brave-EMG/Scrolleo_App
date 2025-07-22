class ApiConfig {
  // URL de l'API en production
  static const String baseUrl = 'https://scrolleo-backend.onrender.com';
  
  // Toujours utiliser l'API en ligne, même en local
  static String get apiUrl => baseUrl;
} 