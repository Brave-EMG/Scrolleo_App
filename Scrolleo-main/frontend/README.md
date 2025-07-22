# Structure du Projet Frontend

## Organisation des Dossiers

### `lib/`
Dossier principal contenant tout le code source de l'application Flutter.

#### `lib/models/`
- **movie.dart** : Définit la classe `Movie` qui représente un film avec ses propriétés (titre, description, note, etc.)
- **user.dart** : Définit la classe `User` pour gérer les informations des utilisateurs

#### `lib/providers/`
- **favorites_provider.dart** : Gère l'état des films favoris de l'utilisateur
- **auth_provider.dart** : Gère l'authentification des utilisateurs
- **movie_provider.dart** : Gère la liste des films et leurs données

#### `lib/screens/`
- **home_screen.dart** : Écran principal de l'application
- **movie_details_screen.dart** : Écran de détails d'un film
- **favorites_screen.dart** : Écran des films favoris
- **profile_screen.dart** : Écran du profil utilisateur
- **login_screen.dart** : Écran de connexion
- **register_screen.dart** : Écran d'inscription

#### `lib/widgets/`
- **movie_card.dart** : Widget personnalisé pour afficher une carte de film
- **movie_list.dart** : Widget pour afficher une liste de films
- **custom_app_bar.dart** : Barre de navigation personnalisée
- **custom_bottom_nav_bar.dart** : Barre de navigation inférieure personnalisée

#### `lib/services/`
- **movie_service.dart** : Service pour gérer les opérations liées aux films
- **auth_service.dart** : Service pour gérer l'authentification
- **storage_service.dart** : Service pour gérer le stockage local

#### `lib/utils/`
- **constants.dart** : Constantes globales de l'application
- **helpers.dart** : Fonctions utilitaires

#### `lib/theme/`
- **app_theme.dart** : Définit le thème de l'application (couleurs, styles, etc.)

### `assets/`
Dossier contenant les ressources statiques de l'application.

#### `assets/images/`
- **movies/thumbnails/** : Contient les images des films (posters et backdrops)
- **icons/** : Contient les icônes de l'application
- **logos/** : Contient les logos de l'application

## Fonctionnalités Principales

1. **Affichage des Films**
   - Liste des films sur la page d'accueil
   - Détails d'un film sélectionné
   - Affichage des films favoris

2. **Gestion des Favoris**
   - Ajout/Suppression de films en favoris
   - Persistance des favoris
   - Affichage dans un écran dédié

3. **Authentification**
   - Connexion des utilisateurs
   - Inscription de nouveaux utilisateurs
   - Gestion du profil utilisateur

4. **Interface Utilisateur**
   - Navigation entre les écrans
   - Thème personnalisé
   - Animations et transitions
   - Design responsive

## Architecture

L'application utilise une architecture basée sur :
- **Provider** pour la gestion d'état
- **Services** pour la logique métier
- **Widgets** réutilisables pour l'interface
- **Models** pour la structure des données

## Dépendances Principales

- `provider` : Gestion d'état
- `cached_network_image` : Chargement et mise en cache des images
- `shared_preferences` : Stockage local des données
- `flutter_svg` : Support des images SVG
