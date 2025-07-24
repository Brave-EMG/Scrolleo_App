import 'package:flutter/material.dart';
import '../../models/movie.dart';
import 'admin_movie_details_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../../widgets/movie_card.dart';
import 'admin_manage_episodes_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import '../../config/environment.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminMoviesScreen extends StatefulWidget {
  const AdminMoviesScreen({Key? key}) : super(key: key);

  @override
  State<AdminMoviesScreen> createState() => _AdminMoviesScreenState();
}

class _AdminMoviesScreenState extends State<AdminMoviesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  bool _isLoading = false;
  String? _error;
  List<Movie> _movies = [];
  List<Movie> _filteredMovies = [];
  bool _showAddMovieForm = false;
  List<Map<String, dynamic>> _directors = [];
  Map<String, dynamic>? _selectedDirector;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _episodesCountController = TextEditingController();
  final TextEditingController _seasonController = TextEditingController();
  String? _coverImagePath;
  DateTime? _selectedDate;
  final List<String> _availableGenres = [
    'Action', 'Comédie', 'Drame', 'Science-Fiction', 'Horreur', 'Romance', 'Documentaire', 'Animation', 'Thriller', 'Aventure'
  ];
  List<String> _selectedGenres = [];
  Uint8List? _coverImageBytes;
  Map<String, dynamic> _contentStats = {};
  List<dynamic> _popularContent = [];
  int? _contentStatsStatusCode;
  String? _contentStatsRawJson;
  bool _isExclusive = false;

  @override
  void initState() {
    super.initState();
    _fetchMovies();
    _fetchDirectors();
    _fetchContentStats();
  }

  void _filterMovies() {
    final query = _search.toLowerCase();
    setState(() {
      _filteredMovies = _movies.where((movie) {
        return movie.title.toLowerCase().contains(query) ||
               movie.genres.any((genre) => genre.toLowerCase().contains(query)) ||
               movie.director.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _fetchMovies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse('${Environment.apiBaseUrl}/movies/movies'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> data = decoded is List ? decoded : (decoded['data'] ?? []);
        final List<Movie> moviesList = data.map((e) => Movie.fromJson(e)).toList();
        
        // Trier les films par date de création (plus récents en premier)
        moviesList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        setState(() {
          _movies = moviesList;
          _filteredMovies = moviesList;
          _isLoading = false;
        });
        
        // LOG : Afficher tous les films avec leur date de sortie
        print('--- LISTE DES FILMS ---');
        for (var m in moviesList) {
          print('Film : \u001b[33m${m.title} | Date de sortie: \u001b[36m${m.releaseDate.year}-${m.releaseDate.month.toString().padLeft(2, '0')}-${m.releaseDate.day.toString().padLeft(2, '0')} | ID: ${m.id}');
        }
        print('-----------------------');
      } else if (response.statusCode == 404) {
        setState(() {
          _movies = [];
          _filteredMovies = [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Erreur serveur: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur réseau: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDirectors() async {
    try {
      final response = await http.get(Uri.parse('${Environment.apiBaseUrl}/auth/users/realisateurs'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _directors = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _fetchContentStats() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.jwtToken;
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/admin/stats/content'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      setState(() {
        _contentStatsStatusCode = response.statusCode;
        _contentStatsRawJson = response.body;
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          _contentStats = data['overview'] ?? {};
          _popularContent = data['popularContent'] ?? [];
        });
      }
    } catch (e) {
      // ignore
    }
  }

  void _showAddMovieDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Ajouter un film', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
          content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Titre',
                      hintText: 'Ex: Cendrillon',
                      labelStyle: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent)),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Décrivez le film...',
                      labelStyle: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent)),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _episodesCountController,
                    decoration: InputDecoration(
                      labelText: 'Nombre d\'épisodes',
                      hintText: 'Ex: 10',
                      labelStyle: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent)),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _seasonController,
                    decoration: InputDecoration(
                      labelText: 'Saison (optionnel)',
                      hintText: 'Ex: 1',
                      labelStyle: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent)),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedDirector,
                    decoration: InputDecoration(
                      labelText: 'Réalisateur',
                      labelStyle: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    dropdownColor: Colors.grey[900],
                    items: _directors.map((director) {
                      return DropdownMenuItem(
                        value: director,
                        child: Text(
                          director['username'] ?? director['email'] ?? 'Inconnu',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDirector = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Text('Genres', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: _availableGenres.map((genre) {
                      final isSelected = _selectedGenres.contains(genre);
                      return FilterChip(
                        label: Text(genre, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.w600)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedGenres.add(genre);
                            } else {
                              _selectedGenres.remove(genre);
                            }
                          });
                        },
                        backgroundColor: Colors.grey[800],
                        selectedColor: Colors.blueAccent,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: isSelected ? 4 : 0,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Switch(
                        value: _isExclusive,
                        onChanged: (value) {
                          setState(() {
                            _isExclusive = value;
                          });
                        },
                        activeColor: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text('Exclusivités ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        allowMultiple: false,
                      );
                      if (result != null) {
                        setState(() {
                          _coverImagePath = result.files.single.name;
                          _coverImageBytes = result.files.single.bytes;
                        });
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: Text(_coverImagePath ?? 'Choisir une image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                  if (_coverImageBytes != null) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _coverImageBytes!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Colors.blueAccent,
                                onPrimary: Colors.white,
                                surface: Colors.grey,
                                onSurface: Colors.white,
                              ),
                              dialogBackgroundColor: Colors.grey[900],
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = DateTime.utc(date.year, date.month, date.day);
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_selectedDate?.toString().split(' ')[0] ?? 'Choisir une date'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetForm();
              },
              child: const Text('Annuler', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_selectedDirector == null || _selectedDate == null || _selectedGenres.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
                    );
                    return;
                  }

                  try {
                    final request = http.MultipartRequest(
                      'POST',
                      Uri.parse('${Environment.apiBaseUrl}/movies/create'),
                    );

                    request.fields['title'] = _titleController.text;
                    request.fields['description'] = _descriptionController.text;
                    request.fields['episodes_count'] = _episodesCountController.text;
                    if (_seasonController.text.isNotEmpty) {
                      request.fields['season'] = _seasonController.text;
                    }
                    request.fields['director_id'] = _selectedDirector!['user_id'].toString();
                    request.fields['release_date'] = _selectedDate!.toIso8601String();
                    request.fields['genre'] = _selectedGenres.join(',');
                    request.fields['status'] = _isExclusive ? 'Exclusive' : 'NoExclusive';

                    if (_coverImageBytes != null) {
                      request.files.add(
                        http.MultipartFile.fromBytes(
                          'cover_image',
                          _coverImageBytes!,
                          filename: _coverImagePath,
                        ),
                      );
                    }

                    print('--- AJOUT FILM ---');
                    print('title: ${_titleController.text}');
                    print('description: ${_descriptionController.text}');
                    print('episodes_count: ${_episodesCountController.text}');
                    print('season: ${_seasonController.text}');
                    print('director_id: ${_selectedDirector!['user_id'].toString()}');
                    print('release_date: ${_selectedDate!.toIso8601String()}');
                    print('genre: ${_selectedGenres.join(',')}');
                    print('cover_image: ${_coverImagePath}');

                    final response = await request.send();
                    if (response.statusCode == 201) {
                      Navigator.pop(context);
                      _resetForm();
                      
                      // Afficher un message de succès
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Film ajouté avec succès'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      
                      // Attendre un peu puis rafraîchir la liste
                      await Future.delayed(const Duration(milliseconds: 500));
                      await _fetchMovies();
                      
                    } else {
                      throw Exception('Erreur lors de l\'ajout du film: ${response.statusCode}');
                    }
      } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                child: const Text('Ajouter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _episodesCountController.clear();
    _seasonController.clear();
    _selectedDirector = null;
    _selectedGenres = [];
    _coverImagePath = null;
    _coverImageBytes = null;
    _selectedDate = null;
    _isExclusive = false;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_contentStats.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        final crossAxisCount = isMobile ? 2 : 4;
                        final childAspectRatio = isMobile ? 1.3 : 1.8;
                        
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: childAspectRatio,
                          children: [
                            _statCard('Total films', _contentStats['total_movies']?.toString() ?? '-', Icons.movie, Colors.blue),
                            _statCard('Total épisodes', _contentStats['total_episodes']?.toString() ?? '-', Icons.video_library, Colors.orange),
                            _statCard('Nouveaux films (30j)', _contentStats['new_movies_30d']?.toString() ?? '-', Icons.fiber_new, Colors.green),
                            _statCard('Nouveaux épisodes (30j)', _contentStats['new_episodes_30d']?.toString() ?? '-', Icons.fiber_new, Colors.purple),
                          ],
                        );
                      },
                    ),
                  ),
                  // Graphe barres nouveaux films/épisodes
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Card(
                      color: Colors.grey[900],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ajouts récents (30 derniers jours)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 220,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: [
                                    double.tryParse(_contentStats['new_movies_30d']?.toString() ?? '0') ?? 0,
                                    double.tryParse(_contentStats['new_episodes_30d']?.toString() ?? '0') ?? 0
                                  ].reduce((a, b) => a > b ? a : b) + 2,
                                  barTouchData: BarTouchData(enabled: false),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          if (value == value.toInt()) {
                                            return Text(
                                              value.toInt().toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          switch (value.toInt()) {
                                            case 0:
                                              return const Text('Films', style: TextStyle(color: Colors.green));
                                            case 1:
                                              return const Text('Épisodes', style: TextStyle(color: Colors.purple));
                                            default:
                                              return const SizedBox.shrink();
                                          }
                                        },
                                        reservedSize: 32,
                                      ),
                                    ),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: [
                                    BarChartGroupData(x: 0, barRods: [
                                      BarChartRodData(
                                        toY: double.tryParse(_contentStats['new_movies_30d']?.toString() ?? '0') ?? 0,
                                        color: Colors.green,
                                        width: 32,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ]),
                                    BarChartGroupData(x: 1, barRods: [
                                      BarChartRodData(
                                        toY: double.tryParse(_contentStats['new_episodes_30d']?.toString() ?? '0') ?? 0,
                                        color: Colors.purple,
                                        width: 32,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ]),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_popularContent.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Card(
                        color: Colors.grey[900],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Contenu populaire', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 220,
                                child: PieChart(
                                  PieChartData(
                                    sections: _popularContent.map((item) {
                                      final value = double.tryParse(item['view_count']?.toString() ?? '0') ?? 0;
                                      return PieChartSectionData(
                                        value: value,
                                        title: '${item['title'] ?? '-'}\n${item['view_count'] ?? 0} vues',
                                        radius: 80,
                                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Liste des films',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _showAddMovieDialog,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Ajouter', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _search = value;
                        _filterMovies();
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par titre, genre ou réalisateur...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search, color: Colors.orange),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: Colors.orange))
                else if (_error != null)
                  Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                else if (_filteredMovies.isEmpty)
                  const Center(child: Text('Aucun film trouvé', style: TextStyle(color: Colors.white70)))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredMovies.length,
                    itemBuilder: (context, index) {
                      final movie = _filteredMovies[index];
                      return _buildMovieListItem(movie);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteMovie(Movie movie) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Supprimer le film', style: TextStyle(color: Colors.white)),
        content: Text('Voulez-vous vraiment supprimer "${movie.title}" ?', style: const TextStyle(color: Colors.white70)),
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
        print('Suppression du film avec id: \\${movie.id}');
        final response = await http.delete(Uri.parse('${Environment.apiBaseUrl}/movies/${movie.id}'));
        print('Suppression film: status=\\${response.statusCode}, body=\\${response.body}');
        if (response.statusCode == 200) {
          _fetchMovies();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Film supprimé avec succès')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la suppression')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _showEditMovieDialog(Movie movie) {
    _titleController.text = movie.title;
    _descriptionController.text = movie.description;
    _episodesCountController.text = (movie.episodes_count ?? movie.episodes.length).toString();
    _seasonController.text = movie.season ?? '';
    _selectedGenres = List<String>.from(movie.genres);
    _selectedDate = movie.releaseDate;
    _coverImagePath = null;
    _coverImageBytes = null;
    _selectedDirector = _directors.firstWhere(
      (d) => d['username'] == movie.director || d['user_id'].toString() == movie.directorId.toString(),
      orElse: () => <String, dynamic>{},
    );
    _isExclusive = movie.status == 'Exclusive';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Modifier le film', style: TextStyle(color: Colors.white)),
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
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                ),
                TextField(
                  controller: _episodesCountController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre d\'épisodes',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _seasonController,
                  decoration: const InputDecoration(
                    labelText: 'Saison (optionnel)',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedDirector,
                  decoration: const InputDecoration(
                    labelText: 'Réalisateur',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  items: _directors.map((director) {
                    return DropdownMenuItem(
                      value: director,
                      child: Text(
                        director['username'] ?? director['email'] ?? 'Inconnu',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDirector = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: _availableGenres.map((genre) {
                    final isSelected = _selectedGenres.contains(genre);
                    return FilterChip(
                      label: Text(genre, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedGenres.add(genre);
                          } else {
                            _selectedGenres.remove(genre);
                          }
                        });
                      },
                      backgroundColor: Colors.grey[800],
                      selectedColor: Colors.blue,
                          );
                        }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Switch(
                      value: _isExclusive,
                      onChanged: (value) {
                        setState(() {
                          _isExclusive = value;
                        });
                      },
                      activeColor: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text('Exclusivités', style: TextStyle(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      allowMultiple: false,
                    );
                    if (result != null) {
                      setState(() {
                        _coverImagePath = result.files.single.name;
                        _coverImageBytes = result.files.single.bytes;
                      });
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: Text(_coverImagePath ?? 'Choisir une image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = DateTime.utc(date.year, date.month, date.day);
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_selectedDate?.toString().split(' ')[0] ?? 'Choisir une date'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetForm();
              },
              child: const Text('Annuler', style: TextStyle(color: Colors.orange)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_selectedDirector == null || _selectedDate == null || _selectedGenres.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
                  );
                  return;
                }
                try {
                  final request = http.MultipartRequest(
                    'PUT',
                    Uri.parse('${Environment.apiBaseUrl}/movies/${movie.id}'),
                  );
                  request.fields['title'] = _titleController.text;
                  request.fields['description'] = _descriptionController.text;
                  request.fields['episodes_count'] = _episodesCountController.text;
                  if (_seasonController.text.isNotEmpty) {
                    request.fields['season'] = _seasonController.text;
                  }
                  request.fields['director_id'] = _selectedDirector!['user_id'].toString();
                  request.fields['release_date'] = _selectedDate!.toIso8601String();
                  request.fields['genre'] = _selectedGenres.join(',');
                  request.fields['status'] = _isExclusive ? 'Exclusive' : 'NoExclusive';
                  if (_coverImageBytes != null) {
                    request.files.add(
                      http.MultipartFile.fromBytes(
                        'cover_image',
                        _coverImageBytes!,
                        filename: _coverImagePath,
                      ),
                    );
                  }
                  final response = await request.send();
                  if (response.statusCode == 200) {
                    Navigator.pop(context);
                    _resetForm();
                    _fetchMovies();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Film modifié avec succès')),
                    );
                  } else {
                    throw Exception('Erreur lors de la modification du film');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieListItem(Movie movie) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          
          return Container(
            padding: const EdgeInsets.all(16),
            child: isMobile ? _buildMobileLayout(movie) : _buildDesktopLayout(movie),
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(Movie movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image en haut sur mobile
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[800],
          ),
          child: movie.posterUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    movie.posterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.movie,
                          color: Colors.white,
                          size: 50,
                        ),
                      );
                    },
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.movie,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
        ),
        const SizedBox(height: 16),
        _buildMovieInfo(movie),
      ],
    );
  }

  Widget _buildDesktopLayout(Movie movie) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image à gauche sur desktop
        Container(
          width: 150,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[800],
          ),
          child: movie.posterUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    movie.posterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.movie,
                          color: Colors.white,
                          size: 50,
                        ),
                      );
                    },
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.movie,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(child: _buildMovieInfo(movie)),
      ],
    );
  }

  Widget _buildMovieInfo(Movie movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec titre et badge année
        Row(
          children: [
            Expanded(
              child: Text(
                movie.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                movie.releaseDate.year.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Description
        if (movie.description.isNotEmpty) ...[
          Text(
            movie.description,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
        ],
        
        // Genres
        if (movie.genres.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: movie.genres.map((genre) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.5)),
                ),
                child: Text(
                  genre,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        
        // Informations supplémentaires
        Row(
          children: [
            Icon(Icons.person, color: Colors.grey[400], size: 16),
            const SizedBox(width: 4),
            Text(
              movie.director,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 16),
            Icon(Icons.video_library, color: Colors.grey[400], size: 16),
            const SizedBox(width: 4),
            Text(
              '${movie.episodes_count ?? movie.episodes.length} épisode(s)',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Boutons d'action
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            
            if (isMobile) {
              // Version mobile avec boutons empilés
              return Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showEditMovieDialog(movie),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Modifier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminManageEpisodesScreen(movie: movie),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list, size: 16),
                    label: const Text('Gérer les épisodes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _confirmDeleteMovie(movie),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Supprimer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              );
            } else {
              // Version desktop avec boutons côte à côte
              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showEditMovieDialog(movie),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminManageEpisodesScreen(movie: movie),
                          ),
                        );
                      },
                      icon: const Icon(Icons.list, size: 16),
                      label: const Text('Gérer les épisodes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmDeleteMovie(movie),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Supprimer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final iconSize = isMobile ? 20.0 : 32.0;
        final valueFontSize = isMobile ? 14.0 : 22.0;
        final titleFontSize = isMobile ? 9.0 : 14.0;
        final padding = isMobile ? 8.0 : 16.0;
        
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.15),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: iconSize),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: titleFontSize,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}