import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/movie.dart';
import '../../services/movie_api_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import '../../config/environment.dart';

class DirectorMovieFormScreen extends StatefulWidget {
  final Movie? movie;

  const DirectorMovieFormScreen({Key? key, this.movie}) : super(key: key);

  @override
  State<DirectorMovieFormScreen> createState() => _DirectorMovieFormScreenState();
}

class _DirectorMovieFormScreenState extends State<DirectorMovieFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _movieApiService = MovieApiService();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _coverImageController;
  late TextEditingController _episodesCountController;
  late DateTime _releaseDate;
  late Duration _duration;
  late List<String> _selectedGenres;
  late List<Episode> _episodes;
  bool _isSeries = false;
  String _status = 'NoExclusive';
  String? _coverImagePath;
  String? _selectedGenre;
  Uint8List? _coverImageBytes;
  bool _isLoading = false;
  String? _error;

  final List<String> _availableGenres = [
    'Action',
    'Comédie',
    'Drame',
    'Science-Fiction',
    'Horreur',
    'Romance',
    'Documentaire',
    'Animation',
    'Thriller',
    'Aventure',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.movie?.title ?? '');
    _descriptionController = TextEditingController(text: widget.movie?.description ?? '');
    _coverImageController = TextEditingController(text: widget.movie?.posterUrl ?? '');
    _episodesCountController = TextEditingController(text: widget.movie?.episodes.length.toString() ?? '0');
    _releaseDate = widget.movie?.releaseDate ?? DateTime.now();
    _duration = widget.movie?.duration ?? const Duration(minutes: 90);
    _selectedGenres = widget.movie?.genres ?? [];
    if (_selectedGenres.isNotEmpty) {
      _selectedGenre = _selectedGenres.first;
    } else if (_availableGenres.isNotEmpty) {
      _selectedGenre = _availableGenres.first;
      _selectedGenres = [_selectedGenre!];
    } else {
      _selectedGenre = null;
    }
    _episodes = widget.movie?.episodes ?? [];
    _isSeries = widget.movie?.episodes.isNotEmpty ?? false;
    _coverImagePath = widget.movie?.posterUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _coverImageController.dispose();
    _episodesCountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _releaseDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _releaseDate) {
      setState(() {
        _releaseDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _selectDuration() async {
    final int? minutes = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        int selectedMinutes = _duration.inMinutes;
        return AlertDialog(
          title: const Text('Durée du film'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Durée en minutes',
                ),
                onChanged: (value) {
                  selectedMinutes = int.tryParse(value) ?? selectedMinutes;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedMinutes),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (minutes != null) {
      setState(() {
        _duration = Duration(minutes: minutes);
      });
    }
  }

  void _addEpisode() {
    setState(() {
      _episodes.add(Episode(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        titre: 'Nouvel épisode',
        description: 'Description de l\'épisode',
        videoPath: '',
        duree: const Duration(minutes: 45),
        dateSortie: DateTime.now(),
      ));
    });
  }

  void _removeEpisode(int index) {
    setState(() {
      _episodes.removeAt(index);
    });
  }

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        if (kIsWeb && result.files.single.bytes != null) {
          _coverImageBytes = result.files.single.bytes;
          _coverImagePath = null;
          _coverImageController.text = result.files.single.name;
        } else if (result.files.single.path != null) {
          _coverImagePath = result.files.single.path;
          _coverImageBytes = null;
          _coverImageController.text = _coverImagePath ?? '';
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.checkAuthStatus();
        final user = authService.currentUser;
        if (user == null) {
          throw Exception('Utilisateur non connecté');
        }
        Movie movie;
        if (widget.movie == null) {
          // Création
          movie = await _movieApiService.createMovie(
            title: _titleController.text,
            description: _descriptionController.text,
            genres: _selectedGenres,
            releaseDate: _releaseDate,
            duration: _duration.inMinutes,
            directorId: user.id,
            episodesCount: int.tryParse(_episodesCountController.text) ?? 0,
            coverImage: _coverImagePath != null && !kIsWeb ? File(_coverImagePath!) : null,
            coverImageBytes: _coverImageBytes,
            status: _status,
          );
        } else {
          // Modification
          movie = await _movieApiService.updateMovie(
            id: widget.movie!.id.toString(),
            title: _titleController.text,
            description: _descriptionController.text,
            genres: _selectedGenres,
            releaseDate: _releaseDate,
            duration: _duration.inMinutes,
            directorId: user.id,
            episodesCount: int.tryParse(_episodesCountController.text) ?? 0,
            coverImage: _coverImagePath != null && !kIsWeb ? File(_coverImagePath!) : null,
            coverImageBytes: _coverImageBytes,
            status: _status,
          );
        }
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString();
        });
      } finally {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.movie == null ? 'Nouveau Film' : 'Modifier le Film'),
        backgroundColor: Colors.grey[900],
      ),
      backgroundColor: Colors.grey[850],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              const Text('Titre du film', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  labelStyle: TextStyle(color: Colors.black54),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un titre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Description du film', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.black54),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Date de sortie et durée', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today),
                      label: Text('Date de sortie: ${_releaseDate.day}/${_releaseDate.month}/${_releaseDate.year}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDuration,
                      icon: const Icon(Icons.timer),
                      label: Text('Durée: ${_duration.inMinutes} min'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Genres du film', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: _availableGenres.map((genre) {
                  return FilterChip(
                    label: Text(genre),
                    selected: _selectedGenres.contains(genre),
                    onSelected: (selected) {
                  setState(() {
                        if (selected) {
                          _selectedGenres.add(genre);
                        } else {
                          _selectedGenres.remove(genre);
                        }
                  });
                },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Image de couverture', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              if (_coverImagePath != null && _coverImagePath!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb && _coverImageBytes != null
                            ? Image.memory(_coverImageBytes!, height: 120, fit: BoxFit.cover)
                                : (_coverImagePath!.startsWith('http') || kIsWeb
                                    ? Image.network(_coverImagePath!.startsWith('http') ? _coverImagePath! : '${Environment.apiBaseUrl}${_coverImagePath!}', height: 120, fit: BoxFit.cover)
                                : Image.file(File(_coverImagePath!), height: 120, fit: BoxFit.cover)),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              tooltip: 'Changer l\'image',
                              onPressed: _pickCoverImage,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Supprimer l\'image',
                              onPressed: () {
                                setState(() {
                                  _coverImagePath = null;
                                  _coverImageController.text = '';
                                  _coverImageBytes = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (_coverImagePath == null || _coverImagePath!.isEmpty)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _coverImageController,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          labelText: 'Image de couverture (chemin local)',
                          labelStyle: TextStyle(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _pickCoverImage,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Uploader'),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              const Text('Nombre d\'épisodes (optionnel)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _episodesCountController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nombre d\'épisodes',
                  labelStyle: TextStyle(color: Colors.black54),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Statut du film', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              TextFormField(
                initialValue: _status,
                style: const TextStyle(color: Colors.black),
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Statut',
                  labelStyle: TextStyle(color: Colors.black54),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Exclusivité SCROLLEO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Switch(
                    value: _status == 'Exclusive',
                    onChanged: (value) {
                      setState(() {
                        _status = value ? 'Exclusive' : 'NoExclusive';
                      });
                    },
                    activeColor: Colors.orange,
                  ),
                  Text(_status == 'Exclusive' ? 'Oui' : 'Non', style: TextStyle(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 16),
                  const SizedBox(height: 32),
                  Center(
                    child: SizedBox(
                      width: 280,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.movie == null ? 'Créer le film' : 'Mettre à jour le film',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                        ),
                ),
              ),
                  const SizedBox(height: 40),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 