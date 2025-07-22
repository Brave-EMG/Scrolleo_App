import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import '../../services/episode_service.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/view_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final bool isEpisode;
  final String contentId;
  final String movieId;

  const VideoPlayerScreen({
    Key? key,
    required this.videoUrl,
    required this.isEpisode,
    required this.contentId,
    required this.movieId,
  }) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isFullScreen = false;
  bool _isControlsVisible = true;
  Timer? _hideTimer;
  bool _isViewRecorded = false;
  final EpisodeService _episodeService = EpisodeService();
  int _views = 0;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    if (widget.isEpisode) {
      _loadViews();
    }
  }

  Future<void> _loadViews() async {
    try {
      print('[DEBUG] Chargement des vues pour episodeId: ' + widget.contentId);
      final views = await _episodeService.getEpisodeViews(widget.contentId);
      //print('[DEBUG] Nombre de vues récupéré: $views');
      setState(() {
        _views = views;
      });
    } catch (e) {
      print('[DEBUG] Erreur lors du chargement des vues: $e');
    }
  }

  Future<void> _initializePlayer() async {
    _controller = VideoPlayerController.network(widget.videoUrl);
    try {
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });
      _controller.play();
      _startHideTimer();
      
      // Enregistrer la vue une fois que la vidéo commence à jouer
      if (!_isViewRecorded && widget.isEpisode) {
        await _recordView();
      }
    } catch (e) {
      print('Error initializing video player: $e');
    }
  }

  Future<void> _recordView() async {
    if (!_isViewRecorded && widget.isEpisode) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final userId = authService.currentUser?.id;
        final token = await authService.getToken();
        if (userId != null && token != null) {
          print('[DEBUG] Tentative d\'enregistrement de la vue pour episodeId: ' + widget.contentId);
          final success = await _episodeService.recordEpisodeView(
            widget.contentId,
            widget.movieId,
            userId,
            token,
          );
          print('[DEBUG] Résultat de l\'enregistrement de la vue: $success');
          if (success) {
            if (mounted) {
              setState(() {
                _isViewRecorded = true;
                _views++; // Incrémenter le compteur local
              });
            }
            // Ajout : Enregistrement de la vue d'épisode et tentative de vue film
            try {
              await ViewService.addEpisodeView(
                userId: int.parse(userId.toString()),
                episodeId: int.parse(widget.contentId),
                movieId: int.parse(widget.movieId),
              );
              await ViewService.addMovieView(
                userId: int.parse(userId.toString()),
                movieId: int.parse(widget.movieId),
              );
              print('[DEBUG] Appel à addEpisodeView et addMovieView effectué');
            } catch (e) {
              print('[DEBUG] Erreur lors de l\'appel à addEpisodeView/addMovieView : $e');
            }
          }
        } else {
          print('[DEBUG] Utilisateur non connecté ou token manquant, vue non enregistrée');
        }
      } catch (e) {
        print('[DEBUG] Erreur lors de l\'enregistrement de la vue: $e');
      }
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isControlsVisible = false;
      });
    }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
                children: [
          // Video Player
          Center(
            child: _isInitialized
                ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                  )
                : CircularProgressIndicator(),
          ),
          
          // Controls Overlay
          if (_isControlsVisible)
            GestureDetector(
      onTap: () {
        setState(() {
                  _isControlsVisible = !_isControlsVisible;
        });
                if (_isControlsVisible) {
                  _startHideTimer();
                }
      },
              child: Container(
                color: Colors.black.withOpacity(0.3),
        child: Stack(
          children: [
                    // Play/Pause Button
            Center(
              child: IconButton(
                icon: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 50,
                  color: Colors.white,
                ),
                onPressed: () {
                          setState(() {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          });
                },
              ),
            ),
                    
                    // Views Counter (only for episodes)
                    if (widget.isEpisode)
            Positioned(
                        top: 40,
                        right: 20,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                    child: Row(
                            mainAxisSize: MainAxisSize.min,
                      children: [
                              Icon(
                                Icons.visibility,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                        Text(
                                '$_views',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                        ),
                      ],
                          ),
                    ),
                  ),
                ],
                ),
              ),
            ),
          ],
      ),
    );
  }
} 