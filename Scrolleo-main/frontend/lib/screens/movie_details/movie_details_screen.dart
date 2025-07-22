import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/movie.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/likes_provider.dart';
import '../video_player/video_player_screen.dart';
import '../../widgets/movie_details.dart';
import '../../utils/app_date_utils.dart';
import '../../services/auth_service.dart';
import '../../services/like_service.dart';

class MovieDetailsScreen extends StatelessWidget {
  final Movie movie;

  const MovieDetailsScreen({
    Key? key,
    required this.movie,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isFavorite = favoritesProvider.isFavorite(movie);
    final likesProvider = Provider.of<LikesProvider>(context);
    final isLiked = likesProvider.isLiked(movie.id.toString());

    return Scaffold(
      backgroundColor: Colors.black,
      body: MovieDetails(movieId: movie.id.toString()),
    );
  }
}

class MovieDetailsWithLike extends StatelessWidget {
  final Movie movie;
  final bool isLiked;
  final VoidCallback onLikeToggle;

  const MovieDetailsWithLike({
    Key? key,
    required this.movie,
    required this.isLiked,
    required this.onLikeToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                        movie.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
            IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.white,
              ),
              onPressed: onLikeToggle,
              tooltip: isLiked ? 'Retirer des likes' : 'Liker',
            ),
          ],
      ),
        Expanded(child: MovieDetails(movieId: movie.id.toString())),
            ],
    );
  }
} 