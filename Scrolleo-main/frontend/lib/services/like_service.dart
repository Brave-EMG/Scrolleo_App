import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';

class LikeService {
  Future<void> likeMovie(String userId, String movieId) async {
    try {
      print('Tentative de like - userId: $userId, movieId: $movieId');
      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}/likes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'movie_id': movieId}),
      );
      
      print('Réponse du serveur - Status: ${response.statusCode}, Body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        throw Exception('Erreur lors du like: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Erreur lors du like: $e');
      throw Exception('Erreur lors du like: $e');
    }
  }

  Future<void> unlikeMovie(String userId, String movieId) async {
    try {
      print('Tentative de unlike - userId: $userId, movieId: $movieId');
      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}/likes/unlike'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'movie_id': movieId}),
      );
      
      print('Réponse du serveur - Status: ${response.statusCode}, Body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        throw Exception('Erreur lors du unlike: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Erreur lors du unlike: $e');
      throw Exception('Erreur lors du unlike: $e');
    }
  }
} 