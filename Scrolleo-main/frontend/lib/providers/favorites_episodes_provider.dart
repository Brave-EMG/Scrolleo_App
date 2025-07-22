import 'package:flutter/material.dart';

class FavoritesEpisodesProvider extends ChangeNotifier {
  final Set<String> _favoriteEpisodeIds = {};

  Set<String> get favoriteEpisodeIds => _favoriteEpisodeIds;

  void addFavorite(String episodeId) {
    _favoriteEpisodeIds.add(episodeId);
    notifyListeners();
  }

  void removeFavorite(String episodeId) {
    _favoriteEpisodeIds.remove(episodeId);
    notifyListeners();
  }

  bool isFavorite(String episodeId) => _favoriteEpisodeIds.contains(episodeId);

  void setFavorites(Set<String> ids) {
    _favoriteEpisodeIds
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }
} 