import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import 'admin_users_screen.dart';
import 'admin_directors_screen.dart';
import 'admin_movies_screen.dart';
import 'admin_upcoming_movies_screen.dart';
import 'admin_rejected_movies_screen.dart';
import 'admin_stats_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/movie.dart';
import '../../config/environment.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  int? totalUsers;
  bool _isLoading = true;
  String? _error;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _sections = [
    'Utilisateurs',
    'Réalisateurs',
    'Films',
    'Films à venir',
    'Statistiques',
  ];

  @override
  void initState() {
    super.initState();
    fetchUserCount();
  }

  Future<void> fetchUserCount() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse('${Environment.apiBaseUrl}/auth/users/getuser'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          totalUsers = data.length;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error = 'Erreur serveur: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur réseau: $e';
        _isLoading = false;
      });
    }
  }

  void _handleNavigation(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });
    if (MediaQuery.of(context).size.width < 700) {
      _scaffoldKey.currentState?.closeEndDrawer();
    }
  }

  Widget _buildSideMenu() {
    return Container(
      width: 240,
      color: Colors.grey[900],
      child: Column(
        children: [
          const SizedBox(height: 48),
          const Text(
            'Admin Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 48),
          _buildMenuItem(0, Icons.people, 'Utilisateurs'),
          _buildMenuItem(1, Icons.movie, 'Réalisateurs'),
          _buildMenuItem(2, Icons.video_library, 'Films'),
          _buildMenuItem(3, Icons.upcoming, 'Films à venir'),
          _buildMenuItem(4, Icons.bar_chart, 'Statistiques'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                await Provider.of<AuthService>(context, listen: false).signOut();
                if (mounted) {
                  context.go('/login');
                }
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Se déconnecter', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _handleNavigation(index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.white70),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(int index) {
    switch (index) {
      case 0:
        return const AdminUsersScreen();
      case 1:
        return const AdminDirectorsScreen();
      case 2:
        return const AdminMoviesScreen();
      case 3:
        return const AdminUpcomingMoviesScreen();
      case 4:
        return AdminStatsScreen(
          onCardTap: (int newIndex) {
            setState(() {
              _selectedIndex = newIndex;
            });
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showMovieDetails(Movie movie) {
    print('Bouton cliqué pour : ${movie.title}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Détail du film', style: TextStyle(color: Colors.white)),
        content: Text('Titre : ${movie.title}', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final role = authService.currentUserRole;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    print('Rôle de l\'utilisateur : $role');
    print('Index sélectionné : $_selectedIndex');
    
    if (role != 'admin') {
      Future.microtask(() {
        context.go('/login');
      });
      return const SizedBox.shrink();
    }

    if (isMobile) {
      // Version mobile avec drawer
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await authService.signOut();
                if (mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        ),
        drawer: _buildMobileDrawer(),
        body: Container(
          color: Colors.grey[900],
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildSection(_selectedIndex),
                    ),
        ),
      );
    } else {
      // Version desktop avec sidebar fixe
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Row(
            children: [
              SizedBox(
                width: 240,
                child: _buildSideMenu(),
              ),
              Expanded(
                child: Container(
                  color: Colors.grey[900],
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: _buildSection(_selectedIndex),
                            ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: Colors.grey[900],
      child: Column(
        children: [
          const SizedBox(height: 48),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Admin Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildMobileMenuItem(0, Icons.people, 'Utilisateurs'),
          _buildMobileMenuItem(1, Icons.movie, 'Réalisateurs'),
          _buildMobileMenuItem(2, Icons.video_library, 'Films'),
          _buildMobileMenuItem(3, Icons.upcoming, 'Films à venir'),
          _buildMobileMenuItem(4, Icons.bar_chart, 'Statistiques'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Provider.of<AuthService>(context, listen: false).signOut();
                  if (mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Se déconnecter', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMenuItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : Colors.white70,
        size: 24,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue.withOpacity(0.15),
      onTap: () {
        _handleNavigation(index);
        Navigator.pop(context); // Ferme le drawer
      },
    );
  }
} 