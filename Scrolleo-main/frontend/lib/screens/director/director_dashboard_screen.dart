import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../models/movie.dart';
import 'director_movies_screen.dart';
import 'director_movie_form_screen.dart';
import 'director_pending_movies_screen.dart';
import 'director_upcoming_movies_screen.dart';
import 'director_episodes_screen.dart';
import '../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/environment.dart';

class DirectorDashboardScreen extends StatefulWidget {
  const DirectorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DirectorDashboardScreen> createState() => _DirectorDashboardScreenState();
}

class _DirectorDashboardScreenState extends State<DirectorDashboardScreen> {
  int _selectedIndex = 0;
  int _selectedTab = 0; // 0 = Films Récents, 1 = Meilleurs Films

  List<Movie> myMovies = [];
  List<MinimalMovie> recentMovies = [];
  bool _isLoading = false;
  String? _error;
  int totalFilms = 0;
  int totalViews = 0;
  int totalLikes = 0;
  int totalFavoritedFilms = 0;
  double totalRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchDirectorMovies();
    _fetchRecentMovies();
    _fetchDirectorStats();
  }

  Future<void> _fetchDirectorMovies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Utilisateur non connecté';
          _isLoading = false;
        });
        return;
      }
      final response = await http.get(Uri.parse('${Environment.apiBaseUrl}/movies/director/${user.id}'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          myMovies = data.map((e) => Movie.fromJson(e)).toList();
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        // Aucun film trouvé
        setState(() {
          myMovies = [];
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _error = 'Erreur lors de la récupération des films';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la récupération des films: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRecentMovies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Utilisateur non connecté';
          _isLoading = false;
        });
        return;
      }
      final response = await http.get(Uri.parse('${Environment.apiBaseUrl}/movies/director/${user.id}'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Movie> movies = data.map((e) => Movie.fromJson(e)).toList();
        // Filtrer les films dont la date de sortie est passée
        final now = DateTime.now();
        final releasedMovies = movies.where((m) => !m.releaseDate.isAfter(now)).toList();
        // Trier par date de sortie et prendre les 5 plus récents
        releasedMovies.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
        final recentMovies = releasedMovies.take(5).toList();
        setState(() {
          this.recentMovies = recentMovies.map((m) => MinimalMovie.fromMovie(m)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Erreur lors de la récupération des films récents';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la récupération des films récents: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDirectorStats() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      final token = authService.jwtToken;
      if (user == null || token == null) return;
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/stats/${user.id}/DirectorStats'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final stats = data['data'] ?? {};
        setState(() {
          totalFilms = int.tryParse(stats['total_movies']?.toString() ?? '0') ?? 0;
          totalViews = int.tryParse(stats['total_views']?.toString() ?? '0') ?? 0;
          totalLikes = int.tryParse(stats['total_likes']?.toString() ?? '0') ?? 0;
          totalFavoritedFilms = int.tryParse(stats['total_favorites']?.toString() ?? '0') ?? 0;
        });
      }
      final revenueResponse = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/stats/revenue?period=30'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (revenueResponse.statusCode == 200) {
        final revenueData = json.decode(revenueResponse.body);
        setState(() {
          totalRevenue = double.tryParse(revenueData['revenue']?.toString() ?? '0') ?? 0.0;
        });
      }
    } catch (e) {
      // ignore erreur stats
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        automaticallyImplyLeading: false,
        title: const Text('Tableau de bord réalisateur'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              if (authService.currentUser != null) {
                await authService.signOut();
                if (mounted) {
                  context.go('/login');
                }
              } else {
                context.go('/login');
              }
            },
            icon: Icon(
              authService.currentUser != null 
                ? Icons.logout 
                : Icons.login,
              color: Colors.white,
            ),
            label: Text(
              authService.currentUser != null 
                ? 'Se déconnecter' 
                : 'Se connecter',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 500;
          final maxContentWidth = isMobile ? double.infinity : 900.0;
          if (constraints.maxWidth > 900) {
            return Center(
              child: Container(
                width: maxContentWidth,
                child: Row(
                  children: [
                    _buildSideMenu(user),
                    Expanded(child: _buildSection(_selectedIndex)),
                  ],
                ),
              ),
            );
          }
          // Version mobile/tablette : on évite Expanded autour du contenu scrollable
          return SafeArea(
            child: Center(
              child: Container(
                width: maxContentWidth,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _buildSection(_selectedIndex),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _buildBottomMenu(isMobile: isMobile),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSideMenu(user) {
    return FutureBuilder<Map<String, dynamic>?> (
      future: _fetchDirectorProfile(user?.id),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        return Container(
          width: 250,
          color: Colors.grey[900],
          child: Column(
            children: [
              const SizedBox(height: 48),
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                profile != null ? (profile['username'] ?? 'Réalisateur') : 'Réalisateur',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                profile != null ? (profile['email'] ?? '') : (user?.email ?? ''),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 48),
              _buildMenuItem(0, Icons.dashboard, 'Tableau de bord'),
              _buildMenuItem(1, Icons.movie, 'Mes Films'),
              // _buildMenuItem(2, Icons.add_circle, 'Ajouter un film'),
              _buildMenuItem(4, Icons.new_releases, 'Films à venir'),
              // _buildMenuItem(5, Icons.video_library, 'Épisodes'),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _fetchDirectorProfile(String? userId) async {
    if (userId == null) return null;
    try {
      final response = await http.get(Uri.parse('${Environment.apiBaseUrl}/auth/users/detailuser/$userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['user'] ?? data;
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  Widget _buildBottomMenu({bool isMobile = false}) {
    return Container(
      color: Colors.grey[900],
      padding: EdgeInsets.symmetric(vertical: isMobile ? 2 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMenuItem(0, Icons.dashboard, 'Tableau de bord', isMobile: isMobile),
          _buildMenuItem(1, Icons.movie, 'Mes Films', isMobile: isMobile),
          // _buildMenuItem(2, Icons.add_circle, 'Ajouter un film', isMobile: isMobile),
          _buildMenuItem(4, Icons.new_releases, 'Films à venir', isMobile: isMobile),
          // _buildMenuItem(5, Icons.video_library, 'Épisodes', isMobile: isMobile),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String label, {bool isMobile = false}) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (index == 0) {
          _fetchDirectorMovies();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24, vertical: isMobile ? 8 : 16),
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.white70,
              size: isMobile ? 20 : 28,
            ),
            if (!isMobile)
              SizedBox(height: 4),
            if (!isMobile)
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(int index) {
    switch (index) {
      case 0:
        return _buildDashboard();
      case 1:
        return DirectorMoviesScreen(
          onMoviesChanged: () {
            _fetchDirectorMovies();
            _fetchRecentMovies();
          },
        );
      case 2:
        return const SizedBox.shrink();
      case 4:
        return const DirectorUpcomingMoviesScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDashboard() {
    print('DASHBOARD: Nombre de films = [38;5;2m${myMovies.length}[0m');
    final filteredMovies = myMovies.where((m) => m.status == 'approved' && !m.releaseDate.isAfter(DateTime.now())).toList();
    final totalFilmsDisplay = totalFilms;
    final totalViewsDisplay = totalViews;
    final totalLikesDisplay = totalLikes;
    final totalFavoritedFilmsDisplay = totalFavoritedFilms;
    final bestThree = List<Movie>.from(filteredMovies)
      ..sort((a, b) => b.likes.compareTo(a.likes));
    bestThree.length > 3 ? bestThree.length = 3 : null;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (filteredMovies.isEmpty) {
      return const Center(
        child: Text(
          'Aucun film trouvé',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final isMobile = constraints.maxWidth < 500;
        final cardPadding = isMobile ? 12.0 : 20.0;
        final cardIconSize = isMobile ? 24.0 : 32.0;
        final cardFontSize = isMobile ? 18.0 : 24.0;
        final cardTitleSize = isMobile ? 13.0 : 16.0;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 8.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: const Text(
                  'Tableau de bord',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 12 : 24),
              isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(child: _buildStatCard('Total Films', '$totalFilmsDisplay', Icons.movie, Colors.blue, cardPadding, cardIconSize, cardFontSize, cardTitleSize)),
                        const SizedBox(width: 24),
                        Flexible(child: _buildStatCard('Vues Totales', '$totalViewsDisplay', Icons.visibility, Colors.green, cardPadding, cardIconSize, cardFontSize, cardTitleSize)),
                        const SizedBox(width: 24),
                        Flexible(child: _buildStatCard('Nombre de Likes', '$totalLikesDisplay', Icons.favorite, Colors.red, cardPadding, cardIconSize, cardFontSize, cardTitleSize)),
                        const SizedBox(width: 24),
                        Flexible(child: _buildStatCard('Films en Favoris', '$totalFavoritedFilmsDisplay', Icons.favorite_border, Colors.pink, cardPadding, cardIconSize, cardFontSize, cardTitleSize)),
                        const SizedBox(width: 24),
                        Flexible(child: _buildStatCard('Revenu (30j)', '${totalRevenue.toStringAsFixed(0)} FCFA', Icons.monetization_on, Colors.amber, cardPadding, cardIconSize, cardFontSize, cardTitleSize)),
                      ],
                    )
                  : Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: _buildStatCard('Total Films', '$totalFilmsDisplay', Icons.movie, Colors.blue, cardPadding, cardIconSize, cardFontSize, cardTitleSize),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: _buildStatCard('Vues Totales', '$totalViewsDisplay', Icons.visibility, Colors.green, cardPadding, cardIconSize, cardFontSize, cardTitleSize),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: _buildStatCard('Nombre de Likes', '$totalLikesDisplay', Icons.favorite, Colors.red, cardPadding, cardIconSize, cardFontSize, cardTitleSize),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: _buildStatCard('Films en Favoris', '$totalFavoritedFilmsDisplay', Icons.favorite_border, Colors.pink, cardPadding, cardIconSize, cardFontSize, cardTitleSize),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: _buildStatCard('Revenu (30j)', '${totalRevenue.toStringAsFixed(0)} FCFA', Icons.monetization_on, Colors.amber, cardPadding, cardIconSize, cardFontSize, cardTitleSize),
                        ),
                      ],
                    ),
              SizedBox(height: isMobile ? 18 : 32),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => _selectedTab = 0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == 0 ? Colors.blue : Colors.grey[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    child: const Text('Films Récents'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => setState(() => _selectedTab = 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == 1 ? Colors.blue : Colors.grey[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    child: const Text('Meilleurs Films'),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 8 : 16),
              if (_selectedTab == 0)
                recentMovies.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun film récent trouvé',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentMovies.length,
                        itemBuilder: (context, index) {
                          final movie = recentMovies[index];
                          return Card(
                            color: Colors.grey[900],
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    movie.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (movie.genres.isNotEmpty)
                                    Text(
                                      movie.genres.join(', '),
                                      style: const TextStyle(
                                        color: Colors.orangeAccent,
                                        fontSize: 18,
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Date de sortie: ${movie.releaseDate.day}/${movie.releaseDate.month}/${movie.releaseDate.year}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildStatItem(Icons.visibility, '${movie.views} vues'),
                                      _buildStatItem(Icons.favorite, '${movie.likes} j\'aime'),
                                      _buildStatItem(Icons.star, '${movie.favorites} favoris'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              if (_selectedTab == 1)
                bestThree.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun meilleur film trouvé',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: bestThree.length,
                        itemBuilder: (context, index) {
                          final movie = bestThree[index];
                          return Card(
                            color: Colors.grey[900],
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    movie.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (movie.genres.isNotEmpty)
                                    Text(
                                      movie.genres.join(', '),
                                      style: const TextStyle(
                                        color: Colors.orangeAccent,
                                        fontSize: 18,
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Date de sortie: ${movie.releaseDate.day}/${movie.releaseDate.month}/${movie.releaseDate.year}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildStatItem(Icons.visibility, '${movie.views} vues'),
                                      _buildStatItem(Icons.favorite, '${movie.likes} j\'aime'),
                                      _buildStatItem(Icons.star, '${movie.rating.toStringAsFixed(1)} note'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, double padding, double iconSize, double valueFontSize, double titleFontSize) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: iconSize),
            SizedBox(height: padding / 2),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: valueFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: padding / 3),
            Text(
              title,
              style: TextStyle(
                color: Colors.white70,
                fontSize: titleFontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMovie() {
    return const Center(
      child: Text(
        'Ajouter un Film\n(Page à développer)',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.orangeAccent, size: 24),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _AddMovieFormWrapper extends StatefulWidget {
  @override
  State<_AddMovieFormWrapper> createState() => _AddMovieFormWrapperState();
}

class _AddMovieFormWrapperState extends State<_AddMovieFormWrapper> {
  bool _success = false;

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            const Text('Film ajouté avec succès !', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() => _success = false),
              child: const Text('Ajouter un autre film'),
            ),
          ],
        ),
      );
    }
    return DirectorMovieFormScreen(
      key: UniqueKey(),
      movie: null,
      // Quand le film est ajouté, afficher le message de succès
      // On utilise le Navigator.pop dans le formulaire, donc on peut intercepter le retour ici si besoin
    );
  }
}

class MinimalMovie {
  final String title;
  final int likes;
  final int views;
  final int favorites;
  final double? rating;
  final List<String> genres;
  final DateTime releaseDate;

  MinimalMovie({
    required this.title,
    required this.likes,
    required this.views,
    required this.favorites,
    this.rating,
    required this.genres,
    required this.releaseDate,
  });

  factory MinimalMovie.fromJson(Map<String, dynamic> json) => MinimalMovie(
    title: json['title'] ?? '',
    likes: json['likes'] ?? 0,
    views: json['views'] ?? 0,
    favorites: json['favorites'] ?? 0,
    rating: json['rating']?.toDouble(),
    genres: (json['genres'] ?? []).cast<String>(),
    releaseDate: DateTime.parse(json['release_date'] ?? DateTime.now().toIso8601String()),
  );

  factory MinimalMovie.fromMovie(Movie movie) => MinimalMovie(
    title: movie.title,
    likes: movie.likes ?? 0,
    views: movie.views ?? 0,
    favorites: movie.likes > 0 ? 1 : 0,
    rating: movie.rating,
    genres: movie.genres,
    releaseDate: movie.releaseDate,
  );
} 