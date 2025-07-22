import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/movie.dart';
import 'package:provider/provider.dart';
import 'package:streaming_platform/services/auth_service.dart';
import 'package:streaming_platform/screens/director/director_movie_form_screen.dart';
import '../../config/environment.dart';
import '../../config/api_config.dart';

class DirectorUpcomingMoviesScreen extends StatefulWidget {
  const DirectorUpcomingMoviesScreen({Key? key}) : super(key: key);

  @override
  State<DirectorUpcomingMoviesScreen> createState() => _DirectorUpcomingMoviesScreenState();
}

class _DirectorUpcomingMoviesScreenState extends State<DirectorUpcomingMoviesScreen> {
  List<Movie> upcomingMovies = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingMovies();
  }

  Future<void> _fetchUpcomingMovies() async {
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

      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/stats/${user.id}/upcoming-movies'),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        // Si la réponse est un objet avec un champ data (cas { message, data: [] })
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          final List<dynamic> data = decoded['data'];
          if (data.isEmpty) {
            setState(() {
              upcomingMovies = [];
              _isLoading = false;
              _error = null;
            });
            return;
          } else {
            final List<Movie> movies = data.map((e) => Movie.fromJson(e)).toList();
            final now = DateTime.now();
            final List<Movie> upcoming = movies.where((m) =>
                m.status == 'approved' &&
                m.releaseDate.isAfter(now)).toList();
            setState(() {
              upcomingMovies = upcoming;
              _isLoading = false;
              _error = null;
            });
            return;
          }
        }
        // Sinon, on suppose que c'est une liste brute (ancienne version API)
        if (decoded is List) {
          final List<Movie> movies = decoded.map((e) => Movie.fromJson(e)).toList();
          final now = DateTime.now();
          final List<Movie> upcoming = movies.where((m) =>
              m.status == 'approved' &&
              m.releaseDate.isAfter(now)).toList();
          setState(() {
            upcomingMovies = upcoming;
            _isLoading = false;
            _error = null;
          });
          return;
        }
        // Cas inattendu
        setState(() {
          _error = 'Format de réponse inattendu';
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        // Aucun film à venir, pas d'erreur bloquante
        setState(() {
          upcomingMovies = [];
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          print('Erreur lors de la récupération des films à venir: ${response.statusCode}');
          //error = 'Erreur lors de la récupération des films à venir: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur réseau: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Films à venir',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _fetchUpcomingMovies,
                  icon: const Icon(Icons.refresh, size: 24),
                  label: const Text('Rafraîchir', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.orange)),
            if (_error != null)
              Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 18),
                ),
              ),
            if (!_isLoading && upcomingMovies.isEmpty)
              const Center(
                child: Text(
                  'Aucun film à venir',
                  style: TextStyle(color: Colors.white70, fontSize: 20),
                ),
              ),
            if (!_isLoading && upcomingMovies.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: upcomingMovies.length,
                itemBuilder: (context, index) {
                  final movie = upcomingMovies[index];
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (movie.posterUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    movie.posterUrl.startsWith('http')
                                        ? movie.posterUrl
                                        : Environment.apiBaseUrl.replaceAll('/api','') + movie.posterUrl,
                                    width: 120,
                                    height: 180,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      width: 120,
                                      height: 180,
                                      color: Colors.grey[800],
                                      child: const Icon(Icons.movie,
                                          color: Colors.white54, size: 48),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 16),
                              Expanded(
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
                                      Text(
                                        movie.genres.join(', '),
                                        style: const TextStyle(
                                          color: Colors.orangeAccent,
                                          fontSize: 18,
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Date de sortie prévue: ${movie.releaseDate.day}/${movie.releaseDate.month}/${movie.releaseDate.year}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Description :',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      movie.description,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DirectorMovieFormScreen(movie: movie),
                                            ),
                                          );
                                          if (result == true) {
                                            _fetchUpcomingMovies();
                                          }
                                        },
                                        icon: const Icon(Icons.edit, color: Colors.white),
                                        label: const Text('Modifier'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
      ),
    );
  }
} 