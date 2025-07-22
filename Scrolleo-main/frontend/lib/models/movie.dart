import 'dart:convert';
import '../utils/app_date_utils.dart';

class Commentaire {
  final String id;
  final String auteur;
  final String texte;
  final DateTime date;

  Commentaire({
    required this.id,
    required this.auteur,
    required this.texte,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'auteur': auteur,
    'texte': texte,
    'date': date.toIso8601String(),
  };

  factory Commentaire.fromJson(Map<String, dynamic> json) => Commentaire(
    id: json['id'],
    auteur: json['auteur'],
    texte: json['texte'],
    date: DateTime.parse(json['date']),
  );
}

class Episode {
  final String id;
  final String titre;
  final String description;
  final String videoPath;
  final Duration duree;
  final DateTime dateSortie;
  final List<Commentaire> commentaires;
  final int views;
  final int likes;
  final int subscribers;
  final double rating;

  Episode({
    required this.id,
    required this.titre,
    required this.description,
    required this.videoPath,
    required this.duree,
    required this.dateSortie,
    this.commentaires = const [],
    this.views = 0,
    this.likes = 0,
    this.subscribers = 0,
    this.rating = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'titre': titre,
    'description': description,
    'videoPath': videoPath,
    'duree': duree.inMinutes,
    'dateSortie': dateSortie.toIso8601String(),
    'commentaires': commentaires.map((c) => c.toJson()).toList(),
    'views': views,
    'likes': likes,
    'subscribers': subscribers,
    'rating': rating,
  };

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
    id: json['id'],
    titre: json['titre'],
    description: json['description'],
    videoPath: json['videoPath'],
    duree: Duration(minutes: json['duree']),
    dateSortie: DateTime.parse(json['dateSortie']),
    commentaires: List<Commentaire>.from(json['commentaires'].map((c) => Commentaire.fromJson(c))),
    views: json['views'] ?? 0,
    likes: json['likes'] ?? 0,
    subscribers: json['subscribers'] ?? 0,
    rating: json['rating']?.toDouble() ?? 0.0,
  );

  Episode copyWith({
    String? id,
    String? titre,
    String? description,
    String? videoPath,
    Duration? duree,
    DateTime? dateSortie,
    List<Commentaire>? commentaires,
    int? views,
    int? likes,
    int? subscribers,
    double? rating,
  }) {
    return Episode(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      videoPath: videoPath ?? this.videoPath,
      duree: duree ?? this.duree,
      dateSortie: dateSortie ?? this.dateSortie,
      commentaires: commentaires ?? this.commentaires,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      subscribers: subscribers ?? this.subscribers,
      rating: rating ?? this.rating,
    );
  }
}

class Movie {
  final dynamic id;
  final String title;
  final String description;
  final String posterUrl;
  final String videoUrl;
  final String directorId;
  final String director;
  final List<String> genres;
  final DateTime releaseDate;
  final Duration duration;
  final double rating;
  final String backdropUrl;
  final bool isTrending;
  final int views;
  final int likes;
  final int subscribers;
  final List<Episode> episodes;
  final List<Commentaire> commentaires;
  final String status;
  final String directorUsername;
  final DateTime createdAt;
  final int episodes_count;
  final String? season;

  Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.posterUrl,
    required this.videoUrl,
    required this.directorId,
    required this.director,
    required this.genres,
    required this.releaseDate,
    required this.duration,
    required this.rating,
    required this.backdropUrl,
    this.isTrending = false,
    this.views = 0,
    this.likes = 0,
    this.subscribers = 0,
    this.episodes = const [],
    this.commentaires = const [],
    this.status = 'pending',
    this.directorUsername = '',
    this.episodes_count = 0,
    this.season,
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  int get nombreEpisodes => episodes.length;

  Map<String, dynamic> toJson() => {
    'movie_id': id,
    'title': title,
    'description': description,
    'cover_image': posterUrl,
    'video_url': videoUrl,
    'director_id': director,
    'directorId': directorId,
    'release_date': AppDateUtils.formatDateForApi(releaseDate),
    'duration': duration.inMinutes,
    'rating': rating,
    'genre': genres.isNotEmpty ? genres.first : '',
    'backdrop_url': backdropUrl,
    'is_trending': isTrending,
    'views': views,
    'likes': likes,
    'subscribers': subscribers,
    'episodes': episodes.map((e) => e.toJson()).toList(),
    'commentaires': commentaires.map((c) => c.toJson()).toList(),
    'status': status,
    'director_username': directorUsername,
    'episodes_count': episodes_count,
    'season': season,
    'created_at': AppDateUtils.formatDateForApi(createdAt),
  };

