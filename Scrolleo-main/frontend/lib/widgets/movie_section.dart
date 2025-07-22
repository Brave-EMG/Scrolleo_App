import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import 'movie_card.dart';
import 'section_header.dart';
import '../providers/likes_provider.dart';
import '../theme/app_theme.dart';

class MovieSection extends StatelessWidget {
  final String title;
  final List<Movie> movies;
  final Function(Movie) onMovieTap;
  final bool showBadge;
  final String? badgeText;
  final Set<String>? likedMovieIds;
  final Function(Movie)? onLikeToggle;

  const MovieSection({
    Key? key,
    required this.title,
    required this.movies,
    required this.onMovieTap,
    this.showBadge = false,
    this.badgeText,
    this.likedMovieIds,
    this.onLikeToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return const SizedBox.shrink();
    }

    final likesProvider = Provider.of<LikesProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppTheme.mobileBreakpoint;
    final isTablet = screenWidth < AppTheme.tabletBreakpoint && screenWidth >= AppTheme.mobileBreakpoint;
    
    // Calcul des dimensions responsives
    final sectionHeight = isMobile ? 280.0 : (isTablet ? 300.0 : 320.0);
    final horizontalPadding = isMobile ? 12.0 : 16.0;
    final verticalPadding = isMobile ? 12.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            verticalPadding,
            horizontalPadding,
            isMobile ? 6.0 : 8.0,
          ),
          child: SectionHeader(title: title),
        ),
        SizedBox(
          height: sectionHeight,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return MovieCard(
                movie: movie,
                onTap: () => onMovieTap(movie),
                isLiked: likesProvider.isLiked(movie.id.toString()),
                onLikeToggle: onLikeToggle != null ? () => onLikeToggle!(movie) : null,
              );
            },
          ),
        ),
      ],
    );
  }
} 