import 'package:flutter/material.dart';
//import '../../models/director.dart';
import '../../models/movie.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
//import '../../config/api_config.dart';
import '../../config/environment.dart';

class AdminDirectorMoviesScreen extends StatefulWidget {
  final int directorId;
  final String directorName;
  const AdminDirectorMoviesScreen({Key? key, required this.directorId, required this.directorName}) : super(key: key);

  @override
  State<AdminDirectorMoviesScreen> createState() => _AdminDirectorMoviesScreenState();
}

class _AdminDirectorMoviesScreenState extends State<AdminDirectorMoviesScreen> {
  List<Movie> _movies = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMovies();
  }

  Future<void> _fetchMovies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse('${Environment.apiBaseUrl}/movies/director/${widget.directorId}'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _movies = data.map((e) => Movie.fromJson(e)).toList();
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _movies = [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Erreur serveur: ${response.statusCode}';
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

  Future<void> _deleteMovie(String movieId) async {
    setState(() { _isLoading = true; });
    try {
      final response = await http.delete(Uri.parse('${Environment.apiBaseUrl}/movies/$movieId'));
      if (response.statusCode == 200) {
        await _fetchMovies();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Film supprimé avec succès'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression : \\${response.statusCode}'), backgroundColor: Colors.red),
        );
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur réseau : $e'), backgroundColor: Colors.red),
      );
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _showEditMovieDialog(Movie movie) async {
    final titleController = TextEditingController(text: movie.title);
    final descriptionController = TextEditingController(text: movie.description);
    DateTime selectedDate = movie.releaseDate;
    final genresController = TextEditingController(text: movie.genres.join(', '));
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Modifier le film', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Titre'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: genresController,
                decoration: const InputDecoration(labelText: 'Genres (séparés par des virgules)'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    selectedDate = picked;
                  }
                },
                child: Text('Date de sortie: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'title': titleController.text,
                'description': descriptionController.text,
                'release_date': selectedDate.toIso8601String(),
                'genre': genresController.text,
                'duration': movie.duration.inMinutes,
                'director_id': movie.directorId,
              };
              final response = await http.put(
                Uri.parse('${Environment.apiBaseUrl}/movies/${movie.id}'),
                headers: {'Content-Type': 'application/json'},
                body: json.encode(data),
              );
              if (response.statusCode == 200) {
                Navigator.pop(context);
                await _fetchMovies();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Film modifié avec succès'), backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur lors de la modification : ${response.statusCode}'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Films de ${widget.directorName}'),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange),
          tooltip: 'Retour aux réalisateurs',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : _movies.isEmpty
                    ? const Center(
                        child: Text('Aucun film pour ce réalisateur.', style: TextStyle(color: Colors.white)),
                      )
                    : ListView.separated(
                        itemCount: _movies.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final movie = _movies[index];
                          return Card(
                            color: Colors.grey[900],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (movie.posterUrl.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        movie.posterUrl,
                                        width: 80,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 80,
                                          height: 120,
                                          color: Colors.grey[800],
                                          child: const Icon(Icons.movie, color: Colors.white54, size: 40),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 80,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.movie, color: Colors.white54, size: 40),
                                    ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(movie.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text('Année : ${movie.releaseDate.year}', style: const TextStyle(color: Colors.white70)),
                                            const SizedBox(width: 16),
                                            Text('Durée : ${movie.duration.inMinutes} min', style: const TextStyle(color: Colors.white70)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (movie.genres.isNotEmpty)
                                          Wrap(
                                            spacing: 8,
                                            children: movie.genres.map((g) => Chip(
                                              label: Text(g, style: const TextStyle(color: Colors.white)),
                                              backgroundColor: Colors.deepPurple,
                                            )).toList(),
                                          ),
                                        if (movie.rating != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.star, color: Colors.amber, size: 20),
                                                const SizedBox(width: 4),
                                                Text('\\${movie.rating}', style: const TextStyle(color: Colors.white)),
                                              ],
                                            ),
                                          ),
                                        if (movie.description.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              movie.description.length > 120
                                                ? '${movie.description.substring(0, 120)}...'
                                                : movie.description,
                                              style: const TextStyle(color: Colors.white54),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        tooltip: 'Modifier',
                                        onPressed: () async {
                                          await _showEditMovieDialog(movie);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        tooltip: 'Supprimer',
                                        onPressed: () async {
                                          await _deleteMovie(movie.id.toString());
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
} 