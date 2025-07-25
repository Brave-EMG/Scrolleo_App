import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/movie.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../widgets/episode_list.dart';
import '../../widgets/episode_details.dart';
import '../../config/api_config.dart';

class DirectorEpisodesScreen extends StatefulWidget {
  final Movie movie;

  const DirectorEpisodesScreen({
    Key? key,
    required this.movie,
  }) : super(key: key);

  @override
  _DirectorEpisodesScreenState createState() => _DirectorEpisodesScreenState();
}

class _DirectorEpisodesScreenState extends State<DirectorEpisodesScreen> {
  String? _selectedEpisodeId;
  final GlobalKey<EpisodeListState> _episodeListKey = GlobalKey<EpisodeListState>();

  void _handleEpisodeSelected(String episodeId) {
    setState(() {
      _selectedEpisodeId = episodeId;
    });
  }

  void _openAddEpisodeDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        final _titleController = TextEditingController();
        final _descriptionController = TextEditingController();
        final _episodeNumberController = TextEditingController();
        final _seasonNumberController = TextEditingController(text: '1');
        return AlertDialog(
          title: const Text('Ajouter un épisode'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Titre'),
              ),
              TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              TextField(
                  controller: _episodeNumberController,
                  decoration: const InputDecoration(labelText: 'Numéro d\'épisode'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                  controller: _seasonNumberController,
                  decoration: const InputDecoration(labelText: 'Numéro de saison'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
                final title = _titleController.text.trim();
                final description = _descriptionController.text.trim();
                final episodeNumber = int.tryParse(_episodeNumberController.text.trim()) ?? 1;
                final seasonNumber = int.tryParse(_seasonNumberController.text.trim()) ?? 1;
                if (title.isEmpty) return;
                Navigator.pop(context, {
                  'title': title,
                  'description': description,
                  'episode_number': episodeNumber,
                  'season_number': seasonNumber,
                });
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      // Envoi au backend
                  final response = await http.post(
                    Uri.parse('${ApiConfig.apiUrl}/api/episodes/'),
                    headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'movie_id': widget.movie.id.toString(),
          ...result,
                    }),
                  );
      if (response.statusCode == 201 || response.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Épisode ajouté avec succès')),
                    );
        _episodeListKey.currentState?.reloadEpisodes(); // Rafraîchit la liste sans recharger tout l'écran
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout:  {response.statusCode}')),
                  );
                }
              }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Épisodes - ${widget.movie.title}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openAddEpisodeDialog,
          ),
        ],
      ),
      body: Row(
            children: [
          // Liste des épisodes (1/3 de l'écran)
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
          ),
              child: EpisodeList(
                key: _episodeListKey,
                movieId: widget.movie.id.toString(),
                isDirector: true,
                onEpisodeSelected: _handleEpisodeSelected,
              ),
          ),
          ),
          // Détails de l'épisode sélectionné (2/3 de l'écran)
          Expanded(
            flex: 2,
            child: _selectedEpisodeId != null
                ? EpisodeDetails(
                    episodeId: _selectedEpisodeId!,
                    isDirector: true,
                  )
                : Center(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                                Text(
                          'Sélectionnez un épisode pour voir les détails',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddEpisodeDialog,
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un épisode',
      ),
    );
  }
}

class Episode {
  final String id;
  final String movieId;
  final String title;
  final String description;
  final int episodeNumber;
  final int seasonNumber;
  final String videoUrl;

  Episode({
    required this.id,
    required this.movieId,
    required this.title,
    required this.description,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.videoUrl,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: (json['id'] ?? json['episode_id'])?.toString() ?? '',
      movieId: json['movie_id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      episodeNumber: json['episode_number'] ?? 0,
      seasonNumber: json['season_number'] ?? 1,
      videoUrl: json['video_url'] ?? '',
    );
  }
} 