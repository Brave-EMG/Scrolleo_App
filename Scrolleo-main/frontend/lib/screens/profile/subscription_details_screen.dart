import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/subscription_service.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import 'package:feexpay_flutter/feexpay_flutter.dart';
import 'dart:convert';
import 'dart:math';

class SubscriptionDetailsScreen extends StatefulWidget {
  const SubscriptionDetailsScreen({Key? key}) : super(key: key);

  @override
  _SubscriptionDetailsScreenState createState() => _SubscriptionDetailsScreenState();
}

class _SubscriptionDetailsScreenState extends State<SubscriptionDetailsScreen> {
  final AuthService _authService = AuthService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  User? _user;
  bool _isLoading = true;
  List<Map<String, dynamic>> _plans = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await _authService.getCurrentUser();
      await _subscriptionService.loadSubscriptionStatus();
      final plans = await _subscriptionService.getSubscriptionPlans();
      
      setState(() {
        _user = user;
        _plans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppTheme.mobileBreakpoint;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Mon Abonnement',
          style: TextStyle(
            fontSize: isMobile ? 18.0 : 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubscriptionStatus(isMobile),
                  SizedBox(height: isMobile ? 24.0 : 32.0),
                  if (_subscriptionService.isPremium) ...[
                    _buildSubscriptionDetails(isMobile),
                    SizedBox(height: isMobile ? 24.0 : 32.0),
                  ],
                  _buildSubscriptionBenefits(isMobile),
                  SizedBox(height: isMobile ? 24.0 : 32.0),
                  _buildSubscriptionPlans(isMobile),
                  SizedBox(height: isMobile ? 24.0 : 32.0),
                  _buildSubscriptionActions(isMobile),
                ],
              ),
            ),
    );
  }

  Widget _buildSubscriptionStatus(bool isMobile) {
    final isPremium = _subscriptionService.isPremium;
    final subscription = _subscriptionService.subscriptionDetails;
    
    return Card(
      color: isPremium ? Colors.amber.withOpacity(0.1) : Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        side: BorderSide(
          color: isPremium ? Colors.amber : Colors.grey[700]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
        child: Column(
          children: [
            Icon(
              isPremium ? Icons.star : Icons.star_border,
              color: isPremium ? Colors.amber : Colors.grey[400],
              size: isMobile ? 48.0 : 56.0,
            ),
            SizedBox(height: isMobile ? 12.0 : 16.0),
            Text(
              isPremium ? 'Abonnement Premium Actif' : 'Aucun Abonnement',
              style: TextStyle(
                color: isPremium ? Colors.amber : Colors.white,
                fontSize: isMobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isPremium && subscription != null) ...[
              SizedBox(height: isMobile ? 8.0 : 12.0),
              Text(
                'Expire le ${_formatDate(subscription['endDate'])}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: isMobile ? 14.0 : 16.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionDetails(bool isMobile) {
    final subscription = _subscriptionService.subscriptionDetails;
    if (subscription == null) return const SizedBox.shrink();

    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails de l\'abonnement',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 16.0 : 20.0),
            _buildDetailRow('Type', 'Premium Mensuel', isMobile),
            _buildDetailRow('Prix', '${subscription['amount']} FCFA', isMobile),
            _buildDetailRow('Date de début', _formatDate(subscription['paymentDate']), isMobile),
            _buildDetailRow('Date de fin', _formatDate(subscription['endDate']), isMobile),
            _buildDetailRow('Statut', 'Actif', isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 6.0 : 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: isMobile ? 14.0 : 16.0,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 14.0 : 16.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionBenefits(bool isMobile) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Avantages Premium',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 16.0 : 20.0),
            _buildBenefitItem('Accès illimité aux épisodes', Icons.all_inclusive, isMobile),
            _buildBenefitItem('Pas de publicités', Icons.block, isMobile),
            _buildBenefitItem('Téléchargement hors ligne', Icons.download, isMobile),
            _buildBenefitItem('Qualité HD', Icons.high_quality, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String text, IconData icon, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 6.0 : 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.amber,
            size: isMobile ? 20.0 : 24.0,
          ),
          SizedBox(width: isMobile ? 12.0 : 16.0),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 14.0 : 16.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlans(bool isMobile) {
    // Afficher même si les plans sont vides pour déboguer
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plans disponibles',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 16.0 : 20.0),
            if (_plans.isEmpty)
              Text(
                'Aucun plan disponible pour le moment',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: isMobile ? 14.0 : 16.0,
                ),
              )
            else
              ...(_plans.map((plan) => _buildPlanItem(plan, isMobile))),
          ],
        ),
      ),
    );

    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plans disponibles',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 16.0 : 20.0),
            ...(_plans.map((plan) => _buildPlanItem(plan, isMobile))),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanItem(Map<String, dynamic> plan, bool isMobile) {
    return Card(
      color: Colors.grey[800],
      margin: EdgeInsets.only(bottom: isMobile ? 8.0 : 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        leading: Container(
          padding: EdgeInsets.all(isMobile ? 8.0 : 12.0),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          ),
          child: Icon(
            Icons.star,
            color: Colors.amber,
            size: isMobile ? 24.0 : 28.0,
          ),
        ),
        title: Text(
          plan['name'] ?? 'Plan Premium',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 16.0 : 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${plan['price']} FCFA - ${plan['duration']} jours',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: isMobile ? 14.0 : 16.0,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () => _subscribeToPlan(plan['id']),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12.0 : 16.0,
              vertical: isMobile ? 8.0 : 12.0,
            ),
          ),
          child: Text(
            'S\'abonner',
            style: TextStyle(
              fontSize: isMobile ? 12.0 : 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionActions(bool isMobile) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 16.0 : 20.0),
            if (_subscriptionService.isPremium)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _unsubscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 12.0 : 16.0),
                  ),
                  child: Text(
                    'Se désabonner',
                    style: TextStyle(
                      fontSize: isMobile ? 16.0 : 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _generateTransKey() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(15, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  Future<void> _subscribeToPlan(String planId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final Map<String, dynamic> feexpayParams = await _subscriptionService.subscribe(planId);
      
      setState(() {
        _isLoading = false;
      });

      // Ouvrir l'interface Feexpay avec le plugin Flutter
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChoicePage(
            token: feexpayParams['token'],
            id: feexpayParams['id'],
            amount: feexpayParams['amount'],
            redirecturl: feexpayParams['callback_url'],
            trans_key: _generateTransKey(),
            callback_info: feexpayParams['callback_info'],
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Interface de paiement ouverte'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _unsubscribe() async {
    try {
      await _subscriptionService.unsubscribe();
      await _loadData(); // Recharger les données
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Désabonnement effectué'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
  }
} 