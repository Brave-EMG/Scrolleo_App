import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _newContentNotifications = true;
  bool _promotionalNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _newContentNotifications = prefs.getBool('new_content_notifications') ?? true;
      _promotionalNotifications = prefs.getBool('promotional_notifications') ?? false;
    });
  }

  Future<void> _saveNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('email_notifications', _emailNotifications);
    await prefs.setBool('push_notifications', _pushNotifications);
    await prefs.setBool('new_content_notifications', _newContentNotifications);
    await prefs.setBool('promotional_notifications', _promotionalNotifications);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSection(
            title: 'Types de notifications',
            children: [
              SwitchListTile(
                title: const Text('Notifications par email'),
                subtitle: const Text('Recevoir des notifications par email'),
                value: _emailNotifications,
                onChanged: (value) {
                  setState(() {
                    _emailNotifications = value;
                  });
                  _saveNotificationSettings();
                },
              ),
              SwitchListTile(
                title: const Text('Notifications push'),
                subtitle: const Text('Recevoir des notifications sur votre appareil'),
                value: _pushNotifications,
                onChanged: (value) {
                  setState(() {
                    _pushNotifications = value;
                  });
                  _saveNotificationSettings();
                },
              ),
            ],
          ),
          _buildSection(
            title: 'Contenu',
            children: [
              SwitchListTile(
                title: const Text('Nouveaux contenus'),
                subtitle: const Text('Être notifié des nouveaux films et séries'),
                value: _newContentNotifications,
                onChanged: (value) {
                  setState(() {
                    _newContentNotifications = value;
                  });
                  _saveNotificationSettings();
                },
              ),
              SwitchListTile(
                title: const Text('Offres promotionnelles'),
                subtitle: const Text('Recevoir des offres spéciales et promotions'),
                value: _promotionalNotifications,
                onChanged: (value) {
                  setState(() {
                    _promotionalNotifications = value;
                  });
                  _saveNotificationSettings();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
} 