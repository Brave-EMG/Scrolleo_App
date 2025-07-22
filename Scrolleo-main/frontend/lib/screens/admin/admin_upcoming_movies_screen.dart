import 'package:flutter/material.dart';
import '../../models/director.dart';
import '../../models/movie.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/app_date_utils.dart';
import '../../config/api_config.dart';
import '../../config/environment.dart';

class AdminUpcomingMoviesScreen extends StatefulWidget {
  const AdminUpcomingMoviesScreen({Key? key}) : super(key: key);

  @override
  State<AdminUpcomingMoviesScreen> createState() => _AdminUpcomingMoviesScreenState();
}

class _AdminUpcomingMoviesScreenState extends State<AdminUpcomingMoviesScreen> {
  List<Map<String, dynamic>> _directors = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _selectedDirector;
  List<Movie> _upcomingMovies = [];
  List<Movie> _allUpcomingMovies = [];
  String _searchQuery = '';
  List<Movie> _filteredUpcomingMovies = [];
  List<Movie> _filteredAllUpcomingMovies = [];

  @override
  void initState() {
    super.initState();
    _fetchAllUpcomingMovies();
    _fetchDirectors();
  }

  void _filterMovies() {
    final query = _searchQuery.toLowerCase();
    if (_selectedDirector != null) {
      _filteredUpcomingMovies = _upcomingMovies.where((movie) {
        return movie.title.toLowerCase().contains(query) ||
               movie.genres.any((genre) => genre.toLowerCase().contains(query));
      }).toList();
    } else {
      _filteredAllUpcomingMovies = _allUpcomingMovies.where((movie) {
        return movie.title.toLowerCase().contains(query) ||
               movie.genres.any((genre) => genre.toLowerCase().contains(query)) ||
               movie.director.toLowerCase().contains(query);
      }).toList();
    }
  }

  Future<void> _fetchDirectors() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await http.get(Uri.parse('${Environment.apiBaseUrl}/auth/users/realisateurs'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _directors = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Erreur serveur: ${response.statusCode}'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Erreur réseau: $e'; _isLoading = false; });
    }
  }

  Future<void> _fetchUpcomingMovies(String directorId) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await http.get(Uri.parse('${Environment.apiBaseUrl}/movies/director/$directorId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final now = DateTime.now();
        setState(() {
          _upcomingMovies = data.map((e) => Movie.fromJson(e)).where((m) => m.releaseDate.isAfter(now)).toList();
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Erreur serveur: ${response.statusCode}'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Erreur réseau: $e'; _isLoading = false; });
    }
  }

  Future<void> _fetchAllUpcomingMovies() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await http.get(Uri.parse('${Environment.apiBaseUrl}/movies/upcoming'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _allUpcomingMovies = data.map((e) => Movie.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        print('Erreur serveur: ${response.statusCode}');
        //setState(() { _error = 'Erreur serveur: ${response.statusCode}'; _isLoading = false; });
      }
    } catch (e) {
      print('Erreur réseau: $e');
      //setState(() { _error = 'Erreur réseau: $e'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBar(
                  title: const Text('Films à venir'),
                  backgroundColor: Colors.black,
                  automaticallyImplyLeading: false,
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: Colors.orange))
                else if (_error != null)
                  Center(
                    child: Column(
                      children: [
                        Text('Erreur: ${_error}', style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchAllUpcomingMovies,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                else if (_selectedDirector == null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Choisissez un réalisateur pour voir ses films à venir :', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                      const SizedBox(height: 24),
                      _directors.isEmpty
                        ? const Center(child: Text('Aucun réalisateur trouvé.', style: TextStyle(color: Colors.white70)))
                        : Wrap(
                            spacing: 24,
                            runSpacing: 24,
                            children: _directors.map((d) => GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDirector = d;
                                });
                                _fetchUpcomingMovies(d['user_id'].toString());
                              },
                              child: Card(
                                color: Colors.grey[900],
                                elevation: 6,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Container(
                                  width: 260,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.orange,
                                        child: Text((d['username'] ?? d['email'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(d['username'] ?? d['email'] ?? 'Inconnu', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                            Text(d['email'] ?? '', style: const TextStyle(color: Colors.white70)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )).toList(),
                          ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.orange),
                            onPressed: () {
                              setState(() {
                                _selectedDirector = null;
                                _upcomingMovies = [];
                              });
                            },
                          ),
                          Text('Films à venir de ${_selectedDirector!['username'] ?? _selectedDirector!['email']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _upcomingMovies.isEmpty
                        ? const Center(child: Text('Aucun film à venir pour ce réalisateur.', style: TextStyle(color: Colors.white70)))
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _upcomingMovies.length,
                            itemBuilder: (context, index) {
                              final movie = _upcomingMovies[index];
                              return Card(
                                color: Colors.grey[900],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 8,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        if (movie.posterUrl.isNotEmpty)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              movie.posterUrl,
                                              height: 120,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                height: 120,
                                                color: Colors.grey[800],
                                                child: const Center(child: Icon(Icons.movie, color: Colors.white38, size: 40)),
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 10),
                                        Text(
                                          movie.title,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today, color: Colors.orange, size: 18),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Sortie : ' + AppDateUtils.formatLongDate(movie.releaseDate),
                                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.timer, color: Colors.blue, size: 18),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Durée : ${movie.duration.inMinutes} min',
                                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        if (movie.genres.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.category, color: Colors.green, size: 18),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  movie.genres.join(', '),
                                                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                    ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 