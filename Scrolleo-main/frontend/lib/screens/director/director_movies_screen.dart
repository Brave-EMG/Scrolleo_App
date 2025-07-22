import 'package:flutter/material.dart';
import '../../models/movie.dart';
import 'director_movie_form_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:streaming_platform/services/auth_service.dart';
import 'director_episodes_screen.dart';
import '../../config/environment.dart';
import '../../config/api_config.dart';

class DirectorMoviesScreen extends StatefulWidget {
  final VoidCallback? onMoviesChanged;
  const DirectorMoviesScreen({Key? key, this.onMoviesChanged}) : super(key: key);

  @override
  State<DirectorMoviesScreen> createState() => _DirectorMoviesScreenState();
}

class _DirectorMoviesScreenState extends State<DirectorMoviesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Movie> movies = [];
  String _search = '';
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchApprovedMovies();
  }

  Future<void> _fetchApprovedMovies() async {
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
        final List<Movie> myMovies = data.map((e) => Movie.fromJson(e)).toList();
        print('DATA BACKEND: ' + data.toString());
        setState(() {
          movies = myMovies;
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        // Aucun film trouvé
        setState(() {
          movies = [];
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _error = 'Erreur lors de la récupération des films approuvés';
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

  Future<void> _deleteMovie(Movie movie) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Supprimer le film', style: TextStyle(color: Colors.white)),
        content: Text('Voulez-vous vraiment supprimer "${movie.title}" ?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.orange)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() { _isLoading = true; });
      try {
        final response = await http.delete(Uri.parse('${Environment.apiBaseUrl}/movies/${movie.id}'));
        if (response.statusCode == 200) {
          await _fetchApprovedMovies();
          // Notifier le parent que les films ont changé
          widget.onMoviesChanged?.call();
        } else {
          setState(() { _error = 'Erreur lors de la suppression du film (${response.statusCode})'; });
        }
      } catch (e) {
        setState(() { _error = 'Erreur réseau lors de la suppression: $e'; });
      } finally {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final filteredMovies = movies.where((m) {
      final passes =
          m.title.toLowerCase().contains(_search.toLowerCase()) &&
          m.status == 'approved' &&
          !m.releaseDate.isAfter(now);

      print('[DEBUG MES FILMS] ${m.title} | status: ${m.status} | sortie: ${m.releaseDate.toLocal()} | passe: $passes');
      return passes;
    }).toList();

    print('[DEBUG MES FILMS] Titres affichés : ${filteredMovies.map((m) => m.title).toList()}');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un film...',
                    hintStyle: TextStyle(fontSize: 18),
                    prefixIcon: const Icon(Icons.search, size: 24),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  onChanged: (value) {
                    setState(() {
                      _search = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _fetchApprovedMovies,
                icon: const Icon(Icons.refresh, size: 24),
                label: const Text('Rafraîchir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.orange)),
          if (_error != null)
            Center(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 20))),
          if (!_isLoading && filteredMovies.isEmpty)
            const Center(child: Text('Aucun film approuvé', style: TextStyle(color: Colors.white, fontSize: 20))),
          if (!_isLoading && filteredMovies.isNotEmpty)
          Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  final crossAxisCount = isWide ? 2 : 1;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: isWide ? 2.2 : 1.7,
                    ),
                    itemCount: filteredMovies.length,
                    itemBuilder: (context, idx) {
                      final m = filteredMovies[idx];
                      print('GENRES FRONT (${m.title}): ' + m.genres.toString());
                      return Card(
                    color: Colors.grey[900],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: (m.posterUrl.isNotEmpty)
                                  ? Image.network(
                                      m.posterUrl.startsWith('http') ? m.posterUrl : Environment.apiBaseUrl.replaceAll('/api','') + m.posterUrl,
                                      width: 120,
                                      height: 160,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 120,
                                        height: 160,
                                        color: Colors.grey[800],
                                        child: const Icon(Icons.movie, color: Colors.white54, size: 48),
                              ),
                                    )
                                  : Container(
                                      width: 120,
                                      height: 160,
                                      color: Colors.blue,
                                      child: const Icon(Icons.movie, color: Colors.white, size: 48),
                                    ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                    Text(m.title, 
                                      style: const TextStyle(
                                        color: Colors.white, 
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 22,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                ),
                                    if (m.genres != null && m.genres.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                                        child: Text(
                                          m.genres.join(', '), 
                                          style: const TextStyle(
                                            color: Colors.orangeAccent, 
                                            fontSize: 18,
                                          )
                                        ),
                                      ),
                                    Text(
                                      (m.genres != null && m.genres.isNotEmpty)
                                        ? m.genres.join(', ')
                                        : '',
                                      style: const TextStyle(color: Colors.orangeAccent, fontSize: 18),
                                      ),
                                    Text(
                                      '${m.releaseDate.toLocal().day}/${m.releaseDate.toLocal().month}/${m.releaseDate.toLocal().year}', 
                                      style: const TextStyle(
                                        color: Colors.white70, 
                                        fontSize: 18,
                                      )
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.visibility, color: Colors.orange, size: 22),
                                        const SizedBox(width: 4),
                                        Text('${m.views}', 
                                          style: const TextStyle(
                                            color: Colors.white70, 
                                            fontSize: 17,
                                          )
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.favorite, color: Colors.red, size: 22),
                                        const SizedBox(width: 4),
                                        Text('${m.likes}', 
                                          style: const TextStyle(
                                            color: Colors.white70, 
                                            fontSize: 17,
                                          )
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.people, color: Colors.blue, size: 22),
                                        const SizedBox(width: 4),
                                        Text('${m.subscribers}', 
                                          style: const TextStyle(
                                            color: Colors.white70, 
                                            fontSize: 17,
                                          )
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.video_library, color: Colors.green, size: 22),
                                        const SizedBox(width: 4),
                                        Text('${m.episodes.length}', 
                                          style: const TextStyle(
                                            color: Colors.white70, 
                                            fontSize: 17,
                                          )
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Wrap(
                                      alignment: WrapAlignment.end,
                                      spacing: 12,
                                      runSpacing: 8,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () => _showMovieDetails(m),
                                          icon: const Icon(Icons.info, color: Colors.white, size: 20),
                                          label: const Text('Détails', 
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            )
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          ),
                                          ),
                                        ],
                                      ),
                                  ],
            ),
          ),
        ],
      ),
                        ),
                      );
                    },
                  );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMovieDetails(Movie movie) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[900],
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: BoxConstraints(
            maxWidth: 800,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                      Row(
                        children: [
                          Text('Détails du film', 
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32, // Increased from 28 to 32
                              fontWeight: FontWeight.bold
                            )
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 24), // Specified size
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (movie.posterUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            movie.posterUrl.startsWith('http') ? movie.posterUrl : Environment.apiBaseUrl.replaceAll('/api','') + movie.posterUrl,
                            height: 400, // Increased from 300 to 400
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 400, // Match with image height
                              color: Colors.grey[800],
                              child: Icon(Icons.movie, color: Colors.white54, size: 72), // Increased icon size
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text('Titre : ${movie.title}', 
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold) // Increased from 22 to 26
                      ),
                      const SizedBox(height: 16),
                      Text('Genre : ${movie.genres.join(", ")}', 
                        style: TextStyle(color: Colors.orangeAccent, fontSize: 22) // Increased from 18 to 22
                      ),
                      const SizedBox(height: 16),
                      Text('Date de sortie: ${movie.releaseDate.day}/${movie.releaseDate.month}/${movie.releaseDate.year}', 
                        style: TextStyle(color: Colors.white70, fontSize: 22) // Increased from 18 to 22
                      ),
                      const SizedBox(height: 16),
                      Text('Description :', 
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold) // Increased from 18 to 22
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: 200, // Limite la hauteur de la description
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            movie.description,
                            style: TextStyle(color: Colors.white70, fontSize: 22),
                  ),
                ),
              ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Icon(Icons.visibility, color: Colors.orange, size: 32), // Increased icon size
                          const SizedBox(width: 8),
                          Text('${movie.views} vues', 
                            style: TextStyle(color: Colors.white, fontSize: 22) // Increased from 18 to 22
                          ),
                          const SizedBox(width: 24),
                          Icon(Icons.favorite, color: Colors.red, size: 32), // Increased icon size
                          const SizedBox(width: 8),
                          Text('${movie.likes} likes', 
                            style: TextStyle(color: Colors.white, fontSize: 22) // Increased from 18 to 22
                          ),
                          const SizedBox(width: 24),
                          Icon(Icons.video_library, color: Colors.green, size: 32), // Increased icon size
            const SizedBox(width: 8),
                          Text('${movie.episodes.length} épisodes', 
                            style: TextStyle(color: Colors.white, fontSize: 22) // Increased from 18 to 22
            ),
          ],
        ),
      ],
                  ),
                ),
                const Divider(color: Colors.white24),
                Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
          children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Fermer', 
                          style: TextStyle(color: Colors.white70, fontSize: 22) // Increased from 18 to 22
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DirectorMovieFormScreen(movie: movie),
                            ),
                          );
                          if (result == true) {
                            _fetchApprovedMovies(); // Rafraîchir la liste après modification
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16), // Increased padding
                        ),
                        child: Text('Modifier', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), // Increased from 18 to 22
                      ),
          ],
        ),
      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 