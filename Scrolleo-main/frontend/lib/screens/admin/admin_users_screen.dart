import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'admin_user_details_dialog.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import '../../config/environment.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  String _search = '';
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _userStats = {};
  List<dynamic> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _loadUserStats();
    _loadUsers();
  }

  Future<void> _loadUserStats() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.jwtToken;
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/admin/stats/users'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          _userStats = data['users'] ?? {};
          _subscriptions = data['subscriptions'] ?? [];
        });
      } else {
        setState(() {
          _error = 'Erreur lors du chargement des statistiques utilisateurs';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final users = await authService.getAllUsers();
      
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> user) async {
    final TextEditingController nameController = TextEditingController(text: user['username']);
    final TextEditingController emailController = TextEditingController(text: user['email']);
    bool isUpdating = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Modifier l\'utilisateur', style: TextStyle(color: Colors.white)),
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
                      user['user_id'].toString(),
                      nameController.text,
                      emailController.text,
                    );
                    
                    if (!mounted) return;
                    Navigator.pop(context);
                    
                    if (success) {
                      _loadUsers();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Utilisateur modifié avec succès'),
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

  Future<void> _showDeleteConfirmation(Map<String, dynamic> user) async {
    bool isDeleting = false;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Confirmation', style: TextStyle(color: Colors.white)),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer l\'utilisateur "${user['username']}" ?',
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
        final success = await authService.deleteUser(user['user_id'].toString());
        
        if (success) {
          _loadUsers();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Utilisateur supprimé avec succès'),
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

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((user) {
      return user['username'].toString().toLowerCase().contains(_search.toLowerCase()) ||
          user['email'].toString().toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_userStats.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
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
                            _buildStatCard('Total utilisateurs', _userStats['total_users']?.toString() ?? '-', Icons.people, Colors.blue),
                            _buildStatCard('Admins', _userStats['admin_count']?.toString() ?? '-', Icons.admin_panel_settings, Colors.red),
                            _buildStatCard('Réalisateurs', _userStats['director_count']?.toString() ?? '-', Icons.movie, Colors.orange),
                            _buildStatCard('Utilisateurs simples', _userStats['user_count']?.toString() ?? '-', Icons.person, Colors.green),
                            _buildStatCard('Nouveaux (30j)', _userStats['new_users_30d']?.toString() ?? '-', Icons.fiber_new, Colors.purple),
                            _buildStatCard('Abonnés', _userStats['subscribed_users']?.toString() ?? '-', Icons.subscriptions, Colors.teal),
                            _buildStatCard('Abonnements actifs', _userStats['active_subscriptions']?.toString() ?? '-', Icons.check_circle, Colors.lightGreen),
                            _buildStatCard('Total coins', _userStats['total_coins']?.toString() ?? '-', Icons.monetization_on, Colors.amber),
                          ],
                        );
                      },
                    ),
                  ),
                  if (_subscriptions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Répartition des abonnements', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            DataTable(
                              columns: const [
                                DataColumn(label: Text('Type')),
                                DataColumn(label: Text('Total')),
                                DataColumn(label: Text('Actifs')),
                              ],
                              rows: _subscriptions.map((sub) => DataRow(cells: [
                                DataCell(Text(sub['subscription_type'] ?? '-')),
                                DataCell(Text(sub['count']?.toString() ?? '-')),
                                DataCell(Text(sub['active_count']?.toString() ?? '-')),
                              ])).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un utilisateur...',
                          prefixIcon: const Icon(Icons.search, color: Colors.white70),
                          filled: true,
                          fillColor: Colors.grey[900],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          setState(() {
                            _search = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: Colors.orange))
                else if (_error != null)
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Erreur: $_error',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadUsers,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                else if (filteredUsers.isEmpty)
                  const Center(
                    child: Text(
                      'Aucun utilisateur trouvé',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  )
                else if (MediaQuery.of(context).size.width < 700)
                  // Affichage en cards sur mobile
                  Column(
                    children: filteredUsers.map((user) {
                      Color badgeColor;
                      switch (user['role']) {
                        case 'admin':
                          badgeColor = Colors.red;
                          break;
                        case 'realisateur':
                          badgeColor = Colors.orange;
                          break;
                        default:
                          badgeColor = Colors.blue;
                      }
                      return Card(
                        color: Colors.grey[900],
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: badgeColor,
                                    child: Text(
                                      (user['username'] != null && user['username'].toString().isNotEmpty)
                                        ? user['username'][0].toUpperCase()
                                        : (user['email'] != null && user['email'].toString().isNotEmpty
                                            ? user['email'][0].toUpperCase()
                                            : '?'),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (user['username'] != null && user['username'].toString().isNotEmpty)
                                            ? user['username']
                                            : '(inconnu)',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                        Text(user['email'], style: const TextStyle(color: Colors.white70)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: badgeColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(user['role'], style: const TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'Modifier',
                                    onPressed: () => _showEditDialog(user),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Supprimer',
                                    onPressed: () => _showDeleteConfirmation(user),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else
                  // Affichage tableau moderne sur desktop/tablette
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                      child: Card(
                        color: Colors.grey[900],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 6,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.grey[850]),
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text('Nom', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Rôle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          ],
                          rows: filteredUsers.map((user) {
                            Color badgeColor;
                            switch (user['role']) {
                              case 'admin':
                                badgeColor = Colors.red;
                                break;
                              case 'realisateur':
                                badgeColor = Colors.orange;
                                break;
                              default:
                                badgeColor = Colors.blue;
                            }
                            return DataRow(
                              cells: [
                                DataCell(Text(
                                  user['username'] ?? '(inconnu)',
                                  style: const TextStyle(color: Colors.white),
                                )),
                                DataCell(Text(
                                  user['email'],
                                  style: const TextStyle(color: Colors.white),
                                )),
                                DataCell(Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    user['role'],
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                )),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      tooltip: 'Modifier',
                                      onPressed: () => _showEditDialog(user),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Supprimer',
                                      onPressed: () => _showDeleteConfirmation(user),
                                    ),
                                  ],
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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