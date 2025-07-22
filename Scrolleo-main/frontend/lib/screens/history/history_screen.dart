import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/movie_service.dart';
import '../../services/auth_service.dart';
import '../../providers/favorites_provider.dart';
import 'dart:convert';
import '../../models/movie.dart';
import '../../providers/history_provider.dart';
import 'package:http/http.dart' as http;
import '../movie_details/movie_details_screen.dart';
import '../../widgets/episode_player_screen.dart';
import '../../config/environment.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final isLoggedIn = authService.isAuthenticated;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Historique', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoggedIn && user != null
          ? Consumer<HistoryProvider>(
              builder: (context, historyProvider, _) {
                return Consumer2<MovieService, FavoritesProvider>(
                  builder: (context, movieService, favoritesProvider, _) {
                    return FutureBuilder<List<dynamic>>(
                      future: http.get(Uri.parse('${Environment.apiBaseUrl}/history/${user.id}'))
                          .then((response) {
                              if (response.statusCode == 200) {
                                  final decoded = json.decode(response.body);
                                  if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
                                      return decoded['data'] as List<dynamic>;
                                  } else if (decoded is List) {
                                      return decoded;
                                  }
                                  return [];
                              } else {
                                  throw Exception('Erreur lors de la récupération de l\'historique: ${response.statusCode}');
                              }
                          }),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Erreur lors du chargement de l\'historique', style: TextStyle(color: Colors.red)));
                        }
                        final history = snapshot.data ?? [];
                        if (history.isEmpty) {
                          return const Center(child: Text('Aucun film dans l\'historique', style: TextStyle(color: Colors.white70)));
                        }
                        return ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final item = history[index];
                            final movieId = item['movie_id']?.toString() ?? '';
                            final imageUrl = (item['cover_image'] != null && item['cover_image'].toString().isNotEmpty)
                                ? (item['cover_image'].toString().startsWith('http')
                                    ? item['cover_image']
                                    : Environment.apiBaseUrl.replaceAll('/api','') + item['cover_image'])
                                : null;

                            return FutureBuilder(
                              future: http.get(Uri.parse(Environment.apiBaseUrl + '/movies/detail/$movieId'))
                                  .then((response) {
                                if (response.statusCode == 200) {
                                  final detail = json.decode(response.body);
                                  return detail['data'];
                                }
                                return null;
                              }),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    color: Colors.grey[900],
                                    child: ListTile(
                                      leading: imageUrl != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                imageUrl,
                                                width: 60,
                                                height: 90,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    width: 60,
                                                    height: 90,
                                                    color: Colors.grey,
                                                    child: const Icon(Icons.error),
                                                  );
                                                },
                                              ),
                                            )
                                          : const Icon(Icons.movie, color: Colors.white, size: 40),
                                      title: const Text('Chargement...', style: TextStyle(color: Colors.white)),
                                    ),
                                  );
                                }
                                if (snapshot.hasError || snapshot.data == null) {
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    color: Colors.grey[900],
                                    child: ListTile(
                                      leading: imageUrl != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                imageUrl,
                                                width: 60,
                                                height: 90,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    width: 60,
                                                    height: 90,
                                                    color: Colors.grey,
                                                    child: const Icon(Icons.error),
                                                  );
                                                },
                                              ),
                                            )
                                          : const Icon(Icons.movie, color: Colors.white, size: 40),
                                      title: const Text('Erreur ou film introuvable', style: TextStyle(color: Colors.red)),
                                    ),
                                  );
                                }
                                final movieData = snapshot.data;
                                final movieTitle = movieData['title'] ?? 'Sans titre';
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  color: Colors.grey[900],
                                  child: ListTile(
                                    leading: imageUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              imageUrl,
                                              width: 60,
                                              height: 90,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  width: 60,
                                                  height: 90,
                                                  color: Colors.grey,
                                                  child: const Icon(Icons.error),
                                                );
                                              },
                                            ),
                                          )
                                        : const Icon(Icons.movie, color: Colors.white, size: 40),
                                    title: Text(
                                      movieTitle,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['episode_title'] ?? '',
                                          style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          'Saison ${item['season_number'] ?? ''} • Épisode ${item['episode_number'] ?? ''}',
                                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                                        ),
                                        if (item['watched_at'] != null)
                                          Text(
                                            'Vu le : ${item['watched_at']}',
                                            style: const TextStyle(color: Colors.white38, fontSize: 13),
                                          ),
                                      ],
                                    ),
                                    onTap: () async {
                                      final episodeId = item['episode_id']?.toString();
                                      print('DEBUG episodeId depuis historique: $episodeId');
                                      if (episodeId != null) {
                                        try {
                                          final response = await http.get(Uri.parse(Environment.apiBaseUrl + '/episodes/$episodeId'));
                                          if (response.statusCode == 200) {
                                            final decoded = json.decode(response.body);
                                            final episodeData = decoded['episode'];
                                            final uploads = decoded['uploads'] as List<dynamic>;
                                            if (episodeData != null) {
                                              final videoUpload = uploads.firstWhere(
                                                (u) => u['type'] == 'video' && u['status'] == 'completed' && u['path'] != null,
                                                orElse: () => null,
                                              );
                                              if (videoUpload != null) {
                                                final videoUrl = videoUpload['path'];
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => EpisodePlayerScreen(
                                                      episodeId: int.parse(episodeId),
                                                      videoUrl: videoUrl,
                                                      title: episodeData['title'],
                                                      description: episodeData['description'],
                                                      movieId: movieId,
                                                      seasonNumber: episodeData['season_number'],
                                                      episodeNumber: episodeData['episode_number'],
                                                      tikTokEpisodeId: int.parse(episodeId),
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Aucune vidéo trouvée pour cet épisode')),
                                                );
                                              }
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Aucune donnée trouvée pour cet épisode')),
                                              );
                                            }
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Erreur lors de la récupération de l\'épisode')),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Erreur lors du chargement de l\'épisode')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            )
          : const Center(child: Text('Connecte-toi pour voir ton historique', style: TextStyle(color: Colors.white70))),
    );
  }
} 