import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/director.dart';
import '../../services/auth_service.dart';
//import '../../services/movie_service.dart';
//import 'admin_director_form_screen.dart';
import 'package:http/http.dart' as http;
import '../../models/movie.dart';
import 'dart:convert';
//import 'admin_director_movies_screen.dart';
//import 'package:intl/intl.dart';
//import '../../config/api_config.dart';
import '../../config/environment.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDirectorsScreen extends StatefulWidget {
  const AdminDirectorsScreen({Key? key}) : super(key: key);

  @override
  State<AdminDirectorsScreen> createState() => _AdminDirectorsScreenState();
}

class _AdminDirectorsScreenState extends State<AdminDirectorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Director> _directors = [];
  String _search = '';
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _directorStats = {};
  List<dynamic> _directorRevenue = [];
  List<dynamic> _topEpisodes = [];
  String? _statsError;
  bool _statsLoading = true;
  List<dynamic> _directorOverview = [];

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.checkAuthStatus();
    _loadDirectorStats();
    _loadDirectors();
  }

  Future<void> _loadDirectors() async {
    print('Chargement des réalisateurs...');
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final realisateurs = await authService.getRealisateurs();

      // Récupérer tous les films validés
      final response = await http.get(Uri.parse('${Environment.apiBaseUrl}/movies/movies'));
      print('Réponse films (status: ${response.statusCode}): ${response.body}');
      List<dynamic> data = [];
      if (response.statusCode == 200) {
        data = json.decode(response.body);
      }
      final allMovies = data.map((e) => Movie.fromJson(e)).toList();

      print('--- DEBUG FILMS ---');
      for (var m in allMovies) {
        print('id: ${m.id} | directorId: ${m.directorId} | status: ${m.status} | title: ${m.title}');
      }
      print('--- DEBUG REALISATEURS ---');
      for (var r in realisateurs) {
        print('user_id: ${r['user_id'] ?? r['id'] ?? ''} | id: ${r['id'] ?? ''} | email: ${r['email'] ?? ''} | username: ${r['username'] ?? ''}');
      }
      setState(() {
        _directors = realisateurs.map((r) {
          final id = (r['user_id'] ?? r['id'] ?? '').toString();
          final email = r['email'] ?? '';
          final username = r['username'] ?? '';
          final filmsCount = allMovies.where((m) =>
            m.directorId.toString() == id && m.status == 'approved'
          ).length;
          return Director(
            id: id,
            name: username,
            email: email,
            created: r['created_at'] ?? DateTime.now().toIso8601String().substring(0, 10),
            films: filmsCount,
          );
        }).toList();
        _isLoading = false;
      });
      print('Chargement terminé. Nb réalisateurs: ${_directors.length}');
    } catch (e) {
      print('Erreur lors du chargement des réalisateurs: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDirectorStats() async {
    try {
      setState(() {
        _statsError = null;
        _statsLoading = true;
      });
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.jwtToken;
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/admin/stats/directors?period=30'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      print('Réponse stats réalisateurs: \\n${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          _directorStats = data;
          _directorOverview = data['directorOverview'] ?? [];
          _directorRevenue = data['directorRevenue'] ?? [];
          _topEpisodes = data['topEpisodes'] ?? [];
          _topEpisodes = data['Listes des réalisateurs'] ?? [];
          _statsLoading = false;
        });
        print('Contenu de _directorOverview: \n${_directorOverview.toString()}');
      } else {
        setState(() {
          _statsError = 'Erreur lors du chargement des statistiques réalisateurs';
          _statsLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statsError = e.toString();
        _statsLoading = false;
      });
    }
  }

  Future<void> _showEditDialog(Director director) async {
    final TextEditingController nameController = TextEditingController(text: director.name);
    final TextEditingController emailController = TextEditingController(text: director.email);
    bool isUpdating = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Modifier le réalisateur', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
            ),
            if (isUpdating)
              const CircularProgressIndicator(color: Colors.orange)
            else
              TextButton(
                onPressed: () async {
                  try {
                    setDialogState(() {
                      isUpdating = true;
                    });
                    
                    final authService = Provider.of<AuthService>(context, listen: false);
                    final success = await authService.updateUser(
                      director.id,
                      nameController.text,
                      emailController.text,
                    );
                    
                    if (!mounted) return;
                    Navigator.pop(context);
                    
                    if (success) {
                      _loadDirectors(); // Actualiser la liste après modification
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Réalisateur modifié avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(authService.error ?? 'Échec de la modification'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Enregistrer', style: TextStyle(color: Colors.orange)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Director director) async {
    bool isDeleting = false;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Confirmation', style: TextStyle(color: Colors.white)),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer le réalisateur "${director.name}" ?',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
            ),
            if (isDeleting)
              const CircularProgressIndicator(color: Colors.red)
            else
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    isDeleting = true;
                  });
                  Navigator.pop(context, true);
                },
                child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
    
    if (confirm == true) {
      setState(() => _isLoading = true);
      
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final success = await authService.deleteRealisateur(director.id);
        
        if (success) {
          _loadDirectors(); // Actualiser la liste après suppression
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Réalisateur supprimé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authService.error ?? 'Erreur lors de la suppression'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Ajout : Fonction pour créer un réalisateur
  void _onAddDirector() {
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau réalisateur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final response = await http.post(
                Uri.parse('${Environment.apiBaseUrl}/auth/register'),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  'username': _nameController.text,
                  'email': _emailController.text,
                  'password': _passwordController.text,
                  'role': 'realisateur',
                }),
              );
              if (response.statusCode == 201) {
                Navigator.pop(context);
                _loadDirectors();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Réalisateur ajouté !')),
                );
              } else {
                String msg = 'Erreur lors de l\'ajout';
                try {
                  final err = json.decode(response.body);
                  if (err is Map && err['message'] != null) msg = err['message'];
                } catch (_) {}
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg)),
                );
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  // Ajout : Fonction pour afficher les films d'un réalisateur
  void _showDirectorMovies(String directorId) async {
    try {
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/movies/director/$directorId'),
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List movies = [];
        if (decoded is List) {
          movies = decoded;
        } else if (decoded is Map && decoded['message'] != null) {
          movies = [];
        } else {
          movies = [];
        }
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.movie, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('Films du réalisateur', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: movies.isEmpty
                  ? const Text('Aucun film trouvé', style: TextStyle(color: Colors.white70))
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: movies.length,
                      separatorBuilder: (context, i) => Divider(color: Colors.white24),
                      itemBuilder: (context, i) {
                        final film = movies[i];
                        return ListTile(
                          leading: const Icon(Icons.local_movies, color: Colors.deepPurple),
                          title: Text(
                            film['title'] ?? '',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: film['release_date'] != null
                              ? Text(
                                  'Sortie : ${film['release_date']}',
                                  style: const TextStyle(color: Colors.orange, fontSize: 13),
                                )
                              : null,
                        );
                      },
                    ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        String msg = 'Erreur lors de la récupération des films';
        try {
          final err = json.decode(response.body);
          if (err is Map && err['message'] != null) msg = err['message'];
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur réseau : $e')),
      );
    }
  }

  void _showDirectorDetailDialog(Director director, dynamic revenue, dynamic topEp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.person, color: Colors.orange),
            const SizedBox(width: 8),
            Text(director.name, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email : ${director.email}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Nombre de films : ${director.films}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Vues totales : ${revenue['total_views'] ?? 0}', style: const TextStyle(color: Colors.white70)),
            Text('Revenu total : ${revenue['estimated_revenue'] ?? 0} FCFA', style: const TextStyle(color: Colors.white70)),
            if (topEp != null) ...[
              const SizedBox(height: 8),
              Text('Top épisode : ${topEp['episode_title']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              Text('Vues épisode : ${topEp['view_count'] ?? 0}', style: const TextStyle(color: Colors.white70)),
              Text('Revenu épisode : ${topEp['estimated_revenue'] ?? 0} FCFA', style: const TextStyle(color: Colors.white70)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _showDirectorMovies(director.id),
            child: const Text('Voir les films', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () => _showEditDialog(director),
            child: const Text('Modifier', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => _showDeleteConfirmation(director),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('BUILD: _isLoading=$_isLoading, _error=$_error, _directors.length=${_directors.length}');
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[900],
                  borderRadius: BorderRadius.circular(8),
                ),
          child: Text(
                  'Erreur: $_error',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            // En-tête avec titre et bouton d'ajout
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Gestion des Réalisateurs',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _onAddDirector,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Ajouter', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Barre de recherche
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
                      child: TextField(
                        controller: _searchController,
                style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un réalisateur...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                        onChanged: (value) {
                          setState(() {
                            _search = value;
                          });
                        },
                      ),
            ),
            const SizedBox(height: 24),

            // Statistiques globales
            if (!_statsLoading && _directorStats.isNotEmpty) ...[
              if (_directorStats.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      final crossAxisCount = isMobile ? 2 : 3;
                      final childAspectRatio = isMobile ? 1.3 : 1.8;
                      
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: childAspectRatio,
                        children: [
                          _buildStatCard(
                            'Total réalisateurs',
                            _directorStats['total_directors']?.toString() ?? '-',
                            Icons.people,
                            Colors.blue,
                          ),
                          _buildStatCard(
                            'Période',
                            '${_directorStats['period'] ?? '-'} jours',
                            Icons.calendar_today,
                            Colors.orange,
                          ),
                          _buildStatCard(
                            'Revenu par vue',
                            '${_directorStats['revenuePerView'] ?? '-'} FCFA',
                            Icons.monetization_on,
                            Colors.green,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_directorRevenue.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Classement des réalisateurs et Top épisodes', 
                  style: GoogleFonts.poppins(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 18
                  )
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    
                    if (isMobile) {
                      // Version mobile avec cartes
                      return Column(
                        children: _directorRevenue.map((d) {
                          final topEp = _topEpisodes.firstWhere(
                            (e) => (e['director_name'] ?? '') == (d['director_name'] ?? ''),
                            orElse: () => null,
                          );
                          final director = findDirectorByName(d['director_name'] ?? '');
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: Colors.grey[850],
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.orange,
                                        child: Text(
                                          (d['director_name'] ?? '?')[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              d['director_name'] ?? '-',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              director?.email ?? '-',
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.movie, color: Colors.orange, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${director?.films ?? 0} films',
                                        style: const TextStyle(color: Colors.orange),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.visibility, color: Colors.blue, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${d['total_views'] ?? 0} vues',
                                        style: const TextStyle(color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.monetization_on, color: Colors.green, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${d['estimated_revenue'] ?? 0} FCFA',
                                        style: const TextStyle(color: Colors.green),
                                      ),
                                    ],
                                  ),
                                  if (topEp != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Top épisode: ${topEp['episode_title'] ?? '-'}',
                                      style: const TextStyle(
                                        color: Colors.purple,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${topEp['view_count'] ?? 0} vues - ${topEp['estimated_revenue'] ?? 0} FCFA',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    } else {
                      // Version desktop avec DataTable
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.grey[850]),
                          columns: const [
                            DataColumn(label: Text('Nom', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Films', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Vues totales', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Revenu total', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Top épisode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Vues épisode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Revenu épisode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          ],
                          rows: _directorRevenue.map((d) {
                            final topEp = _topEpisodes.firstWhere(
                              (e) => (e['director_name'] ?? '') == (d['director_name'] ?? ''),
                              orElse: () => null,
                            );
                            final director = findDirectorByName(d['director_name'] ?? '');
                            return DataRow(
                              onSelectChanged: (_) {
                                if (director != null) {
                                  _showDirectorDetailDialog(director, d, topEp);
                                }
                              },
                              cells: [
                                DataCell(Text(d['director_name'] ?? '-', style: const TextStyle(color: Colors.white))),
                                DataCell(Text(director?.email ?? '-', style: const TextStyle(color: Colors.white))),
                                DataCell(Text(director != null ? '${director.films}' : '-', style: const TextStyle(color: Colors.white))),
                                DataCell(Text('${d['total_views'] ?? 0}', style: const TextStyle(color: Colors.white))),
                                DataCell(Text('${d['estimated_revenue'] ?? 0} FCFA', style: const TextStyle(color: Colors.white))),
                                DataCell(Text(topEp != null ? (topEp['episode_title'] ?? '-') : '-', style: const TextStyle(color: Colors.white))),
                                DataCell(Text(topEp != null ? '${topEp['view_count'] ?? 0}' : '-', style: const TextStyle(color: Colors.white))),
                                DataCell(Text(topEp != null ? '${topEp['estimated_revenue'] ?? 0} FCFA' : '-', style: const TextStyle(color: Colors.white))),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    }
                  },
                ),
              ],
            ],

            // Liste des réalisateurs ou états
            //if (_isLoading)
            //  Column(
            //    crossAxisAlignment: CrossAxisAlignment.start,
            //    children: [
            //      const Text('Liste des réalisateurs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            //      const SizedBox(height: 16),
            //      const Center(child: CircularProgressIndicator(color: Colors.orange)),
            //    ],
            //  )
            //else if (_directors.isEmpty)
            //  Container(
            //    alignment: Alignment.center,
            //    padding: const EdgeInsets.symmetric(vertical: 40),
            //    child: const Text(
            //      'Aucun réalisateur trouvé',
            //      style: TextStyle(color: Colors.white70, fontSize: 18),
            //    ),
            //  )
            //else
            //  ..._buildDirectorsListAsWidgets(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final iconSize = isMobile ? 16.0 : 24.0;
        final valueFontSize = isMobile ? 14.0 : 24.0;
        final titleFontSize = isMobile ? 9.0 : 14.0;
        final padding = isMobile ? 8.0 : 20.0;
        
        return Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: iconSize),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: titleFontSize,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Nouvelle version : retourne une liste de widgets pour chaque réalisateur
  List<Widget> _buildDirectorsListAsWidgets() {
    final filteredDirectors = _directors.where((director) {
      return director.name.toLowerCase().contains(_search.toLowerCase()) ||
             director.email.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    if (filteredDirectors.isEmpty) {
      return [
        const Center(
          child: Text(
            'Aucun réalisateur trouvé',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ),
      ];
    }

    return filteredDirectors.map((director) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: Colors.grey[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isMobile ? _buildMobileDirectorCard(director) : _buildDesktopDirectorCard(director),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildMobileDirectorCard(Director director) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.orange,
              child: Text(
                director.name.isNotEmpty ? director.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    director.name.isNotEmpty ? director.name : '(inconnu)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    director.email,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.movie, color: Colors.orange, size: 16),
            const SizedBox(width: 4),
            Text(
              '${director.films} films',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showDirectorMovies(director.id),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('Voir films', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showEditDialog(director),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Modifier', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showDeleteConfirmation(director),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Supprimer', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopDirectorCard(Director director) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.orange,
          child: Text(
            director.name.isNotEmpty ? director.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                director.name.isNotEmpty ? director.name : '(inconnu)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                director.email,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.movie, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${director.films} films',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, color: Colors.blue),
              tooltip: 'Voir les films',
              onPressed: () => _showDirectorMovies(director.id),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              tooltip: 'Modifier',
              onPressed: () => _showEditDialog(director),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Supprimer',
              onPressed: () => _showDeleteConfirmation(director),
            ),
          ],
        ),
      ],
    );
  }

  Director? findDirectorByName(String name) {
    try {
      return _directors.firstWhere((dir) => dir.name == name);
    } catch (_) {
      return null;
    }
  }
}