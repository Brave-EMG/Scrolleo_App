import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
// import 'package:http/http.dart' as http;
// import '../../models/movie.dart';

// class AdminRejectedMoviesScreen extends StatefulWidget {
//   const AdminRejectedMoviesScreen({Key? key}) : super(key: key);

//   @override
//   _AdminRejectedMoviesScreenState createState() => _AdminRejectedMoviesScreenState();
// }

// class _AdminRejectedMoviesScreenState extends State<AdminRejectedMoviesScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   List<Movie> rejectedMovies = [];
//   String _search = '';
//   bool _isLoading = true;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     fetchRejectedMovies();
//   }

//   Future<void> fetchRejectedMovies() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });
//     try {
//       print('Tentative de récupération des films rejetés...');
//       final response = await http.get(Uri.parse('${Environment.apiBaseUrl}/movies/rejected'));
//       print('Réponse du serveur: ${response.statusCode}');
//       print('Corps de la réponse: ${response.body}');
      
//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body);
//         print('Données reçues: $data');
//         final List<Movie> moviesList = data.map((e) {
//           print('Film rejeté reçu : $e');
//           return Movie(
//             id: e['id']?.toString() ?? e['movie_id']?.toString() ?? e['_id']?.toString() ?? '',
//             title: e['title'] ?? '',
//             description: e['description'] ?? '',
//             posterUrl: e['cover_image'] ?? '',
//             videoUrl: '',
//             director: e['director_username']?.toString() ?? e['director_id']?.toString() ?? '',
//             directorId: e['director_id']?.toString() ?? '',
//             releaseDate: DateTime.tryParse(e['release_date'] ?? '') ?? DateTime.now(),
//             duration: const Duration(minutes: 90),
//             rating: 0.0,
//             genres: e['genre'] != null ? [e['genre'].toString()] : [],
//             backdropUrl: '',
//           );
//         }).toList();
//         setState(() {
//           rejectedMovies = moviesList;
//           _isLoading = false;
//         });
//       } else if (response.statusCode == 404) {
//         print('Aucun film rejeté trouvé');
//         setState(() {
//           rejectedMovies = [];
//           _isLoading = false;
//         });
//       } else {
//         print('Erreur serveur: ${response.statusCode}');
//         setState(() {
//           _error = 'Erreur serveur: ${response.statusCode}';
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Erreur lors de la récupération des films: $e');
//       setState(() {
//         _error = 'Erreur réseau: $e';
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> reacceptMovie(Movie movie) async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });
//     try {
//       final response = await http.patch(
//         Uri.parse('${Environment.apiBaseUrl}/movies/${movie.id}/approve'),
//       );
//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Film réaccepté avec succès')),
//         );
//         await fetchRejectedMovies();
//       } else {
//         setState(() {
//           _error = 'Erreur lors de la réacceptation du film: ${response.statusCode}';
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _error = 'Erreur réseau lors de la réacceptation: $e';
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> deleteMovie(Movie movie) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: Colors.grey[900],
//         title: const Text('Supprimer le film', style: TextStyle(color: Colors.white)),
//         content: Text('Voulez-vous vraiment supprimer définitivement "${movie.title}" ?', style: const TextStyle(color: Colors.white70)),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Annuler', style: TextStyle(color: Colors.orange)),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child: const Text('Supprimer'),
//           ),
//         ],
//       ),
//     );
//     if (confirm == true) {
//       setState(() { _isLoading = true; });
//       try {
//         final response = await http.delete(Uri.parse('${Environment.apiBaseUrl}/movies/movies/${movie.id}'));
//         if (response.statusCode == 200) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Film supprimé définitivement')),
//           );
//           await fetchRejectedMovies();
//         } else {
//           setState(() { _error = 'Erreur lors de la suppression du film (${response.statusCode})'; });
//         }
//       } catch (e) {
//         setState(() { _error = 'Erreur réseau lors de la suppression: $e'; });
//       } finally {
//         setState(() { _isLoading = false; });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filteredMovies = rejectedMovies.where((m) {
//       return m.title.toLowerCase().contains(_search.toLowerCase()) ||
//           m.director.toLowerCase().contains(_search.toLowerCase());
//     }).toList();

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final isMobile = constraints.maxWidth < 700;
//         return SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _searchController,
//                       decoration: InputDecoration(
//                         hintText: 'Rechercher un film rejeté...',
//                         prefixIcon: const Icon(Icons.search, color: Colors.white70),
//                         filled: true,
//                         fillColor: Colors.grey[900],
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide.none,
//                         ),
//                       ),
//                       style: const TextStyle(color: Colors.white),
//                       onChanged: (value) {
//                         setState(() {
//                           _search = value;
//                         });
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//               if (_isLoading)
//                 const Center(child: CircularProgressIndicator())
//               else if (_error != null)
//                 Center(
//                   child: Text(
//                     _error!,
//                     style: const TextStyle(color: Colors.red),
//                   ),
//                 )
//               else if (filteredMovies.isEmpty)
//                 const Center(
//                   child: Text(
//                     'Aucun film rejeté trouvé',
//                     style: TextStyle(color: Colors.white70),
//                   ),
//                 )
//               else
//                 GridView.builder(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: isMobile ? 1 : 3,
//                     childAspectRatio: 0.7,
//                     crossAxisSpacing: 16,
//                     mainAxisSpacing: 16,
//                   ),
//                   itemCount: filteredMovies.length,
//                   itemBuilder: (context, index) {
//                     final movie = filteredMovies[index];
//                     return Card(
//                       clipBehavior: Clip.antiAlias,
//                       color: Colors.grey[900],
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Expanded(
//                             child: Stack(
//                               fit: StackFit.expand,
//                               children: [
//                                 Image.network(
//                                   movie.posterUrl,
//                                   fit: BoxFit.cover,
//                                   errorBuilder: (context, error, stackTrace) {
//                                     return Container(
//                                       color: Colors.grey[800],
//                                       child: const Icon(Icons.movie, size: 50, color: Colors.white54),
//                                     );
//                                   },
//                                 ),
//                                 Positioned(
//                                   bottom: 0,
//                                   left: 0,
//                                   right: 0,
//                                   child: Container(
//                                     padding: const EdgeInsets.all(8),
//                                     decoration: BoxDecoration(
//                                       gradient: LinearGradient(
//                                         begin: Alignment.bottomCenter,
//                                         end: Alignment.topCenter,
//                                         colors: [
//                                           Colors.black.withOpacity(0.8),
//                                           Colors.transparent,
//                                         ],
//                                       ),
//                                     ),
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           movie.title,
//                                           style: const TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 16,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                           maxLines: 2,
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Text(
//                                           'Réalisateur: ${movie.director}',
//                                           style: TextStyle(
//                                             color: Colors.white.withOpacity(0.7),
//                                             fontSize: 14,
//                                           ),
//                                           maxLines: 1,
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(12),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Expanded(
//                                   child: Text(
//                                     movie.description,
//                                     style: TextStyle(
//                                       color: Colors.white.withOpacity(0.7),
//                                       fontSize: 14,
//                                     ),
//                                     maxLines: 2,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 ElevatedButton(
//                                   onPressed: () => reacceptMovie(movie),
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.green,
//                                     foregroundColor: Colors.white,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                   ),
//                                   child: const Text('Réaccepter'),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 ElevatedButton.icon(
//                                   onPressed: () => deleteMovie(movie),
//                                   icon: const Icon(Icons.delete, color: Colors.white, size: 18),
//                                   label: const Text('Supprimer'),
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.red,
//                                     foregroundColor: Colors.white,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// } 