import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';

class HistoryService {
  static Future<void> updateWatchHistory({
    required String userId,
    required String movieId,
    required String episodeId,
    int lastPosition = 0,
  }) async {
    final response = await http.post(
      Uri.parse(Environment.apiBaseUrl + '/history/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'movie_id': movieId,
        'episode_id': episodeId,
        'last_position': lastPosition,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la mise à jour de l\'historique');
    }
  }
} 