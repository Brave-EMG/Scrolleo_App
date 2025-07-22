import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../config/environment.dart';

class MovieService extends ChangeNotifier {
  static const String _moviesKey = 'movies';
  List<Movie> _movies = [];
  List<Movie> _watchHistory = [];
  bool _isLoading = false;
  String? _error;
  final String _baseUrl = Environment.apiBaseUrl;

  List<Movie> get movies => _movies;
  List<Movie> get watchHistory => _watchHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MovieService() {
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/movies'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _movies = data.map((e) => Movie.fromJson(e)).toList();
        _error = null;
      } else {
        _error = 'Erreur lors du chargement des films';
      }
    } catch (e) {
      _error = 'Erreur réseau: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Initialiser le service
  Future<void> init() async {
    _isLoading = true;
    await _loadMovies();
  }

  // CRUD Operations
  Future<void> addMovie(Movie movie) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/movies'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(movie.toJson()),
      );
      
      if (response.statusCode == 201) {
        final newMovie = Movie.fromJson(json.decode(response.body));
        _movies.add(newMovie);
        notifyListeners();
      } else {
        throw Exception('Erreur lors de l\'ajout du film');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateMovie(Movie movie) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/movies/${movie.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(movie.toJson()),
      );
      
      if (response.statusCode == 200) {
        final updatedMovie = Movie.fromJson(json.decode(response.body));
        final index = _movies.indexWhere((m) => m.id == movie.id);
        if (index != -1) {
          _movies[index] = updatedMovie;
          notifyListeners();
        }
      } else {
        throw Exception('Erreur lors de la mise à jour du film');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteMovie(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/movies/$id'),
      );
      
      if (response.statusCode == 200) {
        _movies.removeWhere((movie) => movie.id == id);
        notifyListeners();
      } else {
        throw Exception('Erreur lors de la suppression du film');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Getters
  Future<Movie?> getMovieById(String id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/movies/$id'));
      if (response.statusCode == 200) {
        return Movie.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  Future<List<Movie>> getMovies() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/movies/movies'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Movie.fromJson(e)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erreur lors de la récupération des films: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur dans getMovies: $e');
      return [];
    }
  }

  Future<List<Movie>> getMoviesByGenre(String genre) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/movies/genre/$genre'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Movie.fromJson(e)).toList();
      } else if (response.statusCode == 404) {
        return [];
      }
      return [];
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // Search
  Future<List<Movie>> searchMovies(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movies/search?q=$query'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Movie.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // Interactions
  Future<void> incrementViews(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/movies/$id/view'),
      );
      
      if (response.statusCode == 200) {
        final updatedMovie = Movie.fromJson(json.decode(response.body));
        final index = _movies.indexWhere((m) => m.id == id);
        if (index != -1) {
          _movies[index] = updatedMovie;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<int> likeMovie(String movieId, {String? userId}) async {
    final url = '$_baseUrl/likes';
    final body = {
      'movie_id': int.tryParse(movieId) ?? movieId,
      if (userId != null) 'user_id': int.tryParse(userId) ?? userId,
    };
    print('LIKE BODY: ' + jsonEncode(body));
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    print('LIKE RESPONSE: \\${response.statusCode} \\${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['likes'] ?? 0;
    } else {
      throw Exception('Erreur lors du like du film');
    }
  }

  Future<void> unlikeMovie(String movieId, {String? userId}) async {
    final url = '$_baseUrl/likes/unlike';
    final body = {
      'movie_id': int.tryParse(movieId) ?? movieId,
      if (userId != null) 'user_id': int.tryParse(userId) ?? userId,
    };
    print('UNLIKE BODY: ' + jsonEncode(body));
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    print('UNLIKE RESPONSE: \\${response.statusCode} \\${response.body}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur lors du unlike du film');
    }
  }

  // Watch History
  Future<void> addToWatchHistory(String movieId) async {
    try {
      final movie = await getMovieById(movieId);
      if (movie != null && !_watchHistory.any((m) => m.id == movieId)) {
        _watchHistory.insert(0, movie);
        await _saveWatchHistory();
        await incrementViews(movieId);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _saveWatchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyIds = _watchHistory.map((m) => m.id).toList();
    await prefs.setString('watchHistory', jsonEncode(historyIds));
  }

  Future<void> loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final historyJson = prefs.getString('watchHistory');
      if (historyJson != null) {
        final historyIds = List<String>.from(jsonDecode(historyJson));
        _watchHistory = _movies
            .where((m) => historyIds.contains(m.id))
            .toList();
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<List<Movie>> getNewReleases() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/movies/recentlyadded'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data'] ?? [];
        return data.map((e) => Movie.fromJson(e)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des nouveautés: \\${response.statusCode}');
      }
    } catch (e) {
      print('Erreur dans getNewReleases: $e');
      throw Exception('Erreur réseau: $e');
    }
  }

  Future<List<Movie>> fetchMostViewedMovies() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/movies/mostview'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data'] ?? [];
        return data.map((e) => Movie.fromJson(e)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des films les plus vus: \\${response.statusCode}');
      }
    } catch (e) {
      print('Erreur dans fetchMostViewedMovies: $e');
      throw Exception('Erreur réseau: $e');
    }
  }

  Future<List<Movie>> fetchMostLikedMovies() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/movies/mostliked'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data'] ?? [];
        return data.map((e) => Movie.fromJson(e)).toList();
      } else {
        print('Erreur lors de la récupération des films: \\${response.statusCode}');
        print('Corps de la réponse: \\${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception lors de la récupération des films: $e');
      return [];
    }
  }

  Future<List<Movie>> getUpcomingMovies() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/movies/upcoming'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data'] ?? [];
        return data.map((json) => Movie.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      }
      throw Exception('Erreur lors du chargement des films à venir');
    } catch (e) {
      print('Erreur lors du chargement des films à venir: $e');
      rethrow;
    }
  }

  Future<List<Movie>> getRecentlyAddedMovies() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/movies/recentlyadded'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data'] ?? [];
        return data.map((json) => Movie.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      }
      throw Exception('Erreur lors du chargement des films récemment ajoutés');
    } catch (e) {
      print('Erreur lors du chargement des films récemment ajoutés: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMovie(String movieId) async {
    final response = await http.get(Uri.parse('$_baseUrl/movies/detail/$movieId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la récupération du film');
    }
  }

  Future<List<Movie>> fetchDiscoveryMovies() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/movies/discoveryMovies'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['discovery'] ?? [];
        return data.map((e) => Movie.fromJson(e)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des films découvertes');
      }
    } catch (e) {
      print('Erreur dans fetchDiscoveryMovies: $e');
      throw Exception('Erreur réseau: $e');
    }
  }

  Future<List<dynamic>> fetchUserHistory(String userId) async {
    final url = '$_baseUrl/history/$userId';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Erreur lors de la récupération de l\'historique');
    }
  }

  static Future<List<Movie>> getAllMovies() async {
    final response = await http.get(Uri.parse(Environment.apiBaseUrl + '/movies/movies'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Movie.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<Movie>> fetchTrendingMovies() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/movies/trendingMovies'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['trending'] ?? [];
        return data.map((e) => Movie.fromJson(e)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des films tendances');
      }
    } catch (e) {
      print('Erreur dans fetchTrendingMovies: $e');
      throw Exception('Erreur réseau: $e');
    }
  }

  // Génération de lien de partage
  String generateShareLink(String movieId, {String? episodeId}) {
    // URL de base de l'application
    final String baseUrl = Environment.apiBaseUrl; // URL en local
    
    // Construction du lien
    final Uri shareUrl = Uri(
      scheme: 'http',
      host: 'localhost',
      port: 3000,
      path: '/watch',
      queryParameters: {
        'movieId': movieId,
        if (episodeId != null) 'episodeId': episodeId,
      },
    );

    return shareUrl.toString();
  }

  // Fonction pour partager un film/épisode
  Future<void> shareMovie(String movieId, {String? episodeId}) async {
    try {
      print('[DEBUG] Début du partage - movieId: $movieId, episodeId: $episodeId');
      
      // Générer le lien de partage
      final shareLink = generateShareLink(movieId, episodeId: episodeId);
      print('[DEBUG] Lien de partage généré: $shareLink');
      
      // Utiliser share_plus pour partager le lien
      await Share.share(
        'Regarde ce film sur notre plateforme : $shareLink',
        subject: 'Partage de film',
      );
      
      print('[DEBUG] Partage effectué avec succès');
    } catch (e, stackTrace) {
      print('[ERROR] Erreur lors du partage: $e');
      print('[ERROR] Stack trace: $stackTrace');
      _error = e.toString();
      notifyListeners();
      rethrow; // Propager l'erreur pour la gérer dans l'UI
    }
  }
  Future<List<Movie>> fetchRecommendedMovies() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/movies/RecommendedMovies'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        // L'API retourne directement un tableau, pas un objet avec une clé "recommended"
        final List<dynamic> data = json is List ? json : (json['recommended'] ?? []);
        return data.map((e) => Movie.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Erreur dans fetchRecommendedMovies: $e');
      return [];
    }
  }
} 
