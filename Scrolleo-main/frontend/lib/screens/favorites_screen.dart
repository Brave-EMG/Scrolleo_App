import 'package:flutter/material.dart';
import '../services/favorite_episode_service.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../models/episode.dart';
import '../services/episode_service.dart';
import '../l10n/app_localizations.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoriteEpisodeService _favoriteService = FavoriteEpisodeService();
  final EpisodeService _episodeService = EpisodeService();
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final favorites = await _favoriteService.getFavorites(userId);
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(String episodeId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;
      
      if (userId == null) return;

      final success = await _favoriteService.removeFromFavorites(userId, episodeId);
      if (success) {
        await _loadFavorites();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).favoriteError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
              onPressed: _loadFavorites,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_favorites.isEmpty) {
      return Center(
        child: Text(
          l10n.noFavorites,
          style: const TextStyle(fontSize: 18),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.favorites),
        backgroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _favorites.length,
          itemBuilder: (context, index) {
            final favorite = _favorites[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 100,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.star, color: Colors.amber, size: 40),
                  ),
                ),
                title: Text(favorite['title'] ?? 'Sans titre'),
                subtitle: Text(favorite['description'] ?? 'Pas de description'),
                trailing: IconButton(
                  icon: const Icon(Icons.star, color: Colors.amber),
                  tooltip: l10n.removeFavorite,
                  onPressed: () => _removeFavorite(favorite['episode_id'].toString()),
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/video-player',
                    arguments: {
                      'episodeId': favorite['episode_id'],
                      'movieId': favorite['movie_id'],
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
} 