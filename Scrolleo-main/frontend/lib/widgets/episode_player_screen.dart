import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';
import '../models/movie.dart';
import '../providers/favorites_provider.dart';
import 'tiktok_style_player.dart';

class EpisodePlayerScreen extends StatefulWidget {
  final int episodeId;
  final String? videoUrl;
  final String? title;
  final String? description;
  final String? movieId;
  final int? seasonNumber;
  final int? episodeNumber;
  final int? tikTokEpisodeId;

  const EpisodePlayerScreen({
    Key? key,
    required this.episodeId,
    this.videoUrl,
    this.title,
    this.description,
    this.movieId,
    this.seasonNumber,
    this.episodeNumber,
    this.tikTokEpisodeId,
  }) : super(key: key);

  @override
  State<EpisodePlayerScreen> createState() => _EpisodePlayerScreenState();
}

class _EpisodePlayerScreenState extends State<EpisodePlayerScreen> {
  @override
  Widget build(BuildContext context) {
    if (widget.movieId == null || widget.seasonNumber == null || widget.episodeNumber == null) {
      return const Scaffold(
        body: Center(
          child: Text('Informations manquantes pour l\'épisode'),
        ),
      );
    }

    return TikTokStylePlayer(
      movieId: widget.movieId!,
      seasonNumber: widget.seasonNumber!,
      episodeNumber: widget.episodeNumber!,
      initialVideoUrl: widget.videoUrl,
      title: widget.title,
      description: widget.description,
      episodeId: widget.tikTokEpisodeId ?? widget.episodeId,
    );
  }
} 