import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../services/episode_service.dart';
import '../services/history_service.dart';
import '../services/view_service.dart';
import '../providers/history_provider.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/reel_player.dart';
import '../models/episode.dart';
import '../services/movie_service.dart';
import '../config/environment.dart';

class TikTokStylePlayer extends StatefulWidget {
  final String movieId;
  final int seasonNumber;
  final int episodeNumber;
  final String? initialVideoUrl;
  final String? title;
  final String? description;
  final int? episodeId;

  const TikTokStylePlayer({
    Key? key,
    required this.movieId,
    required this.seasonNumber,
    required this.episodeNumber,
    this.initialVideoUrl,
    this.title,
    this.description,
    this.episodeId,
  }) : super(key: key);

  @override
  State<TikTokStylePlayer> createState() => _TikTokStylePlayerState();
}

class _TikTokStylePlayerState extends State<TikTokStylePlayer> {
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> _episodes = [];
  bool _isLoading = true;
  String? _error;
  VideoPlayerController? _videoController;
  int _currentIndex = 0;
  final EpisodeService _episodeService = EpisodeService();
  Timer? _viewTimer;
  int _watchDuration = 0;
  bool _hasCountedView = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentEpisode().then((_) {
      if (_episodes.isNotEmpty) {
        final firstEpisode = _episodes[0];
        final episodeId = firstEpisode['episode_id'] ?? firstEpisode['id'];
        print('[DEBUG] initState - Démarrage du timer pour le premier épisode: $episodeId');
        _startViewTimer(episodeId);
      }
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _viewTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _addVideoUrlToEpisode(Map<String, dynamic> episode) async {
    try {
      // Récupérer le token d'authentification
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      // Ajouter le token si disponible
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
    final uploadsResponse = await http.get(
      Uri.parse('${Environment.apiBaseUrl}/uploads/episodes/${episode['episode_id'] ?? episode['id']}/uploads'),
        headers: headers,
    );
      
      print('[DEBUG] _addVideoUrlToEpisode - Status: ${uploadsResponse.statusCode}');
      print('[DEBUG] _addVideoUrlToEpisode - Response: ${uploadsResponse.body}');
      
    if (uploadsResponse.statusCode == 200) {
      final uploads = List<Map<String, dynamic>>.from(jsonDecode(uploadsResponse.body));
      final videoUpload = uploads.firstWhere(
        (u) => u['type'] == 'video' && u['status'] == 'completed' && u['path'] != null,
        orElse: () => {},
      );
      if (videoUpload.isNotEmpty) {
        episode['video_url'] = videoUpload['path'];
          print('[DEBUG] Vidéo trouvée pour épisode ${episode['episode_id']}: ${videoUpload['path']}');
        } else {
          print('[DEBUG] Aucune vidéo trouvée pour épisode ${episode['episode_id']}');
        }
      } else {
        print('[DEBUG] Erreur lors de la récupération des uploads: ${uploadsResponse.statusCode} - ${uploadsResponse.body}');
      }
    } catch (e) {
      print('[DEBUG] Erreur dans _addVideoUrlToEpisode: $e');
    }
  }

  Future<void> _loadCurrentEpisode() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Récupérer tous les épisodes de la saison
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/episodes/movie/${widget.movieId}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final episodes = data is List
            ? List<Map<String, dynamic>>.from(data)
            : List<Map<String, dynamic>>.from(data['episodes'] ?? data['result'] ?? []);
        for (var episode in episodes) {
          await _addVideoUrlToEpisode(episode);
        }
        if (!mounted) return;
        setState(() {
          _episodes = episodes;
          _isLoading = false;
        });
        // Aller directement à l'épisode voulu si episodeId est fourni
        if (widget.episodeId != null) {
          final idx = _episodes.indexWhere((e) => (e['episode_id'] ?? e['id']) == widget.episodeId);
          if (idx != -1) {
            _currentIndex = idx;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _pageController.jumpToPage(idx);
            });
          }
        }
      } else {
        throw Exception('Aucun épisode trouvé');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNextEpisode() async {
    if (_episodes.isEmpty) return;
    final currentEpisode = _episodes.last;
    try {
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/episodes/next/${widget.movieId}/${currentEpisode['season_number']}/${currentEpisode['episode_number']}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['episode'] != null) {
          await _addVideoUrlToEpisode(data['episode']);
          if (!mounted) return;
          setState(() {
            _episodes.add(data['episode']);
          });
        }
      } else if (response.statusCode == 404) {
        print('Aucun épisode suivant disponible');
      } else {
        print('Erreur lors du chargement de l\'épisode suivant: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading next episode: $e');
    }
  }

  Future<void> _initializeVideoController(int index) async {
    if (index >= _episodes.length) return;
    final episode = _episodes[index];
    final videoUrl = episode['video_url'];
    if (videoUrl == null) return;
    try {
      final controller = VideoPlayerController.network(videoUrl);
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(0);
      controller.play();
      if (!mounted) return;
      setState(() {
        _videoController = controller;
      });
    } catch (e) {
      print('Erreur lors de l\'initialisation de la vidéo: $e');
    }
  }

  void _startViewTimer(int episodeId) {
    print('[DEBUG] _startViewTimer appelé pour episodeId=$episodeId');
    _viewTimer?.cancel();
    _watchDuration = 0;
    _hasCountedView = false;
    _viewTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _watchDuration++;
      if (_watchDuration >= 2 && !_hasCountedView) {
        _hasCountedView = true;
        _sendView(episodeId);
      }
    });
  }

  void _sendView(int episodeId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.checkAuthStatus();
    final userId = authService.currentUser?.id;
    final isAuthenticated = authService.isAuthenticated;
    final token = await authService.getToken();
    
    print('[DEBUG] _sendView appelé pour episodeId=$episodeId, userId=$userId, movieId=${widget.movieId}');
    print('[DEBUG] Token présent: ${token != null}, isAuthenticated: $isAuthenticated');
    
    if (userId != null && isAuthenticated && token != null) {
      print('[DEBUG] recordEpisodeView params: userId=$userId, episodeId=$episodeId, movieId=${widget.movieId}');
      try {
        print('[DEBUG] Tentative d\'envoi de la vue au backend...');
        final success = await EpisodeService().recordEpisodeView(
          episodeId.toString(),
          widget.movieId.toString(),
          userId,
          token,
        );
        if (success) {
          print('[DEBUG] Vue enregistrée avec succès');
          // Enregistrer aussi la vue du film
          try {
            await ViewService.addMovieView(
              movieId: int.parse(widget.movieId),
              userId: int.parse(userId),
            );
            print('[DEBUG] Vue du film enregistrée avec succès');
            // Rafraîchir le nombre de vues du film
            Provider.of<HistoryProvider>(context, listen: false).notifyHistoryChanged();
          } catch (e) {
            print('[ERROR] Erreur lors de l\'enregistrement de la vue du film: $e');
          }
          // Mettre à jour uniquement le nombre de vues de l'épisode actuel
          if (!mounted) return;
          setState(() {
            if (_currentIndex < _episodes.length) {
              _episodes[_currentIndex]['views'] = (_episodes[_currentIndex]['views'] ?? 0) + 1;
            }
          });
        } else {
          print('[ERROR] Échec de l\'enregistrement de la vue');
        }
      } catch (e) {
        print('[ERROR] Erreur lors de l\'enregistrement de la vue: $e');
      }
    } else {
      print('[DEBUG] Impossible d\'envoyer la vue: token=${token != null}, userId=$userId, isAuthenticated=$isAuthenticated');
    }
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
            Text('Erreur: $_error'),
            ElevatedButton(
              onPressed: _loadCurrentEpisode,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              final episode = _episodes[index];
              final episodeId = episode['episode_id'] ?? episode['id'];
              print('[DEBUG] onPageChanged appelé pour index=$index, episodeId=$episodeId');
              _startViewTimer(episodeId);
              if (index >= _episodes.length - 1) {
                _loadNextEpisode();
              }
            },
            itemCount: _episodes.length,
            itemBuilder: (context, index) {
              final episode = _episodes[index];
              final episodeId = episode['episode_id'] ?? episode['id'];
              print('[DEBUG] TikTokStylePlayer affiche episodeId=$episodeId');
              
              // Vérifier l'accès à l'épisode
              return FutureBuilder<Map<String, dynamic>>(
                future: _episodeService.checkEpisodeAccess(episodeId.toString()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erreur lors de la vérification d\'accès',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    );
                  }
                  
                  final hasAccess = snapshot.hasData && snapshot.data!['hasAccess'] == true;
                  final isFree = episode['is_free'] == true;
                  final isUnlocked = isFree || hasAccess;
                  
                  // Si l'épisode n'est pas débloqué, afficher l'écran de paiement
                  if (!isUnlocked) {
                    return _buildPaymentScreen(episode, snapshot.data!);
                  }
                  
                  // Si pas de vidéo disponible
                  if (episode['video_url'] == null || episode['video_url'].toString().isEmpty) {
                    return Center(
                      child: Text(
                        'Aucune vidéo disponible pour cet épisode.',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    );
                  }
                  
                  // Épisode débloqué avec vidéo
                  return ReelPlayer(
                    episode: Episode.fromJson(episode),
                    isActive: true,
                    onShare: () async {
                      final movieService = MovieService();
                      await movieService.shareMovie(
                        episode['movie_id'].toString(),
                        episodeId: episode['episode_id']?.toString() ?? episode['id']?.toString(),
                      );
                    },
                    movieId: episode['movie_id'].toString(),
                    movieTitle: episode['movie_title'] ?? episode['title'] ?? '',
                  );
                },
              );
            },
          ),
          // Flèche de retour
          Positioned(
            top: 32,
            left: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Retour',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentScreen(Map<String, dynamic> episode, Map<String, dynamic> accessData) {
    final episodeId = episode['episode_id'] ?? episode['id'];
    final userBalance = accessData['userBalance'] ?? 0;
    final requiredCoins = accessData['requiredCoins'] ?? 1;
    final canUnlock = accessData['canUnlock'] ?? false;
    
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône de cadenas
            Icon(
              Icons.lock,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            
            // Titre
            Text(
              'Épisode ${episode['episode_number']}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            
            // Description
            Text(
              'Cet épisode nécessite ${requiredCoins} coin(s)',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            
            // Solde utilisateur
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monetization_on, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Votre solde: $userBalance coin(s)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Bouton de déblocage
            if (canUnlock)
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _episodeService.unlockEpisode(episodeId.toString());
                    // Recharger l'épisode après déblocage
                    await _loadCurrentEpisode();
                    setState(() {});
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur lors du déblocage: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Débloquer pour ${requiredCoins} coin(s)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )
            else
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red[800],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Solde insuffisant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Bouton pour acheter des coins
            TextButton(
              onPressed: () {
                // Navigation vers l'écran d'achat de coins
                Navigator.pushNamed(context, '/coin-packs');
              },
              child: Text(
                'Acheter des coins',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 