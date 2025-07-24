import 'package:flutter/material.dart';
import '../services/movie_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import '../services/episode_service.dart';
import 'episode_player_screen.dart';
import '../providers/favorites_provider.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/likes_provider.dart';
import '../../services/auth_service.dart';
import '../../services/like_service.dart';
import '../providers/favorites_episodes_provider.dart';
import '../services/favorite_episode_service.dart';
import '../l10n/app_localizations.dart';
import '../config/environment.dart';

class MovieDetails extends StatefulWidget {
  final String movieId;
  final bool isDirector;

  const MovieDetails({
    Key? key,
    required this.movieId,
    this.isDirector = false,
  }) : super(key: key);

  @override
  _MovieDetailsState createState() => _MovieDetailsState();
}

class _MovieDetailsState extends State<MovieDetails> {
  final MovieService _movieService = MovieService();
  final EpisodeService _episodeService = EpisodeService();
  Map<String, dynamic>? _movie;
  List<Map<String, dynamic>> _episodes = [];
  bool _isLoading = true;
  String? _error;
  Map<String, VideoPlayerController> _videoControllers = {};
  Map<String, Future<void>> _initializeVideoFutures = {};
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadMovie();
  }

  Future<void> _loadMovie() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final movie = await _movieService.getMovie(widget.movieId);
      await _loadEpisodes();
      
      setState(() {
        _movie = movie;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEpisodes() async {
    try {
      // Utiliser le service d'épisodes pour récupérer la liste
      final episodes = await _episodeService.getEpisodesForMovie(widget.movieId);
      print('Épisodes récupérés: $episodes');
      
      // Pour chaque épisode, charger sa vidéo
      for (var episode in episodes) {
        final uploadsResponse = await http.get(Uri.parse('${Environment.apiBaseUrl}/uploads/episodes/${episode['episode_id']}/uploads'));
        if (uploadsResponse.statusCode == 200) {
          final uploads = List<Map<String, dynamic>>.from(jsonDecode(uploadsResponse.body));
          final videoUpload = uploads.firstWhere(
            (u) => u['type'] == 'video' && u['status'] == 'completed' && u['path'] != null,
            orElse: () => {},
          );
          if (videoUpload.isNotEmpty) {
            episode['video_url'] = videoUpload['path'];
            print('Vidéo trouvée pour épisode ${episode['episode_id']}: ${videoUpload['path']}');
          } else {
            print('Aucune vidéo trouvée pour épisode ${episode['episode_id']}');
          }
        } else {
          print('Erreur lors de la récupération des uploads pour épisode ${episode['episode_id']}');
        }
      }
      
      // Initialiser les contrôleurs vidéo pour chaque épisode avec vidéo
      for (var episode in episodes) {
        if (episode['video_url'] != null) {
          final videoUrl = episode['video_url'];
          final controller = VideoPlayerController.network(videoUrl);
          controller.addListener(() {
            print('État vidéo épisode ${episode['episode_id']} : isPlaying=${controller.value.isPlaying}, position=${controller.value.position}');
          });
          _videoControllers[episode['episode_id'].toString()] = controller;
          _initializeVideoFutures[episode['episode_id'].toString()] = controller.initialize().then((_) {
            print('Contrôleur vidéo initialisé pour l\'épisode ${episode['episode_id']}. Durée : ${controller.value.duration}');
          }).catchError((e) {
            print('Erreur lors de l\'initialisation du contrôleur vidéo pour l\'épisode ${episode['episode_id']} : $e');
          });
        }
      }
      
      setState(() {
        _episodes = episodes;
      });
    } catch (e) {
      print('Erreur lors du chargement des épisodes: $e');
    }
  }

  @override
  void dispose() {
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildVideoPlayer(String episodeId) {
    final controller = _videoControllers[episodeId];
    final initializeFuture = _initializeVideoFutures[episodeId];

    if (controller == null || initializeFuture == null || controller.dataSource.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: FutureBuilder(
          future: initializeFuture,
          builder: (context, snapshot) {
            print('FutureBuilder snapshot: ${snapshot.connectionState}, error: ${snapshot.error}');
            if (snapshot.connectionState == ConnectionState.done) {
              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(controller),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: Colors.blue,
                      bufferedColor: Colors.blue.withOpacity(0.5),
                      backgroundColor: Colors.grey[600]!,
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Row(
                      children: [
                        FloatingActionButton(
                          mini: true,
                          backgroundColor: Colors.black54,
                          onPressed: () {
                            setState(() {
                              if (controller.value.isPlaying) {
                                print('Pause vidéo épisode $episodeId');
                                controller.pause();
                              } else {
                                print('Lecture vidéo épisode $episodeId');
                                controller.play();
                              }
                            });
                          },
                          child: Icon(
                            controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FloatingActionButton(
                          mini: true,
                          backgroundColor: Colors.black54,
                          onPressed: () {
                            setState(() {
                              if (controller.value.volume > 0) {
                                controller.setVolume(0);
                              } else {
                                controller.setVolume(1);
                              }
                            });
                          },
                          child: Icon(
                            controller.value.volume > 0 ? Icons.volume_up : Icons.volume_off,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              return Text('Erreur vidéo : ${snapshot.error}', style: TextStyle(color: Colors.red));
            } else {
              return Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(String episodeId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;
      if (userId == null) return;

      final favoriteService = FavoriteEpisodeService();
      if (_isFavorite) {
        await favoriteService.removeFromFavorites(userId, episodeId);
      } else {
        await favoriteService.addToFavorites(userId, widget.movieId, episodeId);
      }
      setState(() {
        _isFavorite = !_isFavorite;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).favoriteError)),
      );
    }
  }



  Future<void> _unlockEpisode(String episodeId) async {
    try {
      final result = await _episodeService.unlockEpisode(episodeId);
      
      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Épisode débloqué ! Coins dépensés: ${result['coinsSpent']}'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Forcer un rafraîchissement de l'interface
      setState(() {
        // Cela va déclencher un rebuild et recharger les accès aux épisodes
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUnlockDialog(String episodeId, Map<String, dynamic> episode) async {
    // Vérifier l'accès à l'épisode pour obtenir les informations de solde
    try {
      final accessInfo = await _episodeService.checkEpisodeAccess(episodeId);
      final requiredCoins = accessInfo['requiredCoins'] ?? 1;
      final userBalance = accessInfo['userBalance'] ?? 0;

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              'Débloquer l\'épisode',
              style: const TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voulez-vous débloquer l\'épisode ${episode['episode_number']} ?',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Coût: $requiredCoins coin(s)',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Votre solde: $userBalance coin(s)',
                  style: const TextStyle(color: Colors.white),
                ),
                if (userBalance < requiredCoins) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Solde insuffisant !',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler', style: TextStyle(color: Colors.orange)),
              ),
              if (userBalance >= requiredCoins)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _unlockEpisode(episodeId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Débloquer'),
                ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la vérification: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getValidImageUrl(String url) {
    if (url.isEmpty) {
      return 'https://via.placeholder.com/300x400?text=No+Image';
    }
    if (url.startsWith('http')) {
      return url;
    }
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      return 'https://via.placeholder.com/300x400?text=No+Image';
    }
    final baseUrl = Environment.apiBaseUrl.replaceAll('/api','');
    if (!cleanUrl.startsWith('/uploads/')) {
      final cleanPath = cleanUrl.replaceAll('/uploads/', '');
      return '$baseUrl/uploads/$cleanPath';
    }
    return '$baseUrl$cleanUrl';
  }

  String _getThumbnailUrl(String? thumbnailUrl) {
    if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
      return '';
    }
    
    // Si c'est une URL CloudFront, utiliser le proxy backend
    if (thumbnailUrl.contains('cloudfront.net')) {
      // Extraire l'ID de l'épisode de l'URL
      final episodeId = _extractEpisodeIdFromThumbnailUrl(thumbnailUrl);
      if (episodeId != null) {
        return '${Environment.apiBaseUrl}/episodes/$episodeId/thumbnail';
      }
    }
    
    return thumbnailUrl;
  }

  String? _extractEpisodeIdFromThumbnailUrl(String url) {
    // Exemple: https://dm23yf4cycj8r.cloudfront.net/thumbnails/2/ab50ed3c-6a0e-4707-bffe-b6d64e7c96e1.jpg
    // Extraire le numéro après /thumbnails/
    final regex = RegExp(r'/thumbnails/(\d+)/');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  Future<bool> _testImageUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Widget _buildFallbackWidget(int episodeNumber) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              color: Colors.grey[400],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              '$episodeNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Erreur: $_error',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMovie,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_movie == null) {
      return const Center(
        child: Text(
          'Film non trouvé',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    String imageUrl = (_movie!['cover_image'] != null && _movie!['cover_image'].toString().isNotEmpty)
        ? _movie!['cover_image']
        : (_movie!['poster_url'] ?? '');
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = '${Environment.apiBaseUrl}$imageUrl';
    }
    print('URL cover utilisée: $imageUrl');

    // Détection présence saison et nombre d'épisodes
    final bool hasSeason = _movie != null &&
        _movie!['data']?['season'] != null &&
        (_movie!['data']?['season'].toString() ?? '').isNotEmpty;
    final bool hasEpisodesCount = _movie != null &&
        _movie!['data']?['episodes_count'] != null;

    return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          if (imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'URL cover: $imageUrl',
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
              if (imageUrl.isNotEmpty)
                Container(
              width: double.infinity,
              height: 220,
                  decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    ),
              child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        child: Image.network(
                          imageUrl,
                  fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.error, size: 50),
                            );
                          },
                        ),
                      ),
            ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  tooltip: 'Retour',
                ),
                const SizedBox(width: 8),
                Text(
                  'Épisodes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Ajout : Affichage saison, nombre d'épisodes et nombre de vues (œil)
          if (hasSeason || hasEpisodesCount)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (hasSeason)
                    Text(
                      'Saison : ${_movie!['data']?['season']}',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  if (hasSeason) const SizedBox(width: 24),
                  if (hasEpisodesCount)
                    Text(
                      'Nombre d\'épisodes : ${_episodes.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          if (_episodes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Center(
                child: Text(
                  'Aucun épisode disponible',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grille des épisodes
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _episodes.length,
                    itemBuilder: (context, index) {
                      final episode = _episodes[index];
                      final isFree = episode['is_free'] ?? false;
                      final episodeNumber = episode['episode_number'] ?? (index + 1);
                      final isSelected = index == 0; // Premier épisode sélectionné par défaut
                      
                      // Debug: Vérifier les données de l'épisode
                      print('[DEBUG] MovieDetails - Episode $episodeNumber - thumbnail_url: ${episode['thumbnail_url']}');
                      
                      // Vérifier l'accès à l'épisode en temps réel
                      return FutureBuilder<Map<String, dynamic>>(
                        future: _episodeService.checkEpisodeAccess(episode['episode_id'].toString()),
                        builder: (context, snapshot) {
                          final hasAccess = snapshot.hasData && snapshot.data!['hasAccess'] == true;
                          final isUnlocked = isFree || hasAccess;
                      
                                              return GestureDetector(
                          onTap: () async {
                            final authService = Provider.of<AuthService>(context, listen: false);
                            final userId = authService.currentUser?.id;
                            final episodeId = (episode['id'] ?? episode['episode_id']).toString();
                            final movieId = widget.movieId;
                            
                            if (isUnlocked) {
                              // Épisode débloqué ou gratuit - ouvrir directement
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EpisodePlayerScreen(
                                    episodeId: int.parse(episodeId),
                                    videoUrl: episode['video_url'],
                                    title: episode['title'],
                                    description: episode['description'],
                                    movieId: widget.movieId,
                                    seasonNumber: episode['season_number'],
                                    episodeNumber: episode['episode_number'],
                                    tikTokEpisodeId: int.parse(episodeId),
                                  ),
                                ),
                              );
                            } else {
                              // Épisode payant et non débloqué - afficher dialogue de déblocage
                              _showUnlockDialog(episodeId, episode);
                            }
                          },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.grey[600] : Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected ? Border.all(color: Colors.orange, width: 2) : null,
                          ),
                          child: Stack(
                            children: [
                              // Miniature de l'épisode (si disponible)
                              if (episode['thumbnail_url'] != null && episode['thumbnail_url'].toString().isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: FutureBuilder<bool>(
                                    future: _testImageUrl(_getThumbnailUrl(episode['thumbnail_url'])),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData && snapshot.data == true) {
                                        return Image.network(
                                          _getThumbnailUrl(episode['thumbnail_url']),
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return _buildFallbackWidget(episodeNumber);
                                          },
                                        );
                                      } else {
                                        return _buildFallbackWidget(episodeNumber);
                                      }
                                    },
                                  ),
                                )
                              else
                                _buildFallbackWidget(episodeNumber),
                              // Icône de lecture pour l'épisode sélectionné
                              if (isSelected)
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Icon(
                                    Icons.play_arrow,
                                    color: Colors.orange,
                                    size: 16,
                                  ),
                                ),
                              // Icône de cadenas pour les épisodes non débloqués
                              if (!isUnlocked)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Icon(
                                    Icons.lock,
                                    color: Colors.orange,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
        ],
        ),
    );
  }
} 