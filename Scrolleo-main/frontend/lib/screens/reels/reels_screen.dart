import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/movie.dart';
import '../../services/reels_service.dart';
import '../../widgets/reel_player.dart';
import '../../models/episode.dart' as ep;
import '../../services/episode_service.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../services/favorites_service.dart';
import '../../services/movie_service.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({Key? key}) : super(key: key);

  @override
  _ReelsScreenState createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final ReelsService _reelsService = ReelsService();
  final EpisodeService _episodeService = EpisodeService();
  late final FavoritesService _favoritesService;
  final PageController _pageController = PageController();
  List<ep.Episode> _reels = [];
  List<Movie> _movies = [];
  bool _isLoading = false;
  int _currentIndex = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _favoritesService = Provider.of<FavoritesService>(context, listen: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reels.isEmpty && !_isLoading) {
      _loadReels();
    }
  }

  Future<void> _loadReels() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final movieService = Provider.of<MovieService>(context, listen: false);
      final movies = await movieService.getMovies();
      print('Nombre de films trouvés : ${movies.length}');
      print('IDs des films : ${movies.map((m) => m.id).toList()}');

      final episodes = await _episodeService.getFirstEpisodesForMovies(movies, userId);
      print('Nombre d\'épisodes trouvés : ${episodes.length}');
      for (var ep in episodes) {
        print('Episode chargé : ${ep.title} - ${ep.videoUrl}');
      }

      setState(() {
        _movies = movies;
        _reels = episodes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement des épisodes: $e';
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index >= _reels.length - 2) {
      _loadReels();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Pour vous',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Erreur',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReels,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_reels.isEmpty && !_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Pour vous',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(
          child: Text('Aucun épisode à afficher', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Pour vous',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _reels.length,
            itemBuilder: (context, index) {
              final episode = _reels[index];
              final movie = _movies.firstWhere(
                (m) => m.id == episode.movieId,
                orElse: () => Movie(
                  id: episode.movieId,
                  title: 'Film inconnu',
                  description: '',
                  posterUrl: '',
                  videoUrl: '',
                  director: '',
                  directorId: '',
                  releaseDate: DateTime(2000, 1, 1),
                  duration: const Duration(minutes: 90),
                  rating: 0.0,
                  genres: const [],
                  backdropUrl: '',
                ),
              );
              return ReelPlayer(
                episode: episode,
                isActive: _currentIndex == index,
                onShare: () => _reelsService.shareReel(episode.id.toString()),
                movieId: episode.movieId.toString(),
                movieTitle: movie.title,
              );
            },
          ),
          if (_isLoading)
            const Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
} 