import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:streaming_platform/services/auth_service.dart';
import '../../config/api_config.dart';
import '../../config/environment.dart';

class AdminStatsScreen extends StatefulWidget {
  final void Function(int index)? onCardTap;
  const AdminStatsScreen({Key? key, this.onCardTap}) : super(key: key);

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  bool isLoading = true;
  Map<String, dynamic> userStats = {};
  Map<String, dynamic> revenueStats = {};
  Map<String, dynamic> contentStats = {};
  Map<String, dynamic> engagementStats = {};
  Map<String, dynamic> directorStats = {};
  Map<String, dynamic> engagementOverview = {};
  String? errorMsg;
  String? lastApiResponse;
  String? lastApiEndpoint;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
      lastApiResponse = null;
      lastApiEndpoint = null;
    });
    try {
      final results = await Future.wait([
        _fetchStats('/admin/stats/users'),
        _fetchStats('/admin/stats/revenue'),
        _fetchStats('/admin/stats/content'),
        _fetchStats('/admin/stats/engagement'),
        _fetchStats('/admin/stats/directors'),
      ]);
      setState(() {
        userStats = results[0];
        revenueStats = results[1];
        contentStats = results[2];
        engagementStats = results[3];
        directorStats = results[4];
        engagementOverview = results[3]['overview'] ?? {};
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMsg = e.toString();
      });
    }
  }

  Future<Map<String, dynamic>> _fetchStats(String endpoint) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.jwtToken;
    if (token == null || token.isEmpty) {
      lastApiEndpoint = endpoint;
      lastApiResponse = 'Token manquant';
      throw Exception('Token manquant. Veuillez vous reconnecter.');
    }
    final response = await http.get(
      Uri.parse('${Environment.apiBaseUrl}$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    lastApiEndpoint = endpoint;
    lastApiResponse = response.body;
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return decoded['data'] ?? {};
    } else {
      throw Exception('Failed to load stats: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMsg != null) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                errorMsg!,
                style: const TextStyle(color: Colors.red, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (lastApiEndpoint != null)
                Text('Dernier endpoint appelé : $lastApiEndpoint', style: const TextStyle(color: Colors.orange)),
              if (lastApiResponse != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Réponse brute :\n$lastApiResponse', style: const TextStyle(color: Colors.yellow, fontSize: 14)),
                ),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCards(),
          const SizedBox(height: 24),
          _buildRevenueChart(),
          const SizedBox(height: 24),
          _buildEngagementChart(),
          const SizedBox(height: 24),
          _buildContentStats(),
          const SizedBox(height: 24),
          _buildDirectorStats(),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    final totalUsers = userStats['users']?['total_users']?.toString() ?? '0';
    final totalRevenue = revenueStats['overview']?['total_revenue']?.toString() ?? '0';
    final totalViews = engagementStats['overview']?['total_views']?.toString() ?? '0';
    final totalMovies = contentStats['overview']?['total_movies']?.toString() ?? '0';
    final totalFavorites = engagementOverview['total_favorites']?.toString() ?? '0';
    final totalLikes = engagementOverview['total_likes']?.toString() ?? '0';
    final uniqueViewers = engagementOverview['unique_viewers']?.toString() ?? '0';
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        GestureDetector(
          onTap: () => widget.onCardTap?.call(0),
          child: _buildStatCard('Utilisateurs', totalUsers, Icons.people, Colors.blue),
        ),
        _buildStatCard('Revenus', '$totalRevenue FCFA', Icons.attach_money, Colors.green),
        _buildStatCard('Vues', totalViews, Icons.visibility, Colors.orange),
        GestureDetector(
          onTap: () => widget.onCardTap?.call(2),
          child: _buildStatCard('Contenu', '$totalMovies films', Icons.movie, Colors.purple),
        ),
        _buildStatCard('Favoris', totalFavorites, Icons.favorite, Colors.pink),
        _buildStatCard('Likes', totalLikes, Icons.thumb_up, Colors.lightBlue),
        _buildStatCard('Spectateurs uniques', uniqueViewers, Icons.person_pin, Colors.teal),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.7),
              color,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    final revenueData = (revenueStats['byType'] as List?) ?? [];
    if (revenueData.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenus par type',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: revenueData.map((data) {
                    final value = (data['total_amount'] is num)
                        ? (data['total_amount'] as num).toDouble()
                        : double.tryParse(data['total_amount'].toString()) ?? 0.0;
                    return PieChartSectionData(
                      value: value,
                      title: '${data['type']}\n${data['total_amount']} FCFA',
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementChart() {
    final dailyData = (engagementStats['dailyEngagement'] as List?) ?? [];
    if (dailyData.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Engagement quotidien',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dailyData.asMap().entries.map((entry) {
                        final y = (entry.value['view_count'] is num)
                            ? (entry.value['view_count'] as num).toDouble()
                            : double.tryParse(entry.value['view_count'].toString()) ?? 0.0;
                        return FlSpot(
                          entry.key.toDouble(),
                          y,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentStats() {
    final popularContent = (contentStats['popularContent'] as List?) ?? [];
    if (popularContent.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contenu populaire',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: popularContent.length,
              itemBuilder: (context, index) {
                final content = popularContent[index];
                return ListTile(
                  leading: const Icon(Icons.movie),
                  title: Text(content['title'] ?? ''),
                  subtitle: Text('${content['view_count'] ?? 0} vues'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectorStats() {
    final directorRevenue = (directorStats['directorRevenue'] as List?) ?? [];
    if (directorRevenue.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top réalisateurs',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: directorRevenue.length,
              itemBuilder: (context, index) {
                final director = directorRevenue[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(director['director_name'] ?? ''),
                  subtitle: Text('${director['estimated_revenue'] ?? 0} FCFA'),
                  trailing: Text('${director['total_views'] ?? 0} vues'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 