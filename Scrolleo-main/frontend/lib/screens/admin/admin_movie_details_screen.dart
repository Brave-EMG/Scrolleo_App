import 'package:flutter/material.dart';
import '../../models/movie.dart';

class AdminMovieDetailsScreen extends StatelessWidget {
  final Movie movie;
  const AdminMovieDetailsScreen({Key? key, required this.movie}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails du film'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Text(movie.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            Text('Réalisateur : ${movie.director}', style: const TextStyle(color: Colors.white70)),
            Text('Année : ${movie.releaseDate.year}', style: const TextStyle(color: Colors.white70)),
            Text('Durée : ${movie.duration.inMinutes} min', style: const TextStyle(color: Colors.white70)),
            Text('Genres : ${movie.genres.join(", ")}', style: const TextStyle(color: Colors.white70)),
            Text('Note : ${movie.rating}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            Text('Description', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(movie.description, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 24),
            if (movie.posterUrl.isNotEmpty)
              Image.network(movie.posterUrl, height: 200),
          ],
        ),
      ),
    );
  }
} 