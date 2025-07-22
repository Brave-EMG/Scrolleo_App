import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/wallet_service.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import 'package:feexpay_flutter/feexpay_flutter.dart';
import '../../config/environment.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:math';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final WalletService _walletService = WalletService();
  User? _user;
  bool _isLoading = true;
  List<Map<String, dynamic>> _coinPacks = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Recharger le solde quand l'app reprend le focus
      _walletService.loadBalance();
      setState(() {});
    }
  }

  Future<void> _loadData() async {
    try {
      final user = await _authService.getCurrentUser();
      await _walletService.loadBalance();
      await _walletService.loadTransactions();
      final coinPacks = await _walletService.getCoinPacks();
      
      setState(() {
        _user = user;
        _coinPacks = coinPacks;
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
          'Mon Portefeuille',
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
          : RefreshIndicator(
              onRefresh: () async {
                await _walletService.loadBalance();
                await _walletService.loadTransactions();
                setState(() {});
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWalletBalance(isMobile),
                    SizedBox(height: isMobile ? 24.0 : 32.0),
                    _buildCoinPacks(isMobile),
                    SizedBox(height: isMobile ? 24.0 : 32.0),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWalletBalance(bool isMobile) {
    return Card(
      color: Colors.green.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        side: const BorderSide(color: Colors.green, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet,
              color: Colors.green,
              size: isMobile ? 48.0 : 56.0,
            ),
            SizedBox(height: isMobile ? 12.0 : 16.0),
            Text(
              'Solde actuel',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: isMobile ? 14.0 : 16.0,
              ),
            ),
            SizedBox(height: isMobile ? 8.0 : 12.0),
            Text(
              '${_walletService.coins} pièces',
              style: TextStyle(
                color: Colors.green,
                fontSize: isMobile ? 32.0 : 36.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinPacks(bool isMobile) {
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
              'Acheter des pièces',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 16.0 : 20.0),
            if (_coinPacks.isNotEmpty)
              ...(_coinPacks.map((pack) => _buildCoinPack(pack, isMobile)))
            else
              _buildDefaultCoinPacks(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultCoinPacks(bool isMobile) {
    final defaultPacks = [
      {'id': 'small', 'name': 'Petit Pack', 'price': 2, 'coins': 400, 'description': 'Environ 400 coins'},
      {'id': 'medium', 'name': 'Pack Moyen', 'price': 500, 'coins': 800, 'description': 'Environ 800 coins'},
      {'id': 'large', 'name': 'Grand Pack', 'price': 1000, 'coins': 1600, 'description': 'Environ 1600 coins'},
    ];

    return Column(
      children: defaultPacks.map((pack) => _buildCoinPack(pack, isMobile)).toList(),
    );
  }

  Widget _buildCoinPack(Map<String, dynamic> pack, bool isMobile) {
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
            Icons.monetization_on,
            color: Colors.amber,
            size: isMobile ? 24.0 : 28.0,
          ),
        ),
        title: Text(
          pack['name'] ?? 'Pack de coins',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 16.0 : 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${pack['coins']} pièces',
              style: TextStyle(
                color: Colors.amber,
                fontSize: isMobile ? 14.0 : 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${pack['price']} FCFA',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: isMobile ? 12.0 : 14.0,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _purchaseCoins(pack['id']),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12.0 : 16.0,
              vertical: isMobile ? 8.0 : 12.0,
            ),
          ),
          child: Text(
            'Acheter',
            style: TextStyle(
              fontSize: isMobile ? 12.0 : 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction, bool isMobile) {
    final amount = transaction['amount'] ?? 0;
    final reason = transaction['reason'] ?? 'Transaction';
    final date = transaction['created_at'] ?? '';
    final isPositive = amount > 0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 4.0 : 6.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8.0 : 12.0),
            decoration: BoxDecoration(
              color: isPositive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            ),
            child: Icon(
              isPositive ? Icons.add : Icons.remove,
              color: isPositive ? Colors.green : Colors.red,
              size: isMobile ? 16.0 : 20.0,
            ),
          ),
          SizedBox(width: isMobile ? 12.0 : 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reason,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: isMobile ? 12.0 : 14.0,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${amount}',
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontSize: isMobile ? 14.0 : 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _purchaseCoins(String packId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Créer le paiement et récupérer les paramètres Feexpay
      final paymentData = await _walletService.purchaseCoins(packId);
      final feexpayParams = paymentData['feexpayParams'];

      setState(() {
        _isLoading = false;
      });

      // Ouvrir l'interface Feexpay avec le plugin Flutter
      final result = await Navigator.push(
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

      // Si le paiement a réussi, recharger le solde
      if (result == true || result == 'success') {
        await _walletService.loadBalance();
        setState(() {}); // Rafraîchir l'interface
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement réussi ! Solde mis à jour.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Interface de paiement ouverte'),
            backgroundColor: Colors.blue,
          ),
        );
      }
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

  String _generateTransKey() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(15, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
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