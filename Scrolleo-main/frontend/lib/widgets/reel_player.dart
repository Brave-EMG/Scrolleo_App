import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/episode.dart' as ep;
import '../services/reels_service.dart';
import '../services/favorite_episode_service.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../services/history_service.dart';
import '../providers/history_provider.dart';
import '../services/episode_service.dart';
import '../services/movie_service.dart';

class ReelPlayer extends StatefulWidget {
  final ep.Episode episode;
  final bool isActive;
  final VoidCallback onShare;
  final String movieId;
  final String movieTitle;

  const ReelPlayer({
    Key? key,
    required this.episode,
    required this.isActive,
    required this.onShare,
    required this.movieId,
    required this.movieTitle,
  }) : super(key: key);

  @override
  _ReelPlayerState createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isLiked = false;
  final ReelsService _reelsService = ReelsService();
  bool _isFavorite = false;
  bool _loadingFavorite = false;
  late FavoriteEpisodeService _favoriteService;
  String? _userId;
  String? _videoError;
  int _views = 0;
  bool _hasRecordedView = false;
  final EpisodeService _episodeService = EpisodeService();

  @override
  void initState() {
    super.initState();
    _favoriteService = FavoriteEpisodeService();
    _sendToHistory();
    _loadViews();
    _checkFavoriteStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeVideo();
    _checkLikeStatus();
    _initFavoriteState();
  }

  Future<void> _checkLikeStatus() async {
    final isLiked = await _reelsService.isReelLiked(widget.episode.id.toString());
    if (!mounted) return;
    setState(() {
      _isLiked = isLiked;
    });
  }

