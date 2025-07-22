import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/movie_service.dart';
import '../../models/movie.dart';
import '../../widgets/movie_card.dart';
import '../../theme/app_theme.dart';
import '../../config/environment.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<Movie> _movies = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    setState(() => _isLoading = true);
    final movieService = Provider.of<MovieService>(context, listen: false);
    _movies = _searchQuery.isEmpty
        ? movieService.movies
        : await movieService.searchMovies(_searchQuery);
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Explorer',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un film...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _loadMovies();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMovieGrid(context, _movies),
          ),
        ],
              ),
            );
          }

  Widget _buildMovieGrid(BuildContext context, List<Movie> movies) {
          if (movies.isEmpty) {
            return Center(
              child: Text(
          _searchQuery.isEmpty
              ? 'Aucun film disponible'
              : 'Aucun résultat pour "$_searchQuery"',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            fontSize: 16,
          ),
              ),
            );
          }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return _buildMovieCard(context, movie);
      },
    );
  }

  Widget _buildMovieCard(BuildContext context, Movie movie) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // TODO: Naviguer vers la page de détails du film
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (movie.posterUrl.isNotEmpty)
                    ? Image.network(
                        movie.posterUrl.startsWith('http') ? movie.posterUrl : '${Environment.apiBaseUrl}${movie.posterUrl}',
                    fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.movie, color: Colors.white54, size: 48),
                        ),
                      )
                    : Container(
                        color: Colors.blue,
                        child: const Icon(Icons.movie, color: Colors.white, size: 48),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              movie.title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                      ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  movie.rating.toStringAsFixed(1),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.visibility,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${movie.views}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                    fontSize: 14,
                      ),
                    ),
                  ],
                ),
            ],
        ),
      ),
    );
  }
} 