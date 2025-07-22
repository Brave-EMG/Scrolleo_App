import 'package:flutter/material.dart';
import '../../models/movie.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import '../../config/api_config.dart';
import '../../config/environment.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class AdminManageEpisodesScreen extends StatefulWidget {
  final Movie movie;
  const AdminManageEpisodesScreen({Key? key, required this.movie}) : super(key: key);

  @override
  State<AdminManageEpisodesScreen> createState() => _AdminManageEpisodesScreenState();
}

class _AdminManageEpisodesScreenState extends State<AdminManageEpisodesScreen> {
  List<Map<String, dynamic>> episodes = [];
  bool _isLoading = true;
  String? _error;
  late final Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchEpisodes();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchEpisodes() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await http.get(Uri.parse('${Environment.apiBaseUrl}/episodes/movie/${widget.movie.id}'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<Map<String, dynamic>> parsedEpisodes;
        if (decoded is Map && decoded['episodes'] is List) {
          parsedEpisodes = List<Map<String, dynamic>>.from(decoded['episodes']);
          print('Épisodes reçus : $parsedEpisodes');
        } else {
          parsedEpisodes = [];
        }
        setState(() {
          episodes = List<Map<String, dynamic>>.from(parsedEpisodes)
            ..sort((a, b) => (a['episode_number'] ?? 0).compareTo(b['episode_number'] ?? 0));
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Erreur serveur: ${response.statusCode}'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Erreur réseau: $e'; _isLoading = false; });
    }
  }

