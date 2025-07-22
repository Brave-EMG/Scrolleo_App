import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../config/environment.dart';

class FavoritesService {
  final SharedPreferences _prefs;
  static const String _favoritesKey = 'favorites';
  final String _baseUrl = Environment.apiBaseUrl;

  FavoritesService(this._prefs);

  Future<List<String>> getFavoriteIds() async {
    final favorites = _prefs.getStringList(_favoritesKey) ?? [];
    return favorites;
  }

  Future<bool> toggleFavorite(String movieId) async {
    final favorites = await getFavoriteIds();
    final isCurrentlyFavorite = favorites.contains(movieId);
    
    if (isCurrentlyFavorite) {
      favorites.remove(movieId);
    } else {
      favorites.add(movieId);
    }

    await _prefs.setStringList(_favoritesKey, favorites);
    return !isCurrentlyFavorite;
  }

  Future<bool> isFavorite(String movieId) async {
    final favorites = await getFavoriteIds();
    return favorites.contains(movieId);
  }

  Future<void> clearFavorites() async {
    await _prefs.remove(_favoritesKey);
  }

  Future<void> addFavoriteBackend({required String userId, required String episodeId}) async {
    final url = Environment.apiBaseUrl + '/favorites/';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': int.tryParse(userId) ?? userId,
        'episode_id': int.tryParse(episodeId) ?? episodeId,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur lors de l\'ajout aux favoris');
    }
  }

  Future<void> removeFavoriteBackend({required String userId, required String episodeId}) async {
    final url = Environment.apiBaseUrl + '/favorites/$userId/$episodeId';
    final response = await http.delete(Uri.parse(url));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erreur lors de la suppression des favoris');
    }
  }

  Future<List<Movie>> getUserFavorites(String userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse(Environment.apiBaseUrl + '/favorites/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Movie.fromJson(json)).toList();
      } else {
        print('Erreur lors de la récupération des favoris: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Erreur lors de la récupération des favoris: $e');
      return [];
    }
  }

  Future<bool> addToFavorites(String userId, String movieId, String token) async {
    try {
      final response = await http.post(
        Uri.parse(Environment.apiBaseUrl + '/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'movie_id': movieId,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Erreur lors de l\'ajout aux favoris: $e');
      return false;
    }
  }

  Future<bool> removeFromFavorites(String userId, String movieId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse(Environment.apiBaseUrl + '/favorites/$userId/$movieId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Erreur lors de la suppression des favoris: $e');
      return false;
    }
  }
} 