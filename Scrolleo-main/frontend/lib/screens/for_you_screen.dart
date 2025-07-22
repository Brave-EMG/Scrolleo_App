import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/episode.dart';
import '../services/movie_service.dart';
import '../services/episode_service.dart';
import '../widgets/reel_player.dart';

class ForYouScreen extends StatefulWidget {
  final int userId;
  const ForYouScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen> {
  List<Episode> episodes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadEpisodes();
  }

  Future<void> loadEpisodes() async {
    setState(() => loading = true);
    final movies = await MovieService.getAllMovies();
    final List<Episode> loadedEpisodes = [];
    for (final movie in movies) {
      final episode = await EpisodeService.getFirstEpisode(movie.id, widget.userId);
      if (episode != null) loadedEpisodes.add(episode);
    }
    setState(() {
      episodes = loadedEpisodes;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        return ReelPlayer(
          episode: episodes[index],
          isActive: true,
          onShare: () async {
            final movieService = MovieService();
            await movieService.shareMovie(
              episodes[index].movieId.toString(),
              episodeId: episodes[index].id.toString(),
            );
          },
          movieId: episodes[index].movieId.toString(),
          movieTitle: episodes[index].title,
        );
      },
    );
  }
} 