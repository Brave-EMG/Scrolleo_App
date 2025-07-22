import '../config/environment.dart';

class Episode {
  final int id;
  final int movieId;
  final String title;
  final String description;
  final String videoUrl;
  final bool isFavorite;
  final int views;
  final int likes;
  final int comments;

  static String get baseUrl => Environment.apiBaseUrl;

  Episode({
    required this.id,
    required this.movieId,
    required this.title,
    required this.description,
    required this.videoUrl,
    this.isFavorite = false,
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    final url = json['videoUrl'] ?? json['video_url'] ?? json['path'] ?? '';
    print('[Episode.fromJson] URL vidéo récupérée : ' + url.toString());
    return Episode(
      id: json['id'] ?? json['episode_id'],
      movieId: json['movie_id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      videoUrl: url,
      isFavorite: json['is_favorite'] ?? false,
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
    );
  }

  // Utilitaire pour créer un Episode à partir de la réponse complète (episode + uploads)
  static Episode fromApiResponse(Map<String, dynamic> apiResponse) {
    final episodeJson = apiResponse['episode'] ?? {};
    String? videoUrl;
    if (apiResponse['uploads'] is List && (apiResponse['uploads'] as List).isNotEmpty) {
      final videoUpload = (apiResponse['uploads'] as List)
          .firstWhere((u) => u['type'] == 'video' && u['status'] == 'completed' && u['path'] != null,
              orElse: () => {'path': ''});
      if (videoUpload['path'] != null) {
        final basePath = videoUpload['path'].startsWith('http') 
            ? videoUpload['path'] 
            : baseUrl + (videoUpload['path'].startsWith('/') ? videoUpload['path'].substring(1) : videoUpload['path']);
        videoUrl = Uri.encodeFull(basePath);
      }
    }
    
    return Episode(
      id: episodeJson['id'] ?? episodeJson['episode_id'],
      movieId: episodeJson['movie_id'],
      title: episodeJson['title'] ?? '',
      description: episodeJson['description'] ?? '',
      videoUrl: videoUrl ?? '',
      isFavorite: episodeJson['is_favorite'] ?? false,
      views: episodeJson['views'] ?? 0,
      likes: episodeJson['likes'] ?? 0,
      comments: episodeJson['comments'] ?? 0,
    );
  }
} 