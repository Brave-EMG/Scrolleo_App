import 'package:flutter/material.dart';

class Reel {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final int likes;
  final int shares;
  final int views;
  final String movieId;
  final int episodeNumber;
  final int totalEpisodes;

  Reel({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    this.likes = 0,
    this.shares = 0,
    this.views = 0,
    required this.movieId,
    required this.episodeNumber,
    required this.totalEpisodes,
  });
} 