import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/movie_service.dart';
import '../../lib/models/movie.dart';

void main() {
  late MovieService movieService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    movieService = MovieService();
  });

  group('MovieService', () {
    test('Ajout et récupération de film', () async {
      // Création d'un film
      final movie = Movie(
        id: '1',
        title: 'Test Movie',
        description: 'Description du film test',
        videoUrl: 'https://example.com/video.mp4',
        posterUrl: 'https://example.com/poster.jpg',
        backdropUrl: 'https://example.com/backdrop.jpg',
        releaseDate: DateTime.now(),
        rating: 4.5,
        duration: 120,
        genres: ['Action', 'Aventure'],
        views: 0,
        likes: 0,
        directorId: 'director1',
      );

      // Ajout du film
      await movieService.addMovie(movie);

      // Récupération du film
      final retrievedMovie = await movieService.getMovieById('1');
      expect(retrievedMovie, isNotNull);
      expect(retrievedMovie!.title, 'Test Movie');
      expect(retrievedMovie.description, 'Description du film test');
    });

    test('Mise à jour de film', () async {
      // Création d'un film
      final movie = Movie(
        id: '2',
        title: 'Original Title',
        description: 'Original Description',
        videoUrl: 'https://example.com/video.mp4',
        posterUrl: 'https://example.com/poster.jpg',
        backdropUrl: 'https://example.com/backdrop.jpg',
        releaseDate: DateTime.now(),
        rating: 3.0,
        duration: 90,
        genres: ['Drame'],
        views: 0,
        likes: 0,
        directorId: 'director1',
      );

      await movieService.addMovie(movie);

      // Mise à jour du film
      final updatedMovie = movie.copyWith(
        title: 'Updated Title',
        description: 'Updated Description',
      );
      await movieService.updateMovie(updatedMovie);

      // Vérification de la mise à jour
      final retrievedMovie = await movieService.getMovieById('2');
      expect(retrievedMovie!.title, 'Updated Title');
      expect(retrievedMovie.description, 'Updated Description');
    });

    test('Suppression de film', () async {
      // Création d'un film
      final movie = Movie(
        id: '3',
        title: 'Movie to Delete',
        description: 'Description',
        videoUrl: 'https://example.com/video.mp4',
        posterUrl: 'https://example.com/poster.jpg',
        backdropUrl: 'https://example.com/backdrop.jpg',
        releaseDate: DateTime.now(),
        rating: 4.0,
        duration: 100,
        genres: ['Comédie'],
        views: 0,
        likes: 0,
        directorId: 'director1',
      );

      await movieService.addMovie(movie);

      // Suppression du film
      await movieService.deleteMovie('3');

      // Vérification de la suppression
      final retrievedMovie = await movieService.getMovieById('3');
      expect(retrievedMovie, isNull);
    });

    test('Recherche de films', () async {
      // Création de plusieurs films
      final movies = [
        Movie(
          id: '4',
          title: 'Action Movie',
          description: 'Film d\'action',
          videoUrl: 'https://example.com/video1.mp4',
          posterUrl: 'https://example.com/poster1.jpg',
          backdropUrl: 'https://example.com/backdrop1.jpg',
          releaseDate: DateTime.now(),
          rating: 4.5,
          duration: 120,
          genres: ['Action'],
          views: 0,
          likes: 0,
          directorId: 'director1',
        ),
        Movie(
          id: '5',
          title: 'Comedy Film',
          description: 'Film comique',
          videoUrl: 'https://example.com/video2.mp4',
          posterUrl: 'https://example.com/poster2.jpg',
          backdropUrl: 'https://example.com/backdrop2.jpg',
          releaseDate: DateTime.now(),
          rating: 3.5,
          duration: 90,
          genres: ['Comédie'],
          views: 0,
          likes: 0,
          directorId: 'director2',
        ),
      ];

      for (final movie in movies) {
        await movieService.addMovie(movie);
      }

      // Recherche par titre
      final searchResults = await movieService.searchMovies('Action');
      expect(searchResults.length, 1);
      expect(searchResults[0].title, 'Action Movie');

      // Recherche par description
      final searchResults2 = await movieService.searchMovies('comique');
      expect(searchResults2.length, 1);
      expect(searchResults2[0].title, 'Comedy Film');
    });
  });
} 