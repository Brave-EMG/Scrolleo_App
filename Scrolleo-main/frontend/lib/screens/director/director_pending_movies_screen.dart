import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/movie.dart';
import '../../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'director_movie_form_screen.dart';
import '../../config/api_config.dart';
import '../../config/environment.dart';

class DirectorPendingMoviesScreen extends StatefulWidget {
  const DirectorPendingMoviesScreen({Key? key}) : super(key: key);

  @override
  State<DirectorPendingMoviesScreen> createState() => _DirectorPendingMoviesScreenState();
}

class _DirectorPendingMoviesScreenState extends State<DirectorPendingMoviesScreen> {
  List<Movie> pendingMovies = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPendingMovies();
  }

  Future<void> _fetchPendingMovies() async {
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
      final response = await http.get(Uri.parse('${Environment.apiBaseUrl}/movies/Pending'));
      print('Réponse films en attente (status: ${response.statusCode}): ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Movie> allMovies = data.map((e) => Movie.fromJson(e)).toList();
        final userMovies = allMovies.where((movie) => movie.directorId == user.id).toList();
        setState(() {
          pendingMovies = userMovies;
          _isLoading = false;
          _error = null;
        });
      } else if (response.statusCode == 404) {
        // Aucun film en attente, pas d'erreur bloquante
        setState(() {
          pendingMovies = [];
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _error = 'Erreur lors de la récupération des films en attente: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la récupération des films en attente: $e';
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
              children: [
                Expanded(
                  child: const Text(
                    'Films en attente',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _fetchPendingMovies,
                  icon: const Icon(Icons.refresh, size: 24),
                  label: const Text('Rafraîchir', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            if (!_isLoading && pendingMovies.isEmpty)
              const Center(
                child: Text(
                  'Aucun film en attente',
                  style: TextStyle(color: Colors.white70, fontSize: 20),
                ),
              ),
            if (!_isLoading && pendingMovies.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pendingMovies.length,
                itemBuilder: (context, index) {
                  final movie = pendingMovies[index];
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
                            Text(
                              movie.genres.join(', '),
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 18,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            'Date de création : '
                            '${movie.createdAt != null ? '${movie.createdAt!.toLocal().day}/${movie.createdAt!.toLocal().month}/${movie.createdAt!.toLocal().year}' : 'N/A'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
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