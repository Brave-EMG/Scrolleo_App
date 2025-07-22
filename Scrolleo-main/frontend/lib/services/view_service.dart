import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';

class ViewService {
  static final String baseUrl = Environment.apiBaseUrl;

  static Future<void> updateEpisodeView({
    required int userId,
    required int episodeId,
    required int watchDuration,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/views/episode-views'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'episode_id': episodeId,
          'watch_duration': watchDuration,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la mise à jour de la vue: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de la mise à jour de la vue: $e');
    }
  }

  // Enregistrer la vue d'un épisode
  static Future<void> addEpisodeView({
    required int userId,
    required int episodeId,
    required int movieId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/views/episode'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'episode_id': episodeId,
          'movie_id': movieId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de l\'ajout de la vue épisode: \\${response.body}');
      }
    } catch (e) {
      print('Erreur lors de l\'ajout de la vue épisode: $e');
    }
  }

  // Enregistrer la vue du film (logique 75%)
  static Future<void> addMovieView({
    required int userId,
    required int movieId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/views/movie'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'movie_id': movieId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de l\'ajout de la vue film: \\${response.body}');
      }
    } catch (e) {
      print('Erreur lors de l\'ajout de la vue film: $e');
    }
  }
} 