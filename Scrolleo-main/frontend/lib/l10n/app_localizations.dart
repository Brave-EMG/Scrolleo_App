import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ?? AppLocalizations(const Locale('fr'));
  }

  static const _localizedValues = {
    'fr': {
      'language': 'Langue',
      'settings': 'Paramètres',
      'profile': 'Profil',
      'subscription': 'Abonnement',
      'preferences': 'Préférences',
      'helpAndSupport': 'Aide et Support',
      'system': 'Système',
      'light': 'Clair',
      'dark': 'Sombre',
      'favorites': 'Favoris',
      'no_favorites': 'Aucun épisode en favoris',
      'remove_favorite': 'Retirer des favoris',
      'add_favorite': 'Ajouter aux favoris',
      'favorite_error': 'Erreur lors de la gestion des favoris',
      'retry': 'Réessayer',
    },
    'en': {
      'language': 'Language',
      'settings': 'Settings',
      'profile': 'Profile',
      'subscription': 'Subscription',
      'preferences': 'Preferences',
      'helpAndSupport': 'Help & Support',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
      'favorites': 'Favorites',
      'no_favorites': 'No favorite episodes',
      'remove_favorite': 'Remove from favorites',
      'add_favorite': 'Add to favorites',
      'favorite_error': 'Error managing favorites',
      'retry': 'Retry',
    },
  };

  String get language => _localizedValues[locale.languageCode]?['language'] ?? 'Langue';
  String get settings => _localizedValues[locale.languageCode]?['settings'] ?? 'Paramètres';
  String get profile => _localizedValues[locale.languageCode]?['profile'] ?? 'Profil';
  String get subscription => _localizedValues[locale.languageCode]?['subscription'] ?? 'Abonnement';
  String get preferences => _localizedValues[locale.languageCode]?['preferences'] ?? 'Préférences';
  String get helpAndSupport => _localizedValues[locale.languageCode]?['helpAndSupport'] ?? 'Aide et Support';
  String get system => _localizedValues[locale.languageCode]?['system'] ?? 'Système';
  String get light => _localizedValues[locale.languageCode]?['light'] ?? 'Clair';
  String get dark => _localizedValues[locale.languageCode]?['dark'] ?? 'Sombre';
  String get favorites => _localizedValues[locale.languageCode]?['favorites'] ?? 'Favoris';
  String get noFavorites => _localizedValues[locale.languageCode]?['no_favorites'] ?? 'Aucun épisode en favoris';
  String get removeFavorite => _localizedValues[locale.languageCode]?['remove_favorite'] ?? 'Retirer des favoris';
  String get addFavorite => _localizedValues[locale.languageCode]?['add_favorite'] ?? 'Ajouter aux favoris';
  String get favoriteError => _localizedValues[locale.languageCode]?['favorite_error'] ?? 'Erreur lors de la gestion des favoris';
  String get retry => _localizedValues[locale.languageCode]?['retry'] ?? 'Réessayer';
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
} 