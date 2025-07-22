import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/director_service.dart';
import '../../lib/services/movie_service.dart';
import '../../lib/models/director.dart';

void main() {
  late DirectorService directorService;
  late MovieService movieService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    movieService = MovieService();
    directorService = DirectorService(movieService);
  });

  test('Ajout et récupération de vidéos', () async {
    // Créer un réalisateur
    final director = Director(
      id: '1',
      name: 'Test Director',
      bio: 'Test Bio',
      movieIds: [],
      createdAt: DateTime.now(),
    );

    // Ajouter le réalisateur
    await directorService.addDirector(director);

    // Ajouter une vidéo
    await directorService.addVideoToDirector('1', 'https://example.com/video.mp4');

    // Vérifier que la vidéo a été ajoutée
    final videos = directorService.getDirectorVideos('1');
    expect(videos.length, 1);
    expect(videos.first, 'https://example.com/video.mp4');

    // Supprimer la vidéo
    await directorService.removeVideoFromDirector('1', 'https://example.com/video.mp4');

    // Vérifier que la vidéo a été supprimée
    final videosAfterRemoval = directorService.getDirectorVideos('1');
    expect(videosAfterRemoval, isEmpty);
  });
} 