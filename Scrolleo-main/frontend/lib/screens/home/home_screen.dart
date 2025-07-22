import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/movie_service.dart';
import '../../theme/app_theme.dart';
import '../../models/movie.dart';
import '../../screens/video_player/video_player_screen.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/category_tabs.dart';
import '../../widgets/movie_section.dart';
import '../movie_details/movie_details_screen.dart';
import 'nouveaute_screen.dart';
import '../../services/like_service.dart';
import '../../services/auth_service.dart';
import '../../providers/likes_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/environment.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedCategoryIndex = 0;
  int _selectedClassementTab = 0;
  List<Movie> _searchResults = [];
  bool _isSearching = false;
  List<Movie> _popularMovies = [];
  List<Movie> _mostViewedMovies = [];
  List<Movie> _mostLikedMovies = [];
  List<Movie> _upcomingMovies = [];
  List<Movie> _recentlyAddedMovies = [];
  List<Movie> _discoveryMovies = [];
  List<Movie> _allMovies = [];
  bool _isLoading = true;
  String? _error;
  bool _isLoadingMostLiked = true;
  List<dynamic> exclusives = [];
  List<dynamic> veryRecent = [];
  List<dynamic> recent = [];
  List<dynamic> old = [];

  final List<String> _categories = [
    'Tous',
    'Exclusivités SCROLLEO',
    'Très récents',
    'Récents',
    'Anciens',
  ];
  final List<String> _classementTabs = [
    'Les plus vues',
    'Les plus aimées',
  ];

  // Ajout des genres pour la classification
  final List<String> _classificationGenres = [
    'Action',
    'Comédie',
    'Drame',
    'Science-Fiction',
    'Horreur',
    'Romance',
    'Documentaire',
    'Animation',
    'Thriller',
    'Aventure',
  ];
  int _selectedGenreIndex = 0;
  List<Movie> _classificationMovies = [];
  bool _isClassificationLoading = false;

  final Map<String, String> categoryEndpoints = {
    'Tous': '/movies/movies',
    'Exclusivités SCROLLEO': '/movies/exclusive',
    'Très récents': '/movies/recent',
    'Récents': '/movies/mid-old',
    'Anciens': '/movies/old',
  };

  String selectedCategory = 'Tous';
  String selectedGenre = 'Tous';
  List<String> genres = ['Tous'];
  List<dynamic> allMovies = [];
  List<dynamic> displayedMovies = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        selectedCategory = _categories[_tabController.index];
        fetchMoviesForCategory(selectedCategory);
      }
    });
    fetchMoviesForCategory(selectedCategory);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;
      if (userId != null) {
        Provider.of<LikesProvider>(context, listen: false).fetchUserLikes(userId);
      }
    });
    _loadMovies();
    fetchCategories();
  }

  Future<void> _loadMovies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    final movieService = Provider.of<MovieService>(context, listen: false);
    
    try {
      print('Chargement de tous les films...');
      final allMovies = await movieService.getMovies();
      print('Tous les films chargés: \\${allMovies.length}');

      print('Chargement des films recommandés...');
      final recommendedMovies = await movieService.fetchRecommendedMovies();
      print('Films recommandés chargés: \\${recommendedMovies.length}');

      print('Chargement des films découvertes...');
      final discoveryMovies = await movieService.fetchDiscoveryMovies();
      print('Films découvertes chargés: \\${discoveryMovies.length}');

      print('Chargement des films les plus vues...');
      final mostViewedMovies = await movieService.fetchMostViewedMovies();
      print('Films les plus vues chargés: \\${mostViewedMovies.length}');

      print('Chargement des films les plus aimés...');
      await _loadMostLikedMovies();

      print('Chargement des films à venir...');
      final upcomingMovies = await movieService.getUpcomingMovies();
      print('Films à venir chargés: \\${upcomingMovies.length}');

      print('Chargement des films récemment ajoutés...');
      final recentlyAddedMovies = await movieService.getRecentlyAddedMovies();
      print('Films récemment ajoutés chargés: \\${recentlyAddedMovies.length}');

      setState(() {
        _allMovies = allMovies;
        _popularMovies = allMovies.where((m) =>
            m.releaseDate.isBefore(DateTime.now()) ||
            m.releaseDate.isAtSameMomentAs(DateTime.now())).toList();
        _discoveryMovies = discoveryMovies;
        _mostViewedMovies = mostViewedMovies;
        _upcomingMovies = upcomingMovies;
        _recentlyAddedMovies = recentlyAddedMovies;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des films: $e');
      setState(() {
        _isLoading = false;
        _error = 'Erreur lors du chargement des films: $e';
      });
    }
  }

  Future<void> _loadMostLikedMovies() async {
    try {
      final movieService = Provider.of<MovieService>(context, listen: false);
      final movies = await movieService.fetchMostLikedMovies();
      setState(() {
        _mostLikedMovies = movies;
        _isLoadingMostLiked = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des films les plus aimés: $e');
      setState(() {
        _mostLikedMovies = [];
        _isLoadingMostLiked = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de charger les films les plus aimés'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearch(String query) async {
    final movieService = Provider.of<MovieService>(context, listen: false);
    
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = await movieService.searchMovies(query);
    
    setState(() {
      _searchResults = results;
    });
  }

  void _onCategorySelected(int index) {
    setState(() {
      _selectedCategoryIndex = index;
      _isSearching = false;
      _searchResults = [];
    });
  }

  void _onMovieTap(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailsScreen(movie: movie),
      ),
    );
  }

  Future<void> _fetchMoviesByGenre(String genre) async {
    setState(() {
      _isClassificationLoading = true;
    });
    try {
      final response = await http.get(Uri.parse('${Environment.apiBaseUrl}/movies/genre/${genre.toLowerCase()}'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data'] ?? [];
        final movies = data.map((e) => Movie.fromJson(e)).toList();
        setState(() {
          _classificationMovies = movies;
          _isClassificationLoading = false;
        });
      } else {
      setState(() {
          _classificationMovies = [];
        _isClassificationLoading = false;
      });
      }
    } catch (e) {
      setState(() {
        _classificationMovies = [];
        _isClassificationLoading = false;
      });
    }
  }

  void _toggleLike(Movie movie) async {
    final likesProvider = Provider.of<LikesProvider>(context, listen: false);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous devez être connecté pour liker un film'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      final isLiked = likesProvider.isLiked(movie.id.toString());
      if (isLiked) {
        likesProvider.unlike(movie.id.toString());
        await LikeService().unlikeMovie(userId, movie.id.toString());
      } else {
        likesProvider.like(movie.id.toString());
        await LikeService().likeMovie(userId, movie.id.toString());
      }
    } catch (e) {
      print('Erreur lors du like/unlike: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  List<Widget> _buildContent() {
    if (_isLoading) {
      return [
        const Center(
          child: CircularProgressIndicator(),
        ),
      ];
    }

    if (_error != null) {
      return [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Erreur',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMovies,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ];
    }
    
    if (_isSearching) {
      if (_searchResults.isEmpty) {
        return [
          const Center(
            child: Text('Aucun résultat trouvé', style: TextStyle(color: Colors.white70, fontSize: 18)),
          ),
        ];
      }
      final likesProvider = Provider.of<LikesProvider>(context);
      return [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _searchResults.length,
          separatorBuilder: (context, index) => const Divider(color: Colors.white24),
          itemBuilder: (context, index) {
            final movie = _searchResults[index];
            return MovieCard(
              movie: movie,
              isLiked: likesProvider.isLiked(movie.id.toString()),
              onLikeToggle: () => _toggleLike(movie),
              onTap: () => _onMovieTap(movie),
            );
          },
        ),
      ];
    }
    
    switch (_categories[_selectedCategoryIndex]) {
      case 'Populaire':
        return [
          MovieSection(
            title: 'Tendance',
            movies: _mostViewedMovies,
            onMovieTap: _onMovieTap,
            showBadge: true,
            badgeText: 'Tendance',
            likedMovieIds: Provider.of<LikesProvider>(context).likedMovieIds,
            onLikeToggle: _toggleLike,
          ),
          MovieSection(
            title: 'Découvertes',
            movies: _discoveryMovies,
            onMovieTap: _onMovieTap,
            showBadge: true,
            badgeText: 'Découverte',
            likedMovieIds: Provider.of<LikesProvider>(context).likedMovieIds,
            onLikeToggle: _toggleLike,
          ),
          MovieSection(
            title: 'Films recommandés',
            movies: _mostLikedMovies,
            onMovieTap: _onMovieTap,
            showBadge: true,
            badgeText: 'Populaire',
            likedMovieIds: Provider.of<LikesProvider>(context).likedMovieIds,
            onLikeToggle: _toggleLike,
          ),
          MovieSection(
            title: 'Tous les films',
            movies: _popularMovies,
            onMovieTap: _onMovieTap,
            likedMovieIds: Provider.of<LikesProvider>(context).likedMovieIds,
            onLikeToggle: _toggleLike,
          ),
        ];
      case 'Nouveautés':
        return [
          MovieSection(
            title: 'Films à Venir',
            movies: _upcomingMovies,
            onMovieTap: _onMovieTap,
            showBadge: true,
            badgeText: 'SOON',
            likedMovieIds: Provider.of<LikesProvider>(context).likedMovieIds,
            onLikeToggle: _toggleLike,
          ),
          MovieSection(
            title: 'Nouveaux Films',
            movies: _recentlyAddedMovies,
            onMovieTap: _onMovieTap,
            showBadge: true,
            badgeText: 'NEW',
            likedMovieIds: Provider.of<LikesProvider>(context).likedMovieIds,
            onLikeToggle: _toggleLike,
          ),
        ];
      case 'Classement':
        List<Movie> classementMovies = _selectedClassementTab == 0 
            ? _mostViewedMovies 
            : _mostLikedMovies;
            
        return [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_classementTabs.length, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ChoiceChip(
                  label: Text(_classementTabs[i]),
                  selected: _selectedClassementTab == i,
                  onSelected: (selected) {
                    setState(() {
                      _selectedClassementTab = i;
                    });
                  },
                ),
              )),
            ),
          ),
          MovieSection(
            title: _classementTabs[_selectedClassementTab],
            movies: classementMovies,
            onMovieTap: _onMovieTap,
            likedMovieIds: Provider.of<LikesProvider>(context).likedMovieIds,
            onLikeToggle: _toggleLike,
          ),
        ];
      case 'Classification':
          return [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_classificationGenres.length, (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(_classificationGenres[i]),
                      selected: _selectedGenreIndex == i,
                      selectedColor: Colors.red[800],
                      backgroundColor: Colors.grey[900],
                      labelStyle: TextStyle(
                        color: _selectedGenreIndex == i ? Colors.white : Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                      shape: StadiumBorder(),
                      onSelected: (selected) {
                        setState(() {
                          _selectedGenreIndex = i;
                        });
                          _fetchMoviesByGenre(_classificationGenres[i]);
                      },
                    ),
                  )),
                ),
              ),
            ),
            _isClassificationLoading
                ? const Center(child: CircularProgressIndicator())
              : _classificationMovies.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'Aucun film trouvé pour ce genre.',
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      ),
                    )
                : MovieSection(
                      title: 'Films de \'${_classificationGenres[_selectedGenreIndex]}\'',
                    movies: _classificationMovies,
                    onMovieTap: _onMovieTap,
                    likedMovieIds: Provider.of<LikesProvider>(context).likedMovieIds,
                    onLikeToggle: _toggleLike,
                  ),
          ];
      default:
        return [
          MovieSection(
            title: 'Tous les Films',
            movies: _popularMovies,
            onMovieTap: _onMovieTap,
            likedMovieIds: Provider.of<LikesProvider>(context).likedMovieIds,
            onLikeToggle: _toggleLike,
          ),
        ];
    }
    return [];
  }

  Widget _buildHorizontalList(List<Movie> movies, {required bool isComingSoon}) {
    if (movies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Text(
          'Aucun film disponible',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: movies.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final movie = movies[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: () => _onMovieTap(movie),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 120,
                        height: 170,
                        color: Colors.grey[900],
                        child: MovieCard(
                          movie: movie,
                          onTap: () => _onMovieTap(movie),
                        ),
                      ),
                    ),
                  ),
                  if (isComingSoon)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Me rappeler',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (!isComingSoon)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 120,
                child: Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
              ),
              if (isComingSoon && movie.releaseDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    _formatDate(movie.releaseDate),
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    // Conversion en GMT+1
    final dateGmt1 = date.toUtc().add(const Duration(hours: 1));
    return "${dateGmt1.day.toString().padLeft(2, '0')} ${_monthName(dateGmt1.month)}";
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return months[month];
  }

  Widget _buildMovieGrid(List<Movie> movies, String title, {required bool isComingSoon}) {
    if (movies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Text(
          'Aucun film disponible',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }
    return SizedBox(
      height: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: List.generate(movies.length, (index) {
                final movie = movies[index];
                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _onMovieTap(movie),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.grey[900],
                          child: MovieCard(
                            movie: movie,
                            onTap: () => _onMovieTap(movie),
                          ),
                        ),
                      ),
                    ),
                    if (isComingSoon)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Me rappeler',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    if (!isComingSoon)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> fetchMoviesForCategory(String category) async {
    setState(() { _isLoading = true; });
    final endpoint = categoryEndpoints[category] ?? '/movies/movies';
    final url = '${Environment.apiBaseUrl}$endpoint';
    final response = await http.get(Uri.parse(url));
    print('API $url: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      allMovies = decoded is List ? decoded : (decoded['data'] ?? []);
      // Récupérer tous les genres présents dans les films
      final Set<String> foundGenres = {};
      for (var m in allMovies) {
        final genreField = m['genre']?.toString() ?? '';
        if (genreField.isNotEmpty) {
          foundGenres.addAll(genreField.split(',').map((g) => g.trim()));
        }
      }
      genres = ['Tous', ...foundGenres];
      selectedGenre = 'Tous';
      filterMoviesByGenre();
    } else {
      allMovies = [];
      displayedMovies = [];
      genres = ['Tous'];
      selectedGenre = 'Tous';
      setState(() {});
    }
    setState(() { _isLoading = false; });
  }

  void filterMoviesByGenre() {
    if (selectedGenre == 'Tous') {
      displayedMovies = allMovies;
    } else {
      displayedMovies = allMovies.where((movie) => movie['genre'] == selectedGenre).toList();
    }
    setState(() {});
  }

  Future<void> fetchMoviesByGenre(String genre) async {
    setState(() { _isLoading = true; });
    final url = '${Environment.apiBaseUrl}/movies/genre/${genre.toLowerCase()}';
    final response = await http.get(Uri.parse(url));
    print('API $url: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      allMovies = decoded is List ? decoded : (decoded['data'] ?? []);
      displayedMovies = allMovies;
    } else {
      allMovies = [];
      displayedMovies = [];
    }
    setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppTheme.mobileBreakpoint;
    final isTablet = screenWidth < AppTheme.tabletBreakpoint && screenWidth >= AppTheme.mobileBreakpoint;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Accueil',
          style: TextStyle(
            fontSize: isMobile ? 18.0 : 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 40.0 : 48.0),
          child: TabBar(
            controller: _tabController,
            tabs: _categories.map((cat) => Tab(
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: isMobile ? 12.0 : 14.0,
                ),
              ),
            )).toList(),
            indicatorColor: Colors.orange,
            labelStyle: TextStyle(
              fontSize: isMobile ? 12.0 : 14.0,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: isMobile ? 11.0 : 13.0,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Section de filtrage responsive
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12.0 : 16.0,
              vertical: isMobile ? 8.0 : 12.0,
            ),
            child: Row(
              children: [
                Text(
                  'Genre:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 14.0 : 16.0,
                  ),
                ),
                SizedBox(width: isMobile ? 8.0 : 12.0),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedGenre,
                    dropdownColor: Colors.grey[900],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 13.0 : 14.0,
                    ),
                    items: genres.map((g) => DropdownMenuItem(
                      value: g,
                      child: Text(
                        g,
                        style: TextStyle(
                          fontSize: isMobile ? 13.0 : 14.0,
                        ),
                      ),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() { selectedGenre = value; });
                        if (selectedGenre == 'Tous') {
                          fetchMoviesForCategory(selectedCategory);
                        } else {
                          fetchMoviesByGenre(selectedGenre);
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Contenu principal
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  )
                : buildMoviesGrid(displayedMovies),
          ),
        ],
      ),
    );
  }

  Widget buildMoviesGrid(List<dynamic> movies) {
    if (movies.isEmpty) {
      return const Center(
        child: Text('Aucun film trouvé', style: TextStyle(color: Colors.white70)),
      );
    }
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppTheme.mobileBreakpoint;
    final isTablet = screenWidth < AppTheme.tabletBreakpoint && screenWidth >= AppTheme.mobileBreakpoint;
    
    // Calcul des dimensions responsives
    final crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);
    final childAspectRatio = isMobile ? 0.65 : (isTablet ? 0.7 : 0.75);
    final crossAxisSpacing = isMobile ? 12.0 : 16.0;
    final mainAxisSpacing = isMobile ? 12.0 : 16.0;
    final padding = isMobile ? 12.0 : 16.0;
    
    return GridView.builder(
      padding: EdgeInsets.all(padding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movieData = movies[index];
        // Convertir les données JSON en objet Movie
        Movie movie;
        try {
          movie = Movie.fromJson(movieData);
        } catch (e) {
          print('Erreur lors de la conversion du film: $e');
          // Retourner un widget d'erreur si la conversion échoue
          return Card(
            color: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
            ),
            child: const Center(
              child: Text(
                'Erreur de chargement',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        
        return GestureDetector(
          onTap: () => _onMovieTap(movie),
          child: Card(
            color: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.mediumRadius),
                    ),
                    child: movie.posterUrl.isNotEmpty
                        ? Image.network(
                            movie.posterUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.movie,
                                  color: Colors.white54,
                                  size: 50,
                                ),
                              );
                            },
                          )
                        : Container(
                            width: double.infinity,
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.movie,
                              color: Colors.white54,
                              size: 50,
                            ),
                          ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 6.0 : 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 12.0 : 14.0,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (movie.genres.isNotEmpty) ...[
                          SizedBox(height: isMobile ? 2.0 : 4.0),
                          Text(
                            movie.genres.first,
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: isMobile ? 10.0 : 12.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${movie.views} vues',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: isMobile ? 8.0 : 10.0,
                              ),
                            ),
                            Text(
                              '${movie.likes} likes',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: isMobile ? 8.0 : 10.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> fetchCategories() async {
    exclusives = await fetchMoviesByCategory('/movies/exclusive');
    veryRecent = await fetchMoviesByCategory('/movies/recent');
    recent = await fetchMoviesByCategory('/movies/mid-old');
    old = await fetchMoviesByCategory('/movies/old');
    setState(() {});
  }

  Future<List<dynamic>> fetchMoviesByCategory(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('${Environment.apiBaseUrl}$endpoint'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        // Gérer les différents formats de réponse
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map<String, dynamic>) {
          // Si c'est un objet avec une clé 'data'
          if (decoded.containsKey('data')) {
            return decoded['data'] is List ? decoded['data'] : [];
          }
          // Si c'est un objet avec d'autres clés comme 'trending', 'discovery', etc.
          for (var key in ['trending', 'discovery', 'mostViewed', 'mostLiked']) {
            if (decoded.containsKey(key) && decoded[key] is List) {
              return decoded[key];
            }
          }
          // Si aucune clé connue n'est trouvée, retourner une liste vide
          return [];
        }
        return [];
      }
      return [];
    } catch (e) {
      print('Erreur dans fetchMoviesByCategory pour $endpoint: $e');
      return [];
    }
  }
} 