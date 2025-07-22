# Structure du frontend SCROLLEO

Ce document explique le rôle de chaque dossier et fichier du frontend Flutter, et signale les fichiers potentiellement inutiles ou redondants.

---

## Fichier principal

- **main.dart** : Point d'entrée de l'application. Initialise les providers, le thème, la localisation, et configure les routes principales.

---

## Dossiers principaux

### models/
Modèles de données utilisés dans l'application.
- **user.dart** : Modèle utilisateur.
- **director.dart** : Modèle pour un réalisateur.
- **episode.dart** : Modèle pour un épisode.
- **movie.dart** : Modèle pour un film.
- **reel.dart** : Modèle pour un "reel" (vidéo courte).

### screens/
Tous les écrans/pages de l'application, organisés par fonctionnalité.
- **main/** : Contient le MainScreen (barre de navigation principale).
- **home/**, **favorites/**, **profile/**, **reels/**, **movie_details/**, etc. : Pages ou sections de l'application.
- **admin/**, **director/** : Pages réservées à l'admin ou au réalisateur.
- **splash/** : Écran de chargement initial.
- **settings/**, **signup/**, **login/**, **subscription/**, **delete_account/**, **explore/**, **search/**, **welcome/**, **history/** : Pages spécifiques.

### services/
Logique métier et appels API.
- **auth_service.dart** : Authentification.
- **episode_service.dart** : Gestion des épisodes.
- **movie_service.dart** : Gestion des films.
- **user_service.dart** : Gestion des utilisateurs.
- **favorites_service.dart**, **favorite_episode_service.dart** : Gestion des favoris.
- **like_service.dart** : Gestion des likes.
- **history_service.dart** : Historique de visionnage.
- **reels_service.dart** : Gestion des reels.
- **settings_service.dart** : Paramètres utilisateur.
- **locale_service.dart** : Gestion de la langue.
- **storage_service.dart** : Stockage local.
- **subscription_service.dart** : Abonnements.
- **wallet_service.dart** : Portefeuille virtuel.
- **view_service.dart** : Gestion des vues.
- **movie_api_service.dart** : Appels API pour les films.
- **director_service.dart** : Gestion des réalisateurs.

### widgets/
Composants réutilisables de l'UI.
- **movie_details.dart**, **episode_details.dart**, **episode_list.dart**, **movie_card.dart**, **movie_section.dart**, **featured_movie_card.dart** : Composants pour afficher les films/épisodes.
- **reel_player.dart**, **tiktok_style_player.dart**, **movie_player.dart**, **video_player.dart** : Players vidéo.
- **bottom_nav_bar.dart** : Barre de navigation du bas (peut être redondant avec MainScreen).
- **category_tabs.dart**, **custom_app_bar.dart**, **search_bar.dart**, **section_header.dart** : Composants d'interface.
- **coin_packs_screen.dart** : Affichage des packs de pièces.
- **feexpay_launcher_stub.dart**, **feexpay_launcher_web.dart**, **feexpay_webview_mobile.dart**, **feexpay_webview_stub.dart** : Paiement/abonnement (stubs pour différentes plateformes).
- **episodes_grid.dart** : Grille d'épisodes.

### theme/
- **app_theme.dart** : Définition des couleurs, polices, thèmes de l'application.

### utils/
- **app_date_utils.dart** : Fonctions utilitaires pour la gestion des dates.

### l10n/
- **app_localizations.dart** : Gestion de la traduction/localisation.

### providers/
Gestion d'état avec Provider.
- **favorites_provider.dart**, **favorites_episodes_provider.dart** : Favoris.
- **likes_provider.dart** : Likes.
- **history_provider.dart** : Historique.

### routes/
- **app_router.dart**, **app_routes.dart** : Gestion centralisée des routes (peut être redondant si la navigation est gérée dans main.dart).

---

## Fichiers potentiellement inutiles ou redondants

- **widgets/bottom_nav_bar.dart** : Si la barre de navigation est gérée dans MainScreen, ce fichier est inutile.
- **widgets/feexpay_launcher_stub.dart**, **feexpay_webview_stub.dart** : Stubs, utiles seulement pour certaines plateformes. Si tu ne fais pas de build multi-plateforme, tu peux les ignorer.
- **routes/app_router.dart**, **routes/app_routes.dart** : Si toute la navigation est gérée dans main.dart, ces fichiers ne servent à rien.
- **widgets/coin_packs_screen.dart** : Si tu n'as pas de système de pièces ou de boutique, ce fichier est inutile.
- **explore/**, **welcome/**, **delete_account/** : Si ces fonctionnalités ne sont pas utilisées dans l'app, tu peux supprimer les dossiers/fichiers correspondants.

---

## Conseils
- Garde ta structure claire : un dossier par type (modèle, service, écran, widget, etc.).
- Supprime les fichiers/dossiers non utilisés pour alléger le projet.
- Documente les composants complexes directement dans leur fichier si besoin. 