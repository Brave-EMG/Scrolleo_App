import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:dotenv/dotenv.dart';

import '../config/database_config.dart';

void main() async {
  // Charger les variables d'environnement
  final env = DotEnv(includePlatformEnvironment: true)..load();

  // Initialiser la base de données
  final dbConfig = DatabaseConfig();
  await dbConfig.initialize();

  // Créer le routeur
  final router = Router();

  // Configuration CORS
  final handler = Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addHandler(router);

  // Démarrer le serveur
  final server = await io.serve(
    handler,
    env['HOST'] ?? '0.0.0.0',
    int.parse(env['PORT'] ?? '8080'),
  );

  print('Serveur démarré sur ${server.address}:${server.port}');

  // Gérer l'arrêt propre du serveur
  await ProcessSignal.sigint.watch().first;
  await dbConfig.close();
  await server.close();
} 