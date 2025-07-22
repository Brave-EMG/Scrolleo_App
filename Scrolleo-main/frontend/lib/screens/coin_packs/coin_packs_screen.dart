import 'package:flutter/material.dart';
import '../../services/wallet_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/bottom_nav_bar.dart';

class CoinPacksScreen extends StatefulWidget {
  const CoinPacksScreen({Key? key}) : super(key: key);

  @override
  State<CoinPacksScreen> createState() => _CoinPacksScreenState();
}

class _CoinPacksScreenState extends State<CoinPacksScreen> {
  final WalletService _walletService = WalletService();
  final AuthService _authService = AuthService();
  
  List<Map<String, dynamic>> _coinPacks = [];
  int _userBalance = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Charger le solde utilisateur
      final balance = await _walletService.getBalance();
      
      // Charger les packs de coins
      final packs = await _walletService.getCoinPacks();

      setState(() {
        _userBalance = balance;
        _coinPacks = packs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _purchaseCoins(String packId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await _walletService.purchaseCoins(packId);
      
      // Afficher les informations de paiement
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Paiement'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Montant: ${result['amount']} XOF'),
                  Text('Coins: ${result['coinsAdded']}'),
                  const SizedBox(height: 16),
                  const Text('Redirection vers la page de paiement...'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }

      setState(() {
        _isLoading = false;
      });

      // Recharger les données
      await _loadData();

    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _claimDailyReward() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await _walletService.claimDailyReward();
      
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Récompense quotidienne réclamée ! +${result['coinsEarned']} coins'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Recharger les données
      await _loadData();

    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Portefeuille'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Erreur: $_error',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Solde utilisateur
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.purple],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Votre Solde',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_userBalance coins',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _claimDailyReward,
                              icon: const Icon(Icons.card_giftcard),
                              label: const Text('Récompense Quotidienne'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Packs de coins
                      const Text(
                        'Acheter des Coins',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: _coinPacks.length,
                        itemBuilder: (context, index) {
                          final pack = _coinPacks[index];
                          return _CoinPackCard(
                            pack: pack,
                            onPurchase: () => _purchaseCoins(pack['id']),
                          );
                        },
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}

class _CoinPackCard extends StatelessWidget {
  final Map<String, dynamic> pack;
  final VoidCallback onPurchase;

  const _CoinPackCard({
    Key? key,
    required this.pack,
    required this.onPurchase,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monetization_on,
              size: 48,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              pack['name'] ?? 'Pack',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${pack['coins']} coins',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${pack['price']} XOF',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Acheter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 