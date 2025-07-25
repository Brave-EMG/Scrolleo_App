import 'package:flutter/material.dart';
import '../services/episode_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class EpisodeDetails extends StatefulWidget {
  final String episodeId;
  final bool isDirector;

  const EpisodeDetails({
    Key? key,
    required this.episodeId,
    this.isDirector = false,
  }) : super(key: key);

  @override
  _EpisodeDetailsState createState() => _EpisodeDetailsState();
}

class _EpisodeDetailsState extends State<EpisodeDetails> {
  final EpisodeService _episodeService = EpisodeService();
  Map<String, dynamic>? _episode;
  bool _isLoading = true;
  String? _error;
  String? _videoUrl;
  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _loadEpisode();
  }

  @override
  void didUpdateWidget(covariant EpisodeDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.episodeId != oldWidget.episodeId) {
      _loadEpisode();
    }
  }

  Future<void> _loadEpisode() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final episode = await _episodeService.getEpisodeUpload(widget.episodeId);
      // Charger la vidéo associée à l'épisode
      final uploadsResponse = await http.get(Uri.parse('http://localhost:3000/api/uploads/episodes/${widget.episodeId}/uploads'));
      String? videoUrl;
      if (uploadsResponse.statusCode == 200) {
        final uploads = List<Map<String, dynamic>>.from(jsonDecode(uploadsResponse.body));
        final videoUpload = uploads.firstWhere(
          (u) => u['type'] == 'video' && u['status'] == 'completed' && u['path'] != null,
          orElse: () => {},
        );
        if (videoUpload.isNotEmpty) {
          videoUrl = videoUpload['path'];
        }
      }
      // Initialiser le contrôleur vidéo si une vidéo est trouvée
      if (_videoController != null) {
        await _videoController!.dispose();
        _videoController = null;
      }
      Future<void>? videoFuture;
      if (videoUrl != null) {
        print('Initialisation du contrôleur vidéo avec l\'URL : $videoUrl');
        _videoController = VideoPlayerController.network(videoUrl)
          ..addListener(() {
            print('État vidéo : isPlaying=${_videoController!.value.isPlaying}, position=${_videoController!.value.position}, erreur=${_videoController!.value.hasError}');
          });
        videoFuture = _videoController!.initialize().then((_) {
          print('Contrôleur vidéo initialisé. Durée :  {_videoController!.value.duration}');
        }).catchError((e) {
          print('Erreur lors de l\'initialisation du contrôleur vidéo : $e');
        });
      }
      setState(() {
        _episode = episode;
        _videoUrl = videoUrl;
        _initializeVideoPlayerFuture = videoFuture;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _openEditEpisodeDialog() async {
    final _titleController = TextEditingController(text: _episode!['title'] ?? '');
    final _descriptionController = TextEditingController(text: _episode!['description'] ?? '');
    final _episodeNumberController = TextEditingController(text: (_episode!['episode_number'] ?? '').toString());
    final _seasonNumberController = TextEditingController(text: (_episode!['season_number'] ?? '').toString());
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier l\'épisode'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Titre'),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: _episodeNumberController,
                  decoration: const InputDecoration(labelText: 'Numéro d\'épisode'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _seasonNumberController,
                  decoration: const InputDecoration(labelText: 'Numéro de saison'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = _titleController.text.trim();
                final description = _descriptionController.text.trim();
                final episodeNumber = int.tryParse(_episodeNumberController.text.trim()) ?? 1;
                final seasonNumber = int.tryParse(_seasonNumberController.text.trim()) ?? 1;
                if (title.isEmpty) return;
                Navigator.pop(context, {
                  'title': title,
                  'description': description,
                  'episode_number': episodeNumber,
                  'season_number': seasonNumber,
                });
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      final success = await _episodeService.updateEpisode(_episode!['id'].toString(), result);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Épisode modifié avec succès')),
        );
        _loadEpisode();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la modification de l\'épisode')),
        );
      }
    }
  }

  void _deleteEpisode() async {
    // Vérifier si l'ID est valide
    if (widget.episodeId.isEmpty || widget.episodeId == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID d\'épisode invalide')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'épisode'),
        content: const Text('Voulez-vous vraiment supprimer cet épisode ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        // S'assurer que l'ID est un nombre valide
        final episodeId = int.tryParse(widget.episodeId);
        if (episodeId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ID d\'épisode invalide')),
          );
          return;
        }

        final success = await _episodeService.deleteEpisode(episodeId.toString());
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Épisode supprimé avec succès')),
          );
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de la suppression de l\'épisode')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Erreur: $_error',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEpisode,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_episode == null) {
      return const Center(
        child: Text(
          'Épisode non trouvé',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_videoUrl != null)
            Column(
              children: [
                AspectRatio(
                  aspectRatio: _videoController?.value.aspectRatio ?? 16 / 9,
                  child: _initializeVideoPlayerFuture != null
                      ? FutureBuilder(
                          future: _initializeVideoPlayerFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done) {
                              return Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  VideoPlayer(_videoController!),
                                  VideoProgressIndicator(_videoController!, allowScrubbing: true),
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: FloatingActionButton(
                                      mini: true,
                                      backgroundColor: Colors.black54,
                                      onPressed: () {
                                        setState(() {
                                          if (_videoController!.value.isPlaying) {
                                            print('Pause vidéo');
                                            _videoController!.pause();
                                          } else {
                                            print('Lecture vidéo');
                                            _videoController!.play();
                                          }
                                        });
                                      },
                                      child: Icon(
                                        _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return const Center(child: CircularProgressIndicator());
                            }
                          },
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
                const SizedBox(height: 16),
              ],
            )
          else if (_episode!['thumbnail_url'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _episode!['thumbnail_url'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, size: 50),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          Text(
            _episode!['title'] ?? 'Sans titre',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Épisode ${_episode!['episode_number']}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(
            _episode!['description'] ?? 'Aucune description disponible',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          if (widget.isDirector) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                print('Bouton Uploader une vidéo cliqué');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Début du callback upload')),
                );
                final result = await FilePicker.platform.pickFiles(type: FileType.any);
                print('Résultat file picker : $result');
                if (result != null) {
                  final file = result.files.single;
                  print('file.bytes: ${file.bytes}');
                  print('file.name: ${file.name}');
                  print('file.size: ${file.size}');
                  final episodeId = _episode!['id'] ?? _episode!['episode_id'];
                  final url = 'http://localhost:3000/api/uploads';
                  print('URL d\'upload : $url');
                  final request = http.MultipartRequest('POST', Uri.parse(url));
                  if (kIsWeb) {
                    if (file.bytes != null) {
                      print('Upload via fromBytes');
                      request.files.add(
                        http.MultipartFile.fromBytes(
                          'files',
                          file.bytes!,
                          filename: file.name,
                        ),
                      );
                    } else {
                      print('Aucun fichier sélectionné ou bytes null');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Aucun fichier sélectionné ou fichier vide')),
                      );
                      return;
                    }
                  } else {
                    if (file.path != null) {
                      print('Upload via fromPath');
                      request.files.add(
                        await http.MultipartFile.fromPath('files', file.path!),
                      );
                    } else {
                      print('Aucun fichier sélectionné ou chemin invalide');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Aucun fichier sélectionné ou chemin invalide')),
                      );
                      return;
                    }
                  }
                  final mapping = {file.name: episodeId.toString()};
                  request.fields['files_mapping'] = jsonEncode(mapping);
                  final response = await request.send();
                  print('Réponse upload : ${response.statusCode}');
                  if (response.statusCode == 200 || response.statusCode == 201) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vidéo uploadée avec succès')),
                    );
                    _loadEpisode();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur lors de l\'upload: ${response.statusCode}')),
                    );
                  }
                } else {
                  print('Aucun fichier sélectionné');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Aucun fichier sélectionné')),
                  );
                }
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Uploader une vidéo'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      print('Bouton Modifier cliqué');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Callback Modifier appelé')),
                      );
                      _openEditEpisodeDialog();
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      print('Bouton Supprimer cliqué');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Callback Supprimer appelé')),
                      );
                      _deleteEpisode();
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Supprimer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
} 