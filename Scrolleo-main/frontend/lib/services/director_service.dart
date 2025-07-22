import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment.dart';

class DirectorService {
  final String baseUrl = Environment.apiBaseUrl + '/auth';

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Récupérer tous les réalisateurs
  Future<List<Map<String, dynamic>>> getAllDirectors() async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Non authentifié');

      final response = await http.get(
        Uri.parse('$baseUrl/users/realisateurs'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Échec du chargement des réalisateurs');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Modifier un réalisateur
  Future<Map<String, dynamic>> updateDirector(int id, Map<String, dynamic> directorData) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Non authentifié');

      // Préparer les données pour la mise à jour
      final updateData = {
        'username': directorData['username'],
        'email': directorData['email'],
        'role': 'realisateur', // S'assurer que le rôle reste 'realisateur'
      };

      final response = await http.put(
        Uri.parse('$baseUrl/users/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Réalisateur non trouvé');
      } else {
        throw Exception('Échec de la mise à jour du réalisateur');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Supprimer un réalisateur
  Future<void> deleteDirector(int id) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Non authentifié');

      final response = await http.delete(
        Uri.parse('$baseUrl/users/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Réalisateur non trouvé');
      } else {
        throw Exception('Échec de la suppression du réalisateur');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
} 