import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  Locale _locale = const Locale('fr');

  Locale get locale => _locale;

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('locale') ?? 'fr';
    _locale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
    notifyListeners();
  }

  // Méthode pour obtenir le texte traduit
  String getText(String key) {
    if (_locale.languageCode == 'en') {
      return _englishTranslations[key] ?? key;
    }
    return _frenchTranslations[key] ?? key;
  }

  // Traductions en français
  static const Map<String, String> _frenchTranslations = {
    'home': 'Accueil',
    'directors': 'Réalisateurs',
    'movies': 'Films',
    'videos': 'Vidéos',
    'add': 'Ajouter',
    'edit': 'Modifier',
    'delete': 'Supprimer',
    'popular_movies': 'Films populaires',
    'new_movies': 'Nouveautés',
    'director_videos': 'Vidéos du Réalisateur',
    'video_url': 'URL de la vidéo',
    'no_movies': 'Aucun film trouvé',
    'no_directors': 'Aucun réalisateur trouvé',
    'loading': 'Chargement...',
    'error': 'Erreur',
    'retry': 'Réessayer',
    'views': 'vues',
    'likes': 'likes',
    'films': 'films',
  };

  // Traductions en anglais
  static const Map<String, String> _englishTranslations = {
    'home': 'Home',
    'directors': 'Directors',
    'movies': 'Movies',
    'videos': 'Videos',
    'add': 'Add',
    'edit': 'Edit',
    'delete': 'Delete',
    'popular_movies': 'Popular Movies',
    'new_movies': 'New Releases',
    'director_videos': 'Director Videos',
    'video_url': 'Video URL',
    'no_movies': 'No movies found',
    'no_directors': 'No directors found',
    'loading': 'Loading...',
    'error': 'Error',
    'retry': 'Retry',
    'views': 'views',
    'likes': 'likes',
    'films': 'films',
  };
} 