  void _onAddEpisode() {
    final _titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Ajouter un épisode', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.orange)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
                  );
                  return;
                }
                try {
                  // Recharge la liste des épisodes depuis le backend
                  final responseEpisodes = await http.get(Uri.parse('${Environment.apiBaseUrl}/episodes/movie/${widget.movie.id}'));
                  List<dynamic> episodesBackend = [];
                  if (responseEpisodes.statusCode == 200) {
                    final decoded = json.decode(responseEpisodes.body);
                    if (decoded is Map && decoded['episodes'] is List) {
                      episodesBackend = decoded['episodes'];
                    }
                  }
                  final usedNumbers = episodesBackend.map((e) => e['episode_number'] as int? ?? 0).toSet();
                  int nextNumber = 1;
                  while (usedNumbers.contains(nextNumber)) {
                    nextNumber++;
                  }
                  final forcedTitle = 'Épisode $nextNumber';
                  final response = await http.post(
                    Uri.parse('${Environment.apiBaseUrl}/episodes/'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({
                      'movie_id': widget.movie.id,
                      'episodes': [{
                        'title': forcedTitle,
                        'episode_number': nextNumber,
                        'season_number': 1
                      }]
                    }),
                  );
                  if (response.statusCode == 201 || response.statusCode == 200) {
                    Navigator.pop(context);
                    _fetchEpisodes();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Épisode ajouté avec succès')),
                    );
                  } else {
                    throw Exception('Erreur lors de l\'ajout de l\'épisode');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _onEditEpisode(Map<String, dynamic> episode) {
    final _titleController = TextEditingController(text: episode['title'] ?? episode['titre'] ?? '');
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Modifier l\'épisode', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.orange)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez remplir le titre')),
                  );
                  return;
                }
                try {
                  final response = await http.put(
                    Uri.parse('${Environment.apiBaseUrl}/episodes/${episode['episode_id']}'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({
                      'title': _titleController.text,
                    }),
                  );
                  if (response.statusCode == 200) {
                    Navigator.pop(context);
                    _fetchEpisodes();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Épisode modifié avec succès')),
                    );
                  } else {
                    throw Exception('Erreur lors de la modification de l\'épisode');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _onDeleteEpisode(Map<String, dynamic> episode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Supprimer l\'épisode', style: TextStyle(color: Colors.white)),
        content: Text('Voulez-vous vraiment supprimer "${episode['title'] ?? episode['titre'] ?? 'cet épisode'}" ?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.orange)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final episodeId = episode['episode_id'];
        print('Suppression épisode avec id : $episodeId');
        if (episodeId == null) {
          throw Exception('ID de l\'épisode non trouvé');
        }
        final response = await http.delete(Uri.parse('${Environment.apiBaseUrl}/episodes/$episodeId'));
        if (response.statusCode == 200) {
          _fetchEpisodes();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Épisode supprimé avec succès')));
        } else {
          throw Exception('Erreur lors de la suppression: ${response.body}');
        }
      } catch (e) {
        print('Erreur lors de la suppression : $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _onAddMultipleEpisodes() {
    final List<TextEditingController> titleControllers = List.generate(5, (_) => TextEditingController());
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Ajouter plusieurs épisodes', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Épisode ${i + 1}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  TextField(
                    controller: titleControllers[i],
                    decoration: const InputDecoration(labelText: 'Titre', labelStyle: TextStyle(color: Colors.white70)),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                ],
              )),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.orange)),
            ),
            ElevatedButton(
              onPressed: () async {
                final List<Map<String, dynamic>> newEpisodes = [];
                for (int i = 0; i < 5; i++) {
                  if (titleControllers[i].text.isNotEmpty) {
                    newEpisodes.add({
                      'title': '', // sera forcé plus bas
                    });
                  }
                }
                if (newEpisodes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez remplir au moins un épisode complet')));
                  return;
                }
                try {
                  // Recharge la liste des épisodes depuis le backend
                  final responseEpisodes = await http.get(Uri.parse('${Environment.apiBaseUrl}/episodes/movie/${widget.movie.id}'));
                  List<dynamic> episodesBackend = [];
                  if (responseEpisodes.statusCode == 200) {
                    final decoded = json.decode(responseEpisodes.body);
                    if (decoded is Map && decoded['episodes'] is List) {
                      episodesBackend = decoded['episodes'];
                    }
                  }
                  final usedNumbers = episodesBackend.map((e) => e['episode_number'] as int? ?? 0).toSet();
                  int nextNumber = 1;
                  for (var ep in newEpisodes) {
                    while (usedNumbers.contains(nextNumber)) {
                      nextNumber++;
                    }
                    ep['title'] = 'Épisode $nextNumber';
                    ep['episode_number'] = nextNumber;
                    ep['season_number'] = 1;
                    usedNumbers.add(nextNumber);
                    nextNumber++;
                  }
                  final response = await http.post(
                    Uri.parse('${Environment.apiBaseUrl}/episodes/'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({
                      'movie_id': widget.movie.id,
                      'episodes': newEpisodes
                    }),
                  );
                  if (response.statusCode == 201 || response.statusCode == 200) {
                    Navigator.pop(context);
                    _fetchEpisodes();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Épisodes ajoutés avec succès')));
                  } else {
                    throw Exception('Erreur lors de l\'ajout des épisodes');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEpisodeVideo(BuildContext context, int episodeId) async {
    try {
      // Récupérer le token d'authentification
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: Token d\'authentification manquant')),
        );
        return;
      }

      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/uploads/episodes/$episodeId/uploads'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final uploads = json.decode(response.body);
        final videoUpload = (uploads as List).firstWhere(
          (u) => u['type'] == 'video' && u['status'] == 'completed' && u['path'] != null,
          orElse: () => null,
        );
        if (videoUpload != null) {
          context.push(
            '/admin/episode_video',
            extra: {'videoUrl': videoUpload['path']},
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucune vidéo trouvée pour cet épisode')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la récupération de la vidéo: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _showEpisodeUploads(BuildContext context, int episodeId) async {
    try {
      // Récupérer le token d'authentification
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: Token d\'authentification manquant')),
        );
        return;
      }

      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/uploads/episodes/$episodeId/uploads'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final uploads = json.decode(response.body);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.black,
            title: const Text('Vidéos de l\'épisode', style: TextStyle(color: Colors.white)),
            content: SizedBox(
              width: 400,
              child: uploads.isEmpty
                  ? const Text('Aucune vidéo trouvée', style: TextStyle(color: Colors.white70))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: uploads.length,
                      itemBuilder: (context, index) {
                        final upload = uploads[index];
                        if (upload['type'] != 'video') return const SizedBox.shrink();
                        return ListTile(
                          title: Text(upload['original_name'] ?? 'Sans nom', style: const TextStyle(color: Colors.white)),
                          subtitle: Text(upload['path'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDeleteUpload(context, upload['upload_id'], episodeId),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer', style: TextStyle(color: Colors.orange)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la récupération des vidéos: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _confirmDeleteUpload(BuildContext context, int uploadId, int episodeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la vidéo ?'),
        content: const Text('Voulez-vous vraiment supprimer cette vidéo ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final response = await http.delete(Uri.parse('${Environment.apiBaseUrl}/uploads/$uploadId'));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vidéo supprimée avec succès')));
        Navigator.pop(context); // Ferme la liste
        // Rafraîchir la liste après suppression
        _showEpisodeUploads(context, episodeId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la suppression')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des épisodes - ${widget.movie.title}'),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.grey[900]!,
              Colors.black,
            ],
          ),
        ),
        child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Header avec titre et statistiques
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        Text(
                          'Gestion des épisodes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.movie.title}',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${episodes.length} épisode(s) au total',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.5)),
                      ),
                      child: Icon(
                        Icons.admin_panel_settings,
                        color: Colors.orange,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Boutons d'action
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900]!.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                    ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.add,
                      label: 'Ajouter',
                      color: Colors.green,
                      onPressed: _onAddEpisode,
                    ),
                    _buildActionButton(
                      icon: Icons.upload_file,
                      label: 'Uploader',
                      color: Colors.blue,
                      onPressed: () {
                        context.push(
                          '/admin/episode_upload',
                          extra: {
                            'movieId': widget.movie.id,
                            'movieTitle': widget.movie.title,
                          },
                        );
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.library_add,
                      label: 'Multiples',
                      color: Colors.orange,
                      onPressed: _onAddMultipleEpisodes,
                    ),
                  ],
                ),
            ),
              
            const SizedBox(height: 24),
              
              // Liste des épisodes
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            CircularProgressIndicator(color: Colors.orange),
                            const SizedBox(height: 16),
                            Text(
                              'Chargement des épisodes...',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.red, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  _error!,
                                  style: TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchEpisodes,
                                  child: Text('Réessayer'),
                                ),
                              ],
                            ),
                          )
                        : episodes.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.video_library, color: Colors.grey[600], size: 64),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Aucun épisode trouvé',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Commencez par ajouter des épisodes',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 
                                                 MediaQuery.of(context).size.width > 800 ? 2 : 1,
                                  childAspectRatio: 1.2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: episodes.length,
                                itemBuilder: (context, index) {
                                  final episode = episodes[index];
                                  return _buildEpisodeCard(episode, index);
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
                                      );
                                    }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
        backgroundColor: color,
                                  foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }

  Widget _buildEpisodeCard(Map<String, dynamic> episode, int index) {
    final episodeNumber = episode['episode_number'] ?? (index + 1);
    final title = episode['title'] ?? episode['titre'] ?? 'Épisode $episodeNumber';
    final episodeId = episode['episode_id'];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[900]!.withOpacity(0.8),
            Colors.grey[800]!.withOpacity(0.6),
          ],
                              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header de la carte
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '$episodeNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu de la carte
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCardButton(
                        icon: Icons.video_library,
                        label: 'Vidéos',
                        color: Colors.purple,
                        onPressed: () => _showEpisodeUploads(context, episodeId),
                      ),
                      _buildCardButton(
                        icon: Icons.play_circle,
                        label: 'Voir',
                        color: Colors.green,
                        onPressed: () => _showEpisodeVideo(context, episodeId),
                      ),
                    ],
                  ),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCardButton(
                        icon: Icons.upload_file,
                        label: 'Uploader',
                        color: Colors.blue,
                                onPressed: () {
                                  context.push(
                                    '/admin/episode_upload',
                                    extra: {
                                      'movieId': widget.movie.id,
                                      'movieTitle': widget.movie.title,
                              'episodeId': episodeId,
                              'episodeTitle': title,
                                    },
                                  );
                                },
                      ),
                      _buildCardButton(
                        icon: Icons.edit,
                        label: 'Modifier',
                        color: Colors.orange,
                        onPressed: () => _onEditEpisode(episode),
                      ),
                    ],
                  ),
                  
                  // Bouton supprimer
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _onDeleteEpisode(episode),
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Supprimer'),
                                style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                    ),
                              ),
                            ],
                          ),
                ),
              ),
          ],
      ),
    );
  }

  Widget _buildCardButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: Text(label, style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }
}

class EpisodeVideoScreen extends StatefulWidget {
  const EpisodeVideoScreen({Key? key}) : super(key: key);

  @override
  State<EpisodeVideoScreen> createState() => _EpisodeVideoScreenState();
}

class _EpisodeVideoScreenState extends State<EpisodeVideoScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  String? _videoUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_videoUrl == null) {
      final state = GoRouterState.of(context);
      final extra = state.extra as Map<String, dynamic>?;
      _videoUrl = extra?['videoUrl'] as String?;
      
      if (_videoUrl != null) {
        _controller = VideoPlayerController.network(_videoUrl!)
          ..initialize().then((_) {
            if (mounted) {
              setState(() {
                _isInitialized = true;
              });
            }
          });
      }
    }
  }

  @override
  void dispose() {
    if (_videoUrl != null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoUrl == null || _videoUrl!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Erreur'),
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.orange),
            onPressed: () => context.go('/admin'),
          ),
        ),
        backgroundColor: Colors.black,
        body: const Center(
          child: Text('Aucune vidéo à afficher', style: TextStyle(color: Colors.red, fontSize: 18)),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecture de la vidéo'),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () => context.go('/admin'),
        ),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton(
              backgroundColor: Colors.orange,
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
} 