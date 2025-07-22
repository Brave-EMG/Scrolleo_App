import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import '../config/environment.dart';

class FavoriteEpisodeService {
  static String get baseUrl => Environment.apiBaseUrl;

  Future<bool> addToFavorites(String userId, String movieId, String episodeId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/favorites'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'movie_id': movieId,
          'episode_id': episodeId,
        }),
      );
      print('[DEBUG] addToFavorites: status=${response.statusCode}, body=${response.body}');
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de l\'ajout aux favoris: $e');
      return false;
    }
  }

  Future<bool> removeFromFavorites(String userId, String episodeId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/favorites/$userId/$episodeId'),
      );
      print('[DEBUG] removeFromFavorites: status=${response.statusCode}, body=${response.body}');
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la suppression des favoris: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getFavorites(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/favorites/$userId'),
      );
      print('[DEBUG] getFavorites: status=${response.statusCode}, body=${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des favoris: $e');
      return [];
    }
  }
} 