import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../utils/app_date_utils.dart';
import '../config/environment.dart';

class MovieApiService {
  static final String baseUrl = '${Environment.apiBaseUrl}/movies';

  Future<Movie> createMovie({
    required String title,
    required String description,
    required List<String> genres,
    required DateTime releaseDate,
    required int duration,
    required String directorId,
    required int episodesCount,
    required String status,
    File? coverImage,
    Uint8List? coverImageBytes,
    File? videoFile,
    Uint8List? videoBytes,
    String? videoFileName,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/create'));

      // Ajouter les champs textuels
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['genres'] = jsonEncode(genres);
      request.fields['release_date'] = AppDateUtils.formatDateForApi(releaseDate);
      request.fields['duration'] = duration.toString();
      request.fields['director_id'] = directorId;
      request.fields['episodes_count'] = episodesCount.toString();
      request.fields['status'] = status;

      // Ajouter l'image de couverture si elle existe
      if (coverImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'cover_image',
          coverImage.path,
        ));
      } else if (coverImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'cover_image',
          coverImageBytes,
          filename: 'cover_image.jpg',
        ));
      }

      // Ajouter la vidéo principale si elle existe
      if (videoFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'video',
          videoFile.path,
          filename: videoFileName ?? 'video.mp4',
        ));
      } else if (videoBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'video',
          videoBytes,
          filename: videoFileName ?? 'video.mp4',
        ));
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 201) {
        return Movie.fromJson(jsonResponse['movie']);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Erreur lors de la création du film');
      }
    } catch (e) {
      throw Exception('Erreur lors de la création du film: $e');
    }
  }

  Future<Movie> updateMovie({
    required String id,
    required String title,
    required String description,
    required List<String> genres,
    required DateTime releaseDate,
    required int duration,
    required String directorId,
    required int episodesCount,
    required String status,
    File? coverImage,
    Uint8List? coverImageBytes,
  }) async {
    try {
      var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/$id'));
      
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['genres'] = jsonEncode(genres);
      request.fields['release_date'] = AppDateUtils.formatDateForApi(releaseDate);
      request.fields['duration'] = duration.toString();
      request.fields['director_id'] = directorId;
      request.fields['episodes_count'] = episodesCount.toString();
      request.fields['status'] = status;

      if (coverImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'cover_image',
          coverImage.path,
        ));
      } else if (coverImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'cover_image',
          coverImageBytes,
          filename: 'cover_image.jpg',
        ));
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return Movie.fromJson(jsonResponse['movie']);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Erreur lors de la mise à jour du film');
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du film: $e');
    }
  }
} 