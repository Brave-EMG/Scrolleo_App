import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/screens/director_videos_screen.dart';
import '../../lib/services/director_service.dart';
import '../../lib/services/movie_service.dart';
import '../../lib/models/director.dart';
import '../../lib/widgets/video_player.dart';

void main() {
  late DirectorService directorService;
  late MovieService movieService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    movieService = MovieService();
    directorService = DirectorService(movieService);
  });

  testWidgets('Affichage des vidéos d\'un réalisateur', (WidgetTester tester) async {
    final director = Director(
      id: '1',
      name: 'Test Director',
      bio: 'Test Bio',
      movieIds: [],
      videoUrls: ['https://example.com/video1.mp4', 'https://example.com/video2.mp4'],
      createdAt: DateTime.now(),
      isAdmin: true,
    );

    await directorService.addDirector(director);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<DirectorService>.value(
          value: directorService,
          child: DirectorVideosScreen(directorId: '1'),
        ),
      ),
    );

    // Vérifier que le titre est affiché
    expect(find.text('Vidéos du Réalisateur'), findsOneWidget);

    // Vérifier que les vidéos sont affichées
    expect(find.byType(VideoPlayer), findsNWidgets(2));

    // Vérifier que le bouton d'ajout est visible pour l'admin
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('Ajout d\'une nouvelle vidéo', (WidgetTester tester) async {
    final director = Director(
      id: '1',
      name: 'Test Director',
      bio: 'Test Bio',
      movieIds: [],
      createdAt: DateTime.now(),
      isAdmin: true,
    );

    await directorService.addDirector(director);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<DirectorService>.value(
          value: directorService,
          child: DirectorVideosScreen(directorId: '1'),
        ),
      ),
    );

    // Entrer une nouvelle URL de vidéo
    await tester.enterText(find.byType(TextField), 'https://example.com/new-video.mp4');
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();

    // Vérifier que la vidéo a été ajoutée
    expect(directorService.getDirectorVideos('1'), contains('https://example.com/new-video.mp4'));
  });
} 