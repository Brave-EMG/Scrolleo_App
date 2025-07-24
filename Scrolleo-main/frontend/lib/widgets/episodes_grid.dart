import 'package:flutter/material.dart';
import '../services/episode_service.dart';
import '../services/auth_service.dart';

class EpisodesGrid extends StatefulWidget {
  final int totalEpisodes;
  final int currentEpisode;
  final Function(int) onEpisodeSelected;
  final String movieId;

  const EpisodesGrid({
    Key? key,
    required this.totalEpisodes,
    required this.currentEpisode,
    required this.onEpisodeSelected,
    required this.movieId,
  }) : super(key: key);

  @override
  State<EpisodesGrid> createState() => _EpisodesGridState();
}

class _EpisodesGridState extends State<EpisodesGrid> {
  final EpisodeService _episodeService = EpisodeService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _episodes = [];
  Map<String, Map<String, dynamic>> _episodeAccess = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
  }

  Future<void> _loadEpisodes() async {
    try {
      setState(() {
        _isLoading = true;
      });

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
        _isLoading = false;
      });
      print('Erreur lors du chargement des épisodes: $e');
    }
  }

  Future<void> _checkEpisodesAccess(List<Map<String, dynamic>> episodes) async {
    for (final episode in episodes) {
      final episodeId = episode['id'] ?? episode['episode_id'];
      if (episodeId != null) {
        try {
          final accessInfo = await _episodeService.checkEpisodeAccess(episodeId.toString());
          _episodeAccess[episodeId.toString()] = accessInfo;
        } catch (e) {
          print('Erreur lors de la vérification d\'accès pour l\'épisode $episodeId: $e');
          _episodeAccess[episodeId.toString()] = {
            'hasAccess': false,
            'reason': 'error'
          };
        }
      }
    }
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

  void _showUnlockDialog(String episodeId, Map<String, dynamic> accessInfo) {
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

    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Votre Collection',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Au total ${widget.totalEpisodes} épisodes',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Onglets de pagination
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildPageTab('1-30', true),
                _buildPageTab('31-60', false),
                _buildPageTab('61-70', false),
              ],
            ),
          ),

          // Grille d'épisodes
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _episodes.length,
              itemBuilder: (context, index) {
                final episode = _episodes[index];
                final episodeNumber = episode['episode_number'] ?? (index + 1);
                final episodeId = episode['id'] ?? episode['episode_id'];
                final accessInfo = _episodeAccess[episodeId?.toString() ?? ''];
                final hasAccess = accessInfo?['hasAccess'] ?? false;
                final isFree = episode['is_free'] ?? false;
                final isLocked = !hasAccess && !isFree;
                final isSelected = episodeNumber == widget.currentEpisode;

                return _EpisodeButton(
                  episode: episode,
                  episodeNumber: episodeNumber,
                  isSelected: isSelected,
                  isLocked: isLocked,
                  onTap: isLocked 
                    ? () => _showUnlockDialog(episodeId.toString(), accessInfo ?? {})
                    : () => widget.onEpisodeSelected(episodeNumber),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTab(String text, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.red : Colors.grey,
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _EpisodeButton extends StatelessWidget {
  final Map<String, dynamic> episode;
  final int episodeNumber;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback? onTap;

  const _EpisodeButton({
    Key? key,
    required this.episode,
    required this.episodeNumber,
    this.isSelected = false,
    this.isLocked = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[800] : Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!isLocked && episodeNumber == 1)
                            const Icon(
                              Icons.graphic_eq,
                              color: Colors.grey,
                              size: 16,
                            ),
                          Text(
                            episodeNumber.toString(),
                            style: TextStyle(
                              color: isLocked ? Colors.grey : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            else
              // Numéro de l'épisode centré (fallback)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isLocked && episodeNumber == 1)
                      const Icon(
                        Icons.graphic_eq,
                        color: Colors.grey,
                        size: 16,
                      ),
                    Text(
                      episodeNumber.toString(),
                      style: TextStyle(
                        color: isLocked ? Colors.grey : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            if (isLocked)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.lock,
                  color: Colors.orange,
                  size: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
} 