import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';

class LikesProvider extends ChangeNotifier {
  final Set<String> _likedMovieIds = {};

  Set<String> get likedMovieIds => _likedMovieIds;

  void like(String movieId) {
    _likedMovieIds.add(movieId);
    notifyListeners();
  }

  void unlike(String movieId) {
    _likedMovieIds.remove(movieId);
    notifyListeners();
  }

  bool isLiked(String movieId) => _likedMovieIds.contains(movieId);

  void setLikes(Set<String> ids) {
    _likedMovieIds
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }

  Future<void> fetchUserLikes(String userId) async {
    try {
      final response = await http.get(Uri.parse('${Environment.apiBaseUrl}/likes/all'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> likes = data['likes'] ?? [];
        final userLikes = likes.where((like) => like['user_id'].toString() == userId).toList();
        final ids = userLikes.map((like) => like['movie_id'].toString()).toSet();
        setLikes(ids);
      }
    } catch (e) {
      print('Erreur lors du chargement des likes utilisateur: $e');
    }
  }
} 