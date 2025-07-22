import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final _storage = FlutterSecureStorage();

  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  // Méthode pour récupérer le token d'authentification
  Future<String?> getToken() async {
    // Essayer d'abord FlutterSecureStorage avec la clé 'auth_token'
    String? token = await _storage.read(key: 'auth_token');
    
    // Si pas trouvé, essayer SharedPreferences avec la clé 'jwt_token'
    if (token == null) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('jwt_token');
    }
    
    return token;
  }

  // Méthode pour sauvegarder le token d'authentification
  Future<void> saveToken(String token) async {
    // Sauvegarder dans les deux endroits pour compatibilité
    await _storage.write(key: 'auth_token', value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }
} 