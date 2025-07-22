import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../l10n/app_localizations.dart';
import 'profile/profile_screen.dart';
import 'subscription/subscription_screen.dart';
import '../services/locale_service.dart';
import 'delete_account/delete_account_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _mobileDataEnabled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Paramètres',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Consumer<SettingsService>(
        builder: (context, settings, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.primaryColor.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: ListView(
              children: [
                // Langue
                ListTile(
                  title: const Text('Langue', 
                    style: TextStyle(color: Colors.white)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Français',
                        style: TextStyle(color: Colors.grey)),
                      Icon(Icons.chevron_right, color: Colors.grey[600]),
                    ],
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => _buildStyledDialog(
                        context,
                        l10n.language,
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildDialogOption(
                              context,
                              'Français',
                              Icons.check_circle,
                              settings.language == 'fr',
                              () {
                                settings.setLanguage('fr');
                                Provider.of<LocaleService>(context, listen: false)
                                    .setLocale(const Locale('fr'));
                                Navigator.pop(context);
                              },
                            ),
                            _buildDialogOption(
                              context,
                              'English',
                              Icons.check_circle,
                              settings.language == 'en',
                              () {
                                settings.setLanguage('en');
                                Provider.of<LocaleService>(context, listen: false)
                                    .setLocale(const Locale('en'));
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                // Gestion des abonnés
                ListTile(
                  title: const Text('Gestion des abonnés',
                    style: TextStyle(color: Colors.white)),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
                  onTap: () {
                    Navigator.push(
                        context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionScreen(),
                      ),
                    );
                  },
                ),

                // Vider le cache
                ListTile(
                  title: const Text('Vider le cache',
                    style: TextStyle(color: Colors.white)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('35.0MB',
                        style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(width: 8),
                      Icon(Icons.delete_outline, color: Colors.grey[600]),
                    ],
                  ),
                  onTap: () {
                    // Action pour vider le cache
                  },
                ),

                // Suppression de compte
                ListTile(
                  title: const Text('Suppression de compte',
                    style: TextStyle(color: Colors.white)),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DeleteAccountScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(
          Icons.chevron_right,
          color: color,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStyledDialog(
    BuildContext context,
    String title,
    Widget content,
  ) {
    return AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: content,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
    );
  }

  Widget _buildDialogOption(
    BuildContext context,
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final color = Theme.of(context).primaryColor;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? color : Colors.grey,
        ),
        title: Text(title),
        trailing: isSelected
            ? Icon(
                Icons.check,
                color: color,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
} 