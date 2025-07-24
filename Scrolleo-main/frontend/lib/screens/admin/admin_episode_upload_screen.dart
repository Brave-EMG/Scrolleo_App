import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/api_config.dart';
import '../../config/environment.dart';

class AdminEpisodeUploadScreen extends StatefulWidget {
  const AdminEpisodeUploadScreen({Key? key}) : super(key: key);

  @override
  State<AdminEpisodeUploadScreen> createState() => _AdminEpisodeUploadScreenState();
}

class _AdminEpisodeUploadScreenState extends State<AdminEpisodeUploadScreen> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _error;
  List<Map<String, dynamic>> _selectedFiles = [];
  List<Map<String, dynamic>> _episodes = [];
  bool _isLoading = true;
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _loadEpisodes();
      _didLoad = true;
    }
  }

  Future<void> _loadEpisodes() async {
    try {
      final state = GoRouterState.of(context);
      final extra = state.extra as Map<String, dynamic>?;
      final movieId = extra?['movieId'];
      
      if (movieId == null) {
        throw Exception('Movie ID is required');
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.jwtToken;

      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/episodes/movie/$movieId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final episodesList = List<Map<String, dynamic>>.from(data['episodes']);
        episodesList.sort((a, b) => (a['episode_number'] ?? 0).compareTo(b['episode_number'] ?? 0));
        if (mounted) {
          setState(() {
            _episodes = episodesList;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Erreur lors du chargement des épisodes: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickVideos() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
        withData: true,
      );

      if (result != null && mounted) {
        // Limiter à maximum 2 fichiers
        if (result.files.length > 2) {
          setState(() {
            _error = 'Vous ne pouvez sélectionner que maximum 2 vidéos à la fois.';
          });
          return;
        }

        setState(() {
          _selectedFiles = result.files.map((file) => {
            'file': file,
            'episodeId': null,
            'status': 'pending',
          }).toList();
          _error = null;
        });
      } else if (result == null && mounted) {
        setState(() {
          _error = 'Aucun fichier sélectionné ou navigateur non supporté.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors de la sélection des fichiers: $e';
        });
      }
    }
  }

  Future<void> _uploadVideos() async {
    if (_selectedFiles.isEmpty) return;

    if (_selectedFiles.any((f) => f['episodeId'] == null)) {
      if (mounted) {
        setState(() {
          _error = 'Veuillez sélectionner un épisode pour chaque vidéo.';
        });
      }
      return;
    }

    // Vérifier que les vidéos sont pour des épisodes différents
    final selectedEpisodeIds = _selectedFiles.map((f) => f['episodeId']).toSet();
    if (selectedEpisodeIds.length != _selectedFiles.length) {
      if (mounted) {
        setState(() {
          _error = 'Chaque vidéo doit être associée à un épisode différent. Vous ne pouvez pas uploader plusieurs vidéos pour le même épisode.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });
    }

    // Démarrer une simulation de progression pour donner un feedback visuel
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && _isUploading && _uploadProgress < 0.9) {
        setState(() {
          _uploadProgress += 0.01; // Progression lente pour simuler l'upload
        });
      }
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.jwtToken;

      if (token == null) {
        throw Exception('Non authentifié');
      }

      // Construction du mapping fichier-épisode pour l'API
      final filesMapping = <String, String>{};
      for (var f in _selectedFiles) {
        final pf = f['file'] as PlatformFile;
        final eid = f['episodeId'];
        filesMapping[pf.name] = eid.toString();
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Environment.apiBaseUrl}/uploads'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      for (int i = 0; i < _selectedFiles.length; i++) {
        final file = _selectedFiles[i]['file'] as PlatformFile;

        http.MultipartFile multipartFile;
        if (kIsWeb) {
          if (file.bytes == null || file.bytes!.isEmpty) {
            if (mounted) {
              setState(() {
                _error = 'Impossible de lire le fichier sélectionné (web): \\${file.name}';
              });
            }
            continue;
          }
          multipartFile = http.MultipartFile.fromBytes(
            'files',
            file.bytes!,
            filename: file.name,
          );
        } else if (file.path != null && file.path!.isNotEmpty) {
          multipartFile = await http.MultipartFile.fromPath(
            'files',
            file.path!,
            filename: file.name,
          );
        } else if (file.bytes != null && file.bytes!.isNotEmpty) {
          multipartFile = http.MultipartFile.fromBytes(
            'files',
            file.bytes!,
            filename: file.name,
          );
        } else {
          if (mounted) {
            setState(() {
              _error = 'Impossible de lire le fichier sélectionné : \\${file.name}';
            });
          }
          continue;
        }
        request.files.add(multipartFile);
      }

      request.fields['files_mapping'] = jsonEncode(filesMapping);

      // Calculer la taille totale des fichiers pour la progression
      int totalBytes = 0;
      for (var file in _selectedFiles) {
        final pf = file['file'] as PlatformFile;
        totalBytes += pf.size;
      }
      
      // Démarrer l'upload avec suivi de progression
      var streamedResponse = await request.send();
      
      // Simuler la progression (car http.MultipartRequest ne fournit pas de callback de progression)
      int uploadedBytes = 0;
      final responseBytes = <int>[];
      
      await for (var chunk in streamedResponse.stream) {
        responseBytes.addAll(chunk);
        uploadedBytes += chunk.length;
        
        // Mettre à jour la progression
        if (mounted && totalBytes > 0) {
          setState(() {
            _uploadProgress = (uploadedBytes / totalBytes).clamp(0.0, 1.0);
          });
        }
      }
      
      // Reconstruire la réponse
      var response = http.Response(
        String.fromCharCodes(responseBytes), 
        streamedResponse.statusCode, 
        headers: streamedResponse.headers
      );
      final uploadData = json.decode(response.body);
      final isSuccess = uploadData['success'] == true;

      // Mettre la progression à 100% quand l'upload est terminé
      if (mounted) {
        setState(() {
          _uploadProgress = 1.0;
        });
      }
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (isSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vidéos uploadées avec succès')),
            );
            Navigator.pop(context);
          }
        } else {
          throw Exception('Erreur lors de l\'upload: ${response.body}');
        }
      } else {
        throw Exception('Erreur lors de l\'upload: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors de l\'upload: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _updateUploadStatus(String uploadId, String status) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.jwtToken;

      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.patch(
        Uri.parse('${Environment.apiBaseUrl}/uploads/$uploadId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({ 'status': status }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la mise à jour du statut: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du statut: $e');
    }
  }

  void _assignEpisode(int fileIndex, int? episodeId) {
    setState(() {
      _selectedFiles[fileIndex]['episodeId'] = episodeId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    final extra = state.extra as Map<String, dynamic>?;
    
    if (extra == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        backgroundColor: Colors.black,
        body: const Center(
          child: Text(
            'Aucun film sélectionné ou arguments manquants.',
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      );
    }
    
    final movieTitle = extra['movieTitle'] as String?;
    if (movieTitle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        backgroundColor: Colors.black,
        body: const Center(
          child: Text(
            'Titre du film manquant.',
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Upload vidéos - $movieTitle'),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload des vidéos',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Limitations d\'upload',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Maximum 2 vidéos à la fois\n• Chaque vidéo doit être pour un épisode différent\n• Vous ne pouvez pas uploader plusieurs vidéos pour le même épisode',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_selectedFiles.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _selectedFiles.length,
                        itemBuilder: (context, index) {
                          final file = _selectedFiles[index]['file'] as PlatformFile;
                          final episodeId = _selectedFiles[index]['episodeId'];
                          final status = _selectedFiles[index]['status'];
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.video_file, color: Colors.orange),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            file.name,
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                          if (status != null)
                                            Text(
                                              'Statut: $status',
                                              style: TextStyle(
                                                color: status == 'completed' ? Colors.green : Colors.orange,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                DropdownButton<int>(
                                  value: episodeId,
                                  hint: const Text('Sélectionner un épisode', style: TextStyle(color: Colors.white70)),
                                  dropdownColor: Colors.grey[900],
                                  style: const TextStyle(color: Colors.white),
                                  underline: Container(height: 1, color: Colors.orange),
                                  items: _episodes.map((episode) {
                                    return DropdownMenuItem<int>(
                                      value: episode['episode_id'],
                                      child: Text('Épisode ${episode['episode_number']}: ${episode['title']}'),
                                    );
                                  }).toList(),
                                  onChanged: (value) => _assignEpisode(index, value),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  if (_isUploading)
                    Column(
                      children: [
                        LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: Colors.grey[800],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Upload en cours... ${(_uploadProgress * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _pickVideos,
                          icon: const Icon(Icons.add),
                          label: const Text('Sélectionner des vidéos (max 2)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      if (_selectedFiles.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isUploading || _selectedFiles.any((f) => f['episodeId'] == null)
                                ? null
                                : _uploadVideos,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Uploader'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
    );
  }
} 