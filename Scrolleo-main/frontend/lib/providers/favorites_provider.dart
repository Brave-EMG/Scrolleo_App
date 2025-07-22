import 'package:flutter/foundation.dart';
import '../services/favorites_service.dart';
import '../services/movie_service.dart';
import '../models/movie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';

class FavoritesProvider with ChangeNotifier {
  final List<Movie> _favorites = [];
  static const String _favoritesKey = 'favorites';
  late final FavoritesService _favoritesService;
  final MovieService _movieService;
  bool _isLoading = false;

  FavoritesProvider(this._movieService) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _favoritesService = FavoritesService(prefs);
    await _loadFavorites();
  }

  List<Movie> get favorites => List.unmodifiable(_favorites);
  bool get isLoading => _isLoading;

  Future<void> _loadFavorites() async {
    if (kIsWeb) return;
    
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList(_favoritesKey);
    
    if (favoritesJson != null) {
      _favorites.addAll(
        favoritesJson.map((json) => Movie.fromJson(jsonDecode(json))),
      );
      notifyListeners();
    }
  }

  Future<void> _saveFavorites() async {
    if (kIsWeb) return;
    
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = _favorites
        .map((movie) => jsonEncode(movie.toJson()))
        .toList();
    
    await prefs.setStringList(_favoritesKey, favoritesJson);
  }

  bool isFavorite(Movie movie) {
    return _favorites.contains(movie);
  }

  void addToFavorites(Movie movie) {
    if (!_favorites.contains(movie)) {
      _favorites.add(movie);
      notifyListeners();
    }
  }

  void removeFromFavorites(Movie movie) {
    if (_favorites.remove(movie)) {
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(Movie movie) async {
    if (isFavorite(movie)) {
      _favorites.removeWhere((m) => m.id == movie.id);
    } else {
      _favorites.add(movie);
    }
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> addFavorite(Movie movie) async {
    if (!isFavorite(movie)) {
      _favorites.add(movie);
      await _saveFavorites();
      String? userId;
      try {
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString('user');
        if (userJson != null) {
          final user = jsonDecode(userJson);
          userId = user['id']?.toString() ?? user['user_id']?.toString();
        }
      } catch (_) {}
      if (userId != null) {
        await _favoritesService.addFavoriteBackend(userId: userId, episodeId: movie.id.toString());
      }
      notifyListeners();
    }
  }

  Future<void> removeFavorite(Movie movie) async {
    if (isFavorite(movie)) {
      _favorites.removeWhere((m) => m.id == movie.id);
      await _saveFavorites();
      String? userId;
      try {
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString('user');
        if (userJson != null) {
          final user = jsonDecode(userJson);
          userId = user['id']?.toString() ?? user['user_id']?.toString();
        }
      } catch (_) {}
      if (userId != null) {
        await _favoritesService.removeFavoriteBackend(userId: userId, episodeId: movie.id.toString());
      }
      notifyListeners();
    }
  }

  Future<void> loadFavorites() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      String? userId;
      try {
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString('user');
        if (userJson != null) {
          final user = jsonDecode(userJson);
          userId = user['id']?.toString() ?? user['user_id']?.toString();
        }
      } catch (_) {}
      if (userId != null) {
        final url = '${Environment.apiBaseUrl}/favorites/$userId';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          _favorites.clear();
          for (final item in data) {
            _favorites.add(Movie.fromJson(item));
          }
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des favoris: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 