  Future<void> _initializeVideo() async {
    // Utiliser l'URL CloudFront si disponible, sinon utiliser l'URL locale
    final videoUrl = widget.episode.videoUrl.startsWith('http://localhost:3000')
        ? widget.episode.videoUrl.replaceFirst('http://localhost:3000', 'https://d2h8q0ttenj5cb.cloudfront.net')
        : widget.episode.videoUrl;
    
    //print('URL vidéo Pour vous : $videoUrl');
    _controller = VideoPlayerController.network(videoUrl);
    
    try {
      await _controller.initialize();
      _controller.setLooping(true);
      if (widget.isActive) {
        _controller.play();
      }
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _videoError = null;
      });
    } catch (e) {
      print('Erreur lors de l\'initialisation de la vidéo: $e');
      if (!mounted) return;
      setState(() {
        _videoError = e.toString();
      });
    }
  }

  Future<void> _initFavoriteState() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    _userId = authService.currentUser?.id;
    if (_userId == null) return;
    final favorites = await _favoriteService.getFavorites(_userId!);
    if (!mounted) return;
    setState(() {
      _isFavorite = favorites.any((fav) => fav['episode_id'].toString() == widget.episode.id.toString());
    });
  }

  Future<void> _checkFavoriteStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;
    if (userId != null) {
      if (!mounted) return;
      setState(() {
        _userId = userId;
      });
      final favorites = await _favoriteService.getFavorites(userId);
      if (!mounted) return;
      setState(() {
        _isFavorite = favorites.any((fav) => fav['episode_id'].toString() == widget.episode.id.toString());
      });
    }
  }

  Future<void> _toggleFavorite() async {
    print('[DEBUG] _toggleFavorite appelé, userId= _userId, episodeId=${widget.episode.id}');
    if (_userId == null) return;

    if (!mounted) return;
    setState(() {
      _loadingFavorite = true;
    });

    try {
      if (_isFavorite) {
        final success = await _favoriteService.removeFromFavorites(_userId!, widget.episode.id.toString());
        print('[DEBUG] removeFromFavorites success=$success');
        if (success) {
          await _checkFavoriteStatus();
        }
      } else {
        final success = await _favoriteService.addToFavorites(
          _userId!,
          widget.movieId,
          widget.episode.id.toString(),
        );
        print('[DEBUG] addToFavorites success=$success');
        if (success) {
          await _checkFavoriteStatus();
        }
      }
    } catch (e) {
      print('Erreur lors de la gestion des favoris: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingFavorite = false;
      });
    }
  }

  Future<void> _sendToHistory() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;
      if (userId != null) {
        await HistoryService.updateWatchHistory(
          userId: userId,
          movieId: widget.movieId.toString(),
          episodeId: widget.episode.id.toString(),
          lastPosition: 0,
        );
        // Notifier le provider d'historique
        Provider.of<HistoryProvider>(context, listen: false).notifyHistoryChanged();
        print('[History] Ajouté à l\'historique : user=$userId, movie=${widget.movieId}, episode=${widget.episode.id}');
      }
    } catch (e) {
      print('[History] Erreur lors de l\'ajout à l\'historique : $e');
    }
  }

  @override
  void didUpdateWidget(ReelPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('[DEBUG] didUpdateWidget: isActive=${widget.isActive}, _hasRecordedView=$_hasRecordedView');
    if (widget.isActive && !_hasRecordedView) {
      print('[DEBUG] ReelPlayer devient actif pour episodeId: ' + widget.episode.id.toString());
      _recordView();
    }
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.play();
      } else {
        _controller.pause();
      }
    }
  }

  Future<void> _loadViews() async {
    try {
      print('[DEBUG] Chargement des vues pour episodeId: ' + widget.episode.id.toString());
      final views = await _episodeService.getEpisodeViews(widget.episode.id.toString());
      //print('[DEBUG] Nombre de vues récupéré: $views');
      if (!mounted) return;
      setState(() {
        _views = views;
      });
    } catch (e) {
      print('[DEBUG] Erreur lors du chargement des vues: $e');
    }
  }

  Future<void> _recordView() async {
    print('[DEBUG] _recordView() appelé');
    if (_hasRecordedView) return;
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;
      final token = await authService.getToken();
      if (userId == null || token == null) {
        print('[DEBUG] Impossible d\'enregistrer la vue : utilisateur non connecté ou token manquant');
        return;
      }
      print('[DEBUG] Tentative d\'enregistrement de la vue pour episodeId: ' + widget.episode.id.toString());
      final success = await _episodeService.recordEpisodeView(
        widget.episode.id.toString(),
        widget.movieId,
        userId,
        token,
      );
      print('[DEBUG] Résultat de l\'enregistrement de la vue: $success');
      if (success) {
        if (!mounted) return;
        setState(() {
          _hasRecordedView = true;
        });
        await _loadViews(); // Rafraîchir le compteur après enregistrement
      }
    } catch (e) {
      print('[DEBUG] Erreur lors de l\'enregistrement de la vue: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    //print('[ReelPlayer] URL vidéo utilisée : ' + widget.episode.videoUrl.toString());
    //print('[ReelPlayer] Format de l\'URL : ' + widget.episode.videoUrl.runtimeType.toString());
    //print('[ReelPlayer] Longueur de l\'URL : ' + widget.episode.videoUrl.length.toString());

    return Stack(
      children: [
        // Vidéo en fond
        Positioned.fill(
          child: EpisodePlayerSimple(
            videoUrl: widget.episode.videoUrl,
            title: widget.episode.title,
            onError: (error) {
              print('[ReelPlayer] Erreur de lecture vidéo : $error');
              print('[ReelPlayer] URL qui a causé l\'erreur : ' + widget.episode.videoUrl);
            },
          ),
        ),
        // Overlay dégradé pour lisibilité
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black54,
                  Colors.transparent,
                  Colors.black87,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        // Infos et actions en bas
        Positioned(
          left: 20,
          right: 100,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.episode.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 12, color: Colors.black87)],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.episode.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Boutons d'action verticaux à droite
        Positioned(
          right: 20,
          bottom: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionIconButton(
                icon: _isFavorite ? Icons.star : Icons.star_border,
                label: 'Favoris',
                color: _isFavorite ? Colors.yellow : Colors.white,
                onTap: _loadingFavorite ? null : _toggleFavorite,
                isActive: _isFavorite,
              ),
              const SizedBox(height: 12),
              _ActionIconButton(
                icon: Icons.share,
                label: 'Partager',
                color: Colors.white,
                onTap: () async {
                  try {
                    await MovieService().shareMovie(widget.movieId, episodeId: widget.episode.id.toString());
                  } catch (e) {
                    print('[ERROR] Erreur lors du partage: $e');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors du partage: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                isActive: false,
              ),
              const SizedBox(height: 12),
              // Statistiques (vues et commentaires uniquement)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.visibility,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_views',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.comment,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.episode.comments ?? 0}',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class EpisodePlayerSimple extends StatefulWidget {
  final String videoUrl;
  final String title;
  final Function(String) onError;
  const EpisodePlayerSimple({Key? key, required this.videoUrl, required this.title, required this.onError}) : super(key: key);

  @override
  State<EpisodePlayerSimple> createState() => _EpisodePlayerSimpleState();
}

class _EpisodePlayerSimpleState extends State<EpisodePlayerSimple> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  String? _error;

  String _cleanVideoUrl(String url) {
    // Remplacer les espaces et les tirets par des caractères URL-safe
    String cleanedUrl = url.replaceAll(' ', '%20').replaceAll('-', '%2D');
    
    // Si c'est une URL S3, utiliser CloudFront si disponible
    if (cleanedUrl.contains('myscrolleobucket.s3.amazonaws.com')) {
      cleanedUrl = cleanedUrl.replaceFirst(
        'myscrolleobucket.s3.amazonaws.com',
        'd2h8q0ttenj5cb.cloudfront.net'
      );
    }
    
    print('[EpisodePlayerSimple] URL nettoyée : $cleanedUrl');
    return cleanedUrl;
  }

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      print('[EpisodePlayerSimple] Initialisation avec URL : ${widget.videoUrl}');
      
      // Vérifier si l'URL est valide
      if (widget.videoUrl.isEmpty) {
        throw Exception('URL vidéo vide');
      }

      // Nettoyer l'URL
      final cleanedUrl = _cleanVideoUrl(widget.videoUrl);

      // Créer le contrôleur avec des options spécifiques
      _controller = VideoPlayerController.network(
        cleanedUrl,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        httpHeaders: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
          'Accept': 'video/mp4,video/*;q=0.9,*/*;q=0.8',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
        },
      );

      // Ajouter un listener pour les erreurs
      _controller.addListener(() {
        if (_controller.value.hasError) {
          print('[EpisodePlayerSimple] Erreur du contrôleur : ${_controller.value.errorDescription}');
          widget.onError(_controller.value.errorDescription ?? 'Erreur inconnue');
        }
      });

      await _controller.initialize();
      
      if (!mounted) return;
      
      setState(() {
        _isInitialized = true;
        _error = null;
      });
      
      _controller.play();
      _controller.setLooping(true);
      
    } catch (e) {
      print('[EpisodePlayerSimple] Erreur lors de l\'initialisation : $e');
      if (!mounted) return;
      
      setState(() {
        _error = e.toString();
      });
      widget.onError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Erreur de lecture vidéo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Nouveau widget pour les boutons d'action verticaux
class _ActionIconButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isActive;
  const _ActionIconButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.isActive = false,
    Key? key,
  }) : super(key: key);

  @override
  State<_ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<_ActionIconButton> {
  bool _hovering = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
                  child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: _hovering ? Colors.white12 : Colors.black38,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (widget.isActive)
                  const BoxShadow(
                    color: Colors.yellow,
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                const BoxShadow(
                  color: Colors.black54,
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(widget.icon, color: widget.color, size: 20),
                const SizedBox(height: 2),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
} 