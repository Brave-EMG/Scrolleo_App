import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../services/movie_service.dart';
import '../config/environment.dart';

class ReelsService {
  final List<Movie> _movies = [];
  final Random _random = Random();
  final String _likedReelsKey = 'liked_reels';
  Set<String> _likedReels = {};
  final String _baseUrl = Environment.apiBaseUrl;

  ReelsService() {
    _loadLikedReels();
  }

  Future<void> _loadLikedReels() async {
    final prefs = await SharedPreferences.getInstance();
    _likedReels = Set<String>.from(prefs.getStringList(_likedReelsKey) ?? []);
  }

  Future<void> _saveLikedReels() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_likedReelsKey, _likedReels.toList());
  }

  Future<List<Movie>> getRandomReels({int count = 5}) async {
    // Simulation de l'obtention de reels aléatoires depuis une API
    await Future.delayed(const Duration(seconds: 1));
    
    // Pour l'instant, nous utilisons des données fictives
    List<Movie> reels = List.generate(
      count,
      (index) => Movie(
        id: index,
        title: 'Reel ${index + 1}',
        description: 'Description du reel ${index + 1}',
        posterUrl: 'assets/images/movies/thumbnails/${(index % 9) + 1}.jpg',
        videoUrl: 'assets/videos/film1.mp4',
        director: 'Réalisateur ${index + 1}',
        directorId: '',
        releaseDate: DateTime.now(),
        duration: const Duration(minutes: 2),
        rating: 4.5,
        genres: ['Court métrage', 'Divertissement'],
        backdropUrl: 'assets/images/movies/thumbnails/${(index % 9) + 1}.jpg',
        isTrending: true,
      ),
    );

    _movies.addAll(reels);
    return reels;
  }

  Future<void> likeReel(String reelId) async {
    try {
      final isCurrentlyLiked = _likedReels.contains(reelId);
      final action = isCurrentlyLiked ? 'unlike' : 'like';

      final response = await http.patch(
        Uri.parse('$_baseUrl/movies/likes/$reelId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'action': action}),
      );

      if (response.statusCode == 200) {
        if (isCurrentlyLiked) {
      _likedReels.remove(reelId);
    } else {
      _likedReels.add(reelId);
    }
    await _saveLikedReels();
      } else {
        throw Exception('Erreur lors du like: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors du like: $e');
      rethrow;
    }
  }

  Future<bool> isReelLiked(String reelId) async {
    return _likedReels.contains(reelId);
  }

  Future<void> shareReel(String reelId) async {
    try {
      final movieService = MovieService();
      await movieService.shareMovie(reelId);
    } catch (e) {
      print('Erreur lors du partage du reel: $e');
      rethrow;
    }
  }
} 