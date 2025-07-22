import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminMovieEpisodesScreen extends StatelessWidget {
  final int movieId;
  final String movieTitle;
  const AdminMovieEpisodesScreen({Key? key, required this.movieId, required this.movieTitle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Remplacer par la vraie liste des épisodes (API)
    final List<Map<String, dynamic>> episodes = [
      {'id': 201, 'title': 'Épisode 1'},
      {'id': 202, 'title': 'Épisode 2'},
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('Épisodes de $movieTitle'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: ListView.builder(
        itemCount: episodes.length,
        itemBuilder: (context, i) {
          final episode = episodes[i];
            return Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        episode['title'],
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push(
                          '/admin/episode_upload',
                          extra: {'episodeId': episode['id'], 'episodeTitle': episode['title']},
                        );
                      },
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Uploader'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            );
        },
      ),
    );
  }
} 