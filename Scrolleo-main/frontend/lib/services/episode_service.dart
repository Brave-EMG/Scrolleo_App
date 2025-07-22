import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../models/episode.dart' as ep;
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment.dart';

class EpisodeService {
  final String _baseUrl = Environment.apiBaseUrl;
  final storage = StorageService();

  Future<Map<String, dynamic>> getEpisodeUpload(String episodeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/episodes/$episodeId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['episode'];
      } else {
        throw Exception('Erreur lors de la récupération de l\'épisode: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'épisode: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getEpisodesForMovie(String movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/episodes/movie/$movieId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> episodesList;
        if (data is List) {
          episodesList = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['episodes'] is List) {
          episodesList = (data['episodes'] as List).cast<Map<String, dynamic>>();
        } else {
          episodesList = [];
        }
        // Tri par numéro d'épisode croissant
        episodesList.sort((a, b) => (a['episode_number'] ?? 0).compareTo(b['episode_number'] ?? 0));
        return episodesList;
      } else {
        throw Exception('Erreur lors de la récupération des épisodes: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des épisodes: $e');
      rethrow;
    }
  }

  Future<bool> updateEpisode(String episodeId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/episodes/$episodeId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<bool> deleteEpisode(String episodeId) async {
    try {
      // Vérifier si l'ID est valide
      if (episodeId.isEmpty || episodeId == 'null') {
        throw Exception('ID d\'épisode invalide');
      }

      // S'assurer que l'ID est un nombre
      final id = int.tryParse(episodeId);
      if (id == null) {
        throw Exception('ID d\'épisode doit être un nombre');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/episodes/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('Erreur lors de la suppression: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Erreur lors de la suppression de l\'épisode: $e');
      rethrow;
    }
  }

  Future<List<Movie>> getFirstEpisodes(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/episodes/first/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des premiers épisodes');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<List<ep.Episode>> getFirstEpisodesForMovies(List<Movie> movies, String userId) async {
    List<ep.Episode> episodes = [];
    for (final movie in movies) {
      final response = await http.get(
        Uri.parse('$_baseUrl/episodes/first/${movie.id}/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        episodes.add(ep.Episode.fromApiResponse(data));
      }
    }
    return episodes;
  }

  static Future<ep.Episode?> getFirstEpisode(int movieId, int userId) async {
    final response = await http.get(
      Uri.parse('${Environment.apiBaseUrl}/episodes/first/$movieId/$userId')
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ep.Episode.fromJson(data);
    }
    return null;
  }

  Future<bool> recordEpisodeView(String episodeId, String movieId, String userId, String token) async {
    try {
      print('[DEBUG FRONT] Token reçu: ${token != null ? 'présent' : 'null'}');
      if (token == null) {
        throw Exception('Utilisateur non connecté');
      }
      final body = jsonEncode({
        'user_id': userId,
        'episode_id': episodeId,
        'movie_id': movieId,
      });
      print('[DEBUG FRONT] Body envoyé à l\'API /views/episode : ' + body);
      print('[DEBUG FRONT] URL de la requête: $_baseUrl/views/episode');
      final response = await http.post(
        Uri.parse('$_baseUrl/views/episode'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );
      print('[DEBUG FRONT] Réponse backend : ' + response.statusCode.toString() + ' - ' + response.body);
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Erreur lors de l\'enregistrement de la vue: ' + response.statusCode.toString() + ' - ' + response.body);
        return false;
      }
    } catch (e) {
      print('[DEBUG FRONT] Erreur lors de l\'enregistrement de la vue: ' + e.toString());
      return false;
    }
  }

  Future<int> getEpisodeViews(String episodeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/views/episode-views'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Compter le nombre d'objets pour cet épisode
        final count = data.where((view) => view['episode_id'].toString() == episodeId).length;
        return count;
      } else {
        print('Erreur lors de la récupération des vues: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      print('Erreur lors de la récupération des vues: $e');
      return 0;
    }
  }

  // Vérifier l'accès à un épisode
  Future<Map<String, dynamic>> checkEpisodeAccess(String episodeId) async {
    try {
      final token = await storage.getToken();
      print('[DEBUG] Token récupéré: ${token != null ? 'présent' : 'null'}');
      
      final headers = {
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        print('[DEBUG] Header Authorization ajouté');
      } else {
        print('[DEBUG] Aucun token trouvé - utilisateur non connecté');
      }

      print('[DEBUG] URL de la requête: $_baseUrl/episodes/$episodeId/access');
      print('[DEBUG] Headers envoyés: $headers');

      final response = await http.get(
        Uri.parse('$_baseUrl/episodes/$episodeId/access'),
        headers: headers,
      );

      print('[DEBUG] Réponse du serveur: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de la vérification d\'accès: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la vérification d\'accès: $e');
      rethrow;
    }
  }

  // Débloquer un épisode
  Future<Map<String, dynamic>> unlockEpisode(String episodeId) async {
    try {
      final token = await storage.getToken();
      print('[DEBUG] Token pour déblocage: ${token != null ? 'présent' : 'null'}');
      
      if (token == null) {
        throw Exception('Utilisateur non connecté');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('[DEBUG] URL de déblocage: $_baseUrl/episodes/$episodeId/unlock');
      print('[DEBUG] Headers de déblocage: $headers');

      final response = await http.post(
        Uri.parse('$_baseUrl/episodes/$episodeId/unlock'),
        headers: headers,
      );

      print('[DEBUG] Réponse de déblocage: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Erreur lors du déblocage');
      }
    } catch (e) {
      print('Erreur lors du déblocage de l\'épisode: $e');
      rethrow;
    }
  }
} 