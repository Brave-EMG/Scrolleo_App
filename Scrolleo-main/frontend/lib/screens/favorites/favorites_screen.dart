import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../providers/favorites_provider.dart';
import '../../models/movie.dart';
import '../../services/auth_service.dart';
import '../../services/favorites_service.dart';
import '../movie_details/movie_details_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/environment.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late FavoritesService _favoritesService;
  List<Movie> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    final prefs = await SharedPreferences.getInstance();
    _favoritesService = FavoritesService(prefs);
    _loadFavorites();
  }

  Future<Map<String, dynamic>> fetchMovieDetail(String movieId, String token) async {
    final response = await http.get(
      Uri.parse('${Environment.apiBaseUrl}/movies/detail/$movieId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la récupération du film');
    }
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;
      final token = await authService.getToken();

      if (userId != null && token != null) {
        final favorites = await _favoritesService.getUserFavorites(userId, token);

        // Pour chaque favori, enrichir avec la vraie image
        final List<Movie> enrichedFavorites = [];
        for (final movie in favorites) {
          try {
            final detail = await fetchMovieDetail(movie.id.toString(), token);
            final coverImage = detail['data']?['cover_image'];
            enrichedFavorites.add(
              movie.copyWith(posterUrl: coverImage),
            );
          } catch (e) {
            enrichedFavorites.add(movie); // fallback
          }
        }

        setState(() {
          _favorites = enrichedFavorites;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des favoris: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            color: Colors.black,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      'Mes Favoris',
                      style: AppTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Liste des favoris
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : _favorites.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star_border,
                              size: 64,
                              color: Colors.amber,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Vous n\'avez pas encore de favoris',
                              style: AppTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Explorez notre catalogue et ajoutez des films à vos favoris',
                              style: AppTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _favorites.length,
                        itemBuilder: (context, index) {
                          final movie = _favorites[index];
                          return _buildFavoriteItem(context, movie);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteItem(BuildContext context, Movie movie) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailsScreen(movie: movie),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Image avec badge Tendance
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: Stack(
                children: [
                  Image.network(
                    movie.posterUrl,
                    width: 120,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/movies/thumbnails/saloum_poster.jpg',
                        width: 120,
                        height: 160,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  if (movie.isTrending)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[900],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Tendance',
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Informations
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: AppTheme.titleMedium.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie.genres.join(' • '),
                      style: AppTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          movie.rating.toString(),
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Bouton de suppression des favoris
            IconButton(
              icon: const Icon(Icons.star, color: Colors.amber),
              onPressed: () async {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id;
                final token = await authService.getToken();

                if (userId != null && token != null) {
                  final success = await _favoritesService.removeFromFavorites(
                    userId,
                    movie.id.toString(),
                    token,
                  );

                  if (success) {
                    setState(() {
                      _favorites.remove(movie);
                    });
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
} 