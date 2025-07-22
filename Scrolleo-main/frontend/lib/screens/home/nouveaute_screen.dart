import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/movie_card.dart';
import '../../models/movie.dart';
import '../../providers/favorites_provider.dart';
import '../../services/movie_service.dart';
import '../movie_details/movie_details_screen.dart';
import '../../utils/app_date_utils.dart';

class NouveauteScreen extends StatefulWidget {
  const NouveauteScreen({Key? key}) : super(key: key);

  @override
  State<NouveauteScreen> createState() => _NouveauteScreenState();
}

class _NouveauteScreenState extends State<NouveauteScreen> {
  List<Movie> _upcomingMovies = [];
  List<Movie> _recentlyAddedMovies = [];
  bool _isLoading = true;
  String? _error;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final movieService = Provider.of<MovieService>(context, listen: false);
      
      print('Chargement des films à venir...');
      final upcomingMovies = await movieService.getUpcomingMovies();
      print('Films à venir chargés: ${upcomingMovies.length}');

      print('Chargement des films récemment ajoutés...');
      final recentlyAddedMovies = await movieService.getRecentlyAddedMovies();
      print('Films récemment ajoutés chargés: ${recentlyAddedMovies.length}');

      setState(() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveautés'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Coming Soon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Films à Venir',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Recevez un rappel avant la sortie !",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              _buildHorizontalList(_upcomingMovies, isComingSoon: true),
              const SizedBox(height: 18),
              // Section New Release
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: const Text(
                  'Nouveaux Films',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              _buildHorizontalList(_recentlyAddedMovies, isComingSoon: false),
            ],
          ),
        ),
      ),
    );
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MovieDetailsScreen(movie: movie),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 120,
                        height: 170,
                        color: Colors.grey[900],
                        child: MovieCard(
                          movie: movie,
                          onTap: null,
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
                    AppDateUtils.formatLongDate(movie.releaseDate),
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
    return AppDateUtils.formatShortDate(date);
  }

  String _monthName(int month) {
    return AppDateUtils.getMonthName(month);
  }
} 