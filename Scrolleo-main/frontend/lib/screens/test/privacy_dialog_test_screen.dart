import 'package:flutter/material.dart';
import '../../widgets/privacy_policy_dialog.dart';
import '../../services/privacy_service.dart';

class PrivacyDialogTestScreen extends StatefulWidget {
  const PrivacyDialogTestScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyDialogTestScreen> createState() => _PrivacyDialogTestScreenState();
}

class _PrivacyDialogTestScreenState extends State<PrivacyDialogTestScreen> {
  bool _hasAccepted = false;

  @override
  void initState() {
    super.initState();
    _checkPrivacyStatus();
  }

  Future<void> _checkPrivacyStatus() async {
    final accepted = await PrivacyService.hasAcceptedPrivacyPolicy();
    setState(() {
      _hasAccepted = accepted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Test Pop-up Politique de Confidentialité'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Scrolleo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.movie,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'SCROLLEO',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              'Plateforme de Streaming Africain',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),
            
            // Statut de la politique de confidentialité
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _hasAccepted ? Icons.check_circle : Icons.info_outline,
                    color: _hasAccepted ? Colors.green : Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hasAccepted 
                      ? 'Politique de confidentialité acceptée'
                      : 'Politique de confidentialité non acceptée',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Boutons de test
            Column(
              children: [
                SizedBox(
                  width: 300,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _showPrivacyDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Afficher le Pop-up',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: 300,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => _resetPrivacyStatus(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Réinitialiser le statut',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PrivacyPolicyDialog(
        onAccepted: () {
          setState(() {
            _hasAccepted = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Politique de confidentialité acceptée !'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  Future<void> _resetPrivacyStatus() async {
    await PrivacyService.resetPrivacyAcceptance();
    setState(() {
      _hasAccepted = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Statut réinitialisé'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }
} 