import 'package:flutter/material.dart';
import '../services/episode_service.dart';
import '../providers/favorites_provider.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';
import '../services/auth_service.dart';

class EpisodeList extends StatefulWidget {
  final String movieId;
  final bool isDirector;
  final Function(String)? onEpisodeSelected;

  const EpisodeList({
    Key? key,
    required this.movieId,
    this.isDirector = false,
    this.onEpisodeSelected,
  }) : super(key: key);

  @override
  EpisodeListState createState() => EpisodeListState();
}

class EpisodeListState extends State<EpisodeList> {
  final EpisodeService _episodeService = EpisodeService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _episodes = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedEpisodeId;
  Movie? _movie;
  Map<String, Map<String, dynamic>> _episodeAccess = {};

  @override
  void initState() {
    super.initState();
    _loadMovieAndEpisodes();
  }

  void reloadEpisodes() {
    _loadMovieAndEpisodes();
  }

  Future<void> _loadMovieAndEpisodes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Charger les infos du film
      final response = await http.get(Uri.parse('${Environment.apiBaseUrl}/movies/detail/${widget.movieId}'));
      if (response.statusCode == 200) {
        final detail = json.decode(response.body);
        final movieData = detail['data'] ?? {};
        _movie = Movie.fromJson(movieData);
      }

      // Charger les épisodes
      final episodes = await _episodeService.getEpisodesForMovie(widget.movieId);
      
      // Vérifier l'accès pour chaque épisode
      await _checkEpisodesAccess(episodes);
      
      setState(() {
        _episodes = episodes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkEpisodesAccess(List<Map<String, dynamic>> episodes) async {
    for (final episode in episodes) {
      final episodeId = episode['id'] ?? episode['episode_id'];
      if (episodeId != null) {
        try {
          final accessInfo = await _episodeService.checkEpisodeAccess(episodeId.toString());
          _episodeAccess[episodeId.toString()] = accessInfo;
          
          // Mettre à jour l'épisode avec les informations de l'accès (y compris la miniature)
          if (accessInfo['episode'] != null) {
            episode['thumbnail_url'] = accessInfo['episode']['thumbnail_url'];
          }
        } catch (e) {
          print('Erreur lors de la vérification d\'accès pour l\'épisode $episodeId: $e');
          // Par défaut, considérer comme non accessible
          _episodeAccess[episodeId.toString()] = {
            'hasAccess': false,
            'reason': 'error'
          };
        }
      }
    }
  }

  void _selectEpisode(String episodeId) {
    setState(() {
      _selectedEpisodeId = episodeId;
    });
    widget.onEpisodeSelected?.call(episodeId);
  }

  Future<void> _unlockEpisode(String episodeId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await _episodeService.unlockEpisode(episodeId);
      
      // Mettre à jour l'accès
      _episodeAccess[episodeId] = {
        'hasAccess': true,
        'reason': 'episode_debloque'
      };

      setState(() {
        _isLoading = false;
      });

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Épisode débloqué ! Coins dépensés: ${result['coinsSpent']}'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
      });

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

  void _showUnlockDialog(String episodeId, Map<String, dynamic> episode, Map<String, dynamic> accessInfo) {
    final requiredCoins = accessInfo['requiredCoins'] ?? 1;
    final userBalance = accessInfo['userBalance'] ?? 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Débloquer l\'épisode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Voulez-vous débloquer cet épisode ?'),
              const SizedBox(height: 8),
              Text('Coût: $requiredCoins coin(s)'),
              Text('Votre solde: $userBalance coin(s)'),
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
              child: const Text('Annuler'),
            ),
            if (userBalance >= requiredCoins)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _unlockEpisode(episodeId);
                },
                child: const Text('Débloquer'),
              ),
          ],
        );
      },
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
              onPressed: _loadMovieAndEpisodes,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_episodes.isEmpty) {
      return const Center(
        child: Text(
          'Aucun épisode disponible',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // Affichage saison et nombre d'épisodes
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_movie != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (_movie!.season != null && _movie!.season!.isNotEmpty)
                  Text(
                    'Saison : ${_movie!.season}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                const SizedBox(width: 24),
                Text(
                  'Nombre d\'épisodes : ${_episodes.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: _episodes.length,
            itemBuilder: (context, index) {
              final episode = _episodes[index];
              final episodeId = episode['id'] ?? episode['episode_id'];
              final isSelected = episodeId == _selectedEpisodeId;
              final validEpisodeId = episodeId != null ? episodeId.toString() : null;
              final accessInfo = _episodeAccess[validEpisodeId ?? ''];
              final hasAccess = accessInfo?['hasAccess'] ?? false;
              final isFree = episode['is_free'] ?? false;
              final episodeNumber = episode['episode_number'] ?? (index + 1);
              

              
              return GestureDetector(
                  onTap: () {
                    if (validEpisodeId != null) {
                      if (hasAccess || isFree) {
                        _selectEpisode(validEpisodeId);
                      } else {
                        _showUnlockDialog(validEpisodeId, episode, accessInfo ?? {});
                      }
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
                      if (episode['thumbnail_url'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            episode['thumbnail_url'],
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback vers le numéro si l'image ne charge pas
                              return Center(
                                child: Text(
                                  '$episodeNumber',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      else
                        // Numéro de l'épisode centré (fallback)
                        Center(
                          child: Text(
                            '$episodeNumber',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
                      // Icône de cadenas pour les épisodes non gratuits
                      if (!hasAccess && !isFree)
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
          ),
        ),
      ],
    );
  }
} 