  factory Movie.fromJson(Map<String, dynamic> json) {
    List<String> genresList = [];
    if (json['genres'] != null) {
      if (json['genres'] is List) {
        genresList = List<String>.from(json['genres']);
      } else if (json['genres'] is String && json['genres'].toString().isNotEmpty) {
        genresList = json['genres'].toString().split(',').map((g) => g.trim()).toList();
      }
    } else if (json['genre'] != null && json['genre'] is String && json['genre'].toString().isNotEmpty) {
      genresList = (json['genre'] as String).split(',').map((e) => e.trim()).toList();
    }

    // Fonction helper pour convertir en int de manière sûre
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          return 0;
        }
      }
      return 0;
    }

    return Movie(
      id: json['movie_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      posterUrl: json['cover_image'] ?? '',
      videoUrl: json['video_url'] ?? '',
      directorId: json['director_id']?.toString() ?? '',
      director: json['director'] ?? json['director_id']?.toString() ?? '',
      releaseDate: DateTime.tryParse(json['release_date'] ?? '') ?? DateTime.now(),
      duration: Duration(minutes: safeInt(json['duration'])),
      rating: (json['rating'] ?? 0.0).toDouble(),
      genres: genresList,
      backdropUrl: json['backdrop_url'] ?? '',
      isTrending: json['is_trending'] ?? false,
      views: safeInt(json['views']),
      likes: safeInt(json['likes']),
      subscribers: safeInt(json['subscribers']),
      episodes: json['episodes'] != null
          ? List<Episode>.from(json['episodes'].map((e) => Episode.fromJson(e)))
          : [],
      commentaires: json['commentaires'] != null
          ? List<Commentaire>.from(json['commentaires'].map((c) => Commentaire.fromJson(c)))
          : [],
      status: json['status'] ?? 'pending',
      directorUsername: json['director_username'] ?? json['realisateur'] ?? '',
      episodes_count: safeInt(json['episodes_count']),
      season: json['season']?.toString(),
      createdAt: json['created_at'] != null ? AppDateUtils.parseApiDate(json['created_at']) : null,
    );
  }

  Movie copyWith({
    dynamic id,
    String? title,
    String? description,
    String? posterUrl,
    String? videoUrl,
    String? directorId,
    String? director,
    List<String>? genres,
    DateTime? releaseDate,
    Duration? duration,
    double? rating,
    String? backdropUrl,
    bool? isTrending,
    int? views,
    int? likes,
    int? subscribers,
    List<Episode>? episodes,
    List<Commentaire>? commentaires,
    String? status,
    String? directorUsername,
    DateTime? createdAt,
    int? episodes_count,
    String? season,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      posterUrl: posterUrl ?? this.posterUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      directorId: directorId ?? this.directorId,
      director: director ?? this.director,
      genres: genres ?? this.genres,
      releaseDate: releaseDate ?? this.releaseDate,
      duration: duration ?? this.duration,
      rating: rating ?? this.rating,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      isTrending: isTrending ?? this.isTrending,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      subscribers: subscribers ?? this.subscribers,
      episodes: episodes ?? this.episodes,
      commentaires: commentaires ?? this.commentaires,
      status: status ?? this.status,
      directorUsername: directorUsername ?? this.directorUsername,
      episodes_count: episodes_count ?? this.episodes_count,
      season: season ?? this.season,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'posterUrl': posterUrl,
      'videoUrl': videoUrl,
      'directorId': directorId,
      'director': director,
      'genres': genres,
      'releaseDate': releaseDate.toIso8601String(),
      'duration': duration.inMinutes,
      'rating': rating,
      'backdropUrl': backdropUrl,
      'isTrending': isTrending,
      'views': views,
      'likes': likes,
      'subscribers': subscribers,
      'episodes': episodes.map((e) => e.toJson()).toList(),
      'commentaires': commentaires.map((c) => c.toJson()).toList(),
      'status': status,
      'directorUsername': directorUsername,
      'episodes_count': episodes_count,
      'season': season,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Movie.fromMap(Map<String, dynamic> map) {
    return Movie(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      posterUrl: map['posterUrl'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      directorId: map['directorId']?.toString() ?? '',
      director: map['director'] ?? '',
      genres: List<String>.from(map['genres'] ?? []),
      releaseDate: DateTime.tryParse(map['releaseDate'] ?? '') ?? DateTime.now(),
      duration: Duration(minutes: map['duration'] ?? 0),
      rating: (map['rating'] ?? 0.0).toDouble(),
      backdropUrl: map['backdropUrl'] ?? '',
      isTrending: map['isTrending'] ?? false,
      views: map['views'] ?? 0,
      likes: map['likes'] ?? 0,
      subscribers: map['subscribers'] ?? 0,
      episodes: map['episodes'] != null
          ? List<Episode>.from(map['episodes'].map((e) => Episode.fromJson(e)))
          : [],
      commentaires: map['commentaires'] != null
          ? List<Commentaire>.from(map['commentaires'].map((c) => Commentaire.fromJson(c)))
          : [],
      status: map['status'] ?? 'pending',
      directorUsername: map['directorUsername'] ?? '',
      episodes_count: map['episodes_count'] ?? 0,
      season: map['season'],
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) ?? DateTime.now() : null,
    );
  }

  @override
  String toString() {
    return 'Movie(id: $id, title: $title, description: $description, posterUrl: $posterUrl, videoUrl: $videoUrl, directorId: $directorId, director: $director, genres: $genres, releaseDate: $releaseDate, duration: $duration, rating: $rating, backdropUrl: $backdropUrl, isTrending: $isTrending, views: $views, likes: $likes, subscribers: $subscribers, episodes: $episodes, commentaires: $commentaires, status: $status, directorUsername: $directorUsername, episodes_count: $episodes_count, season: $season)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Movie &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.posterUrl == posterUrl &&
        other.videoUrl == videoUrl &&
        other.directorId == directorId &&
        other.director == director &&
        other.genres == genres &&
        other.releaseDate == releaseDate &&
        other.duration == duration &&
        other.rating == rating &&
        other.backdropUrl == backdropUrl &&
        other.isTrending == isTrending &&
        other.views == views &&
        other.likes == likes &&
        other.subscribers == subscribers &&
        other.episodes == episodes &&
        other.commentaires == commentaires &&
        other.status == status &&
        other.directorUsername == directorUsername &&
        other.episodes_count == episodes_count &&
        other.season == season;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        posterUrl.hashCode ^
        videoUrl.hashCode ^
        directorId.hashCode ^
        director.hashCode ^
        genres.hashCode ^
        releaseDate.hashCode ^
        duration.hashCode ^
        rating.hashCode ^
        backdropUrl.hashCode ^
        isTrending.hashCode ^
        views.hashCode ^
        likes.hashCode ^
        subscribers.hashCode ^
        episodes.hashCode ^
        commentaires.hashCode ^
        status.hashCode ^
        directorUsername.hashCode ^
        episodes_count.hashCode ^
        season.hashCode;
  }
}

class MinimalMovie {
  final String title;
  final int likes;
  final int views;
  final int favorites;
  final double? rating;
  final String? genre;
  final DateTime releaseDate;

  MinimalMovie({
    required this.title,
    required this.likes,
    required this.views,
    required this.favorites,
    this.rating,
    this.genre,
    required this.releaseDate,
  });

  factory MinimalMovie.fromJson(Map<String, dynamic> json) {
    DateTime parseReleaseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is DateTime) return date;
      try {
        return DateTime.parse(date.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    return MinimalMovie(
      title: json['title'] ?? '',
      likes: json['likes'] ?? 0,
      views: json['views'] ?? 0,
      favorites: json['favorites'] ?? 0,
      rating: json['rating']?.toDouble(),
      genre: json['genre'],
      releaseDate: parseReleaseDate(json['release_date'] ?? json['created_at']),
    );
  }

  factory MinimalMovie.fromMovie(Movie movie) => MinimalMovie(
    title: movie.title,
    likes: movie.likes,
    views: movie.views,
    favorites: movie.likes > 0 ? 1 : 0,
    rating: movie.rating,
    genre: movie.genres.isNotEmpty ? movie.genres.first : null,
    releaseDate: movie.releaseDate,
  );
} 