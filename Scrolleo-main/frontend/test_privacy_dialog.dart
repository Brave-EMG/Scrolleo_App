import 'package:flutter/material.dart';
import 'lib/widgets/privacy_policy_dialog.dart';
import 'lib/theme/app_theme.dart';

void main() {
  runApp(const PrivacyDialogTestApp());
}

class PrivacyDialogTestApp extends StatelessWidget {
  const PrivacyDialogTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Pop-up Politique de Confidentialité',
      theme: AppTheme.darkTheme,
      home: const PrivacyDialogTestPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PrivacyDialogTestPage extends StatefulWidget {
  const PrivacyDialogTestPage({Key? key}) : super(key: key);

  @override
  State<PrivacyDialogTestPage> createState() => _PrivacyDialogTestPageState();
}

class _PrivacyDialogTestPageState extends State<PrivacyDialogTestPage> {
  @override
  void initState() {
    super.initState();
    // Afficher le pop-up automatiquement après un court délai
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _showPrivacyDialog();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
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
            
            // Bouton pour afficher le pop-up
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
                  'Afficher le Pop-up de Politique de Confidentialité',
                  style: TextStyle(
                    fontSize: 16,
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

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PrivacyPolicyDialog(
        onAccepted: () {
          Navigator.of(context).pop();
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
} 