import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;
  bool _isDarkMode = true;
  bool _notificationsEnabled = true;
  bool _autoPlayEnabled = false;
  String _videoQuality = 'HD';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getCurrentUser();
      setState(() {
        _user = user;
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
          'Paramètres',
          style: TextStyle(
            fontSize: isMobile ? 18.0 : 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileSection(isMobile),
                  SizedBox(height: isMobile ? 24.0 : 32.0),
                  _buildAppearanceSection(isMobile),
                  SizedBox(height: isMobile ? 24.0 : 32.0),
                  _buildPlaybackSection(isMobile),
                  SizedBox(height: isMobile ? 24.0 : 32.0),
                  _buildNotificationSection(isMobile),
                  SizedBox(height: isMobile ? 24.0 : 32.0),
                  _buildAccountSection(isMobile),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileSection(bool isMobile) {
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
              'Profil',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 16.0 : 20.0),
            _buildSettingItem(
              'Nom d\'utilisateur',
              _user?.name ?? 'Utilisateur',
              Icons.person,
              () => _showEditUsernameDialog(),
              isMobile,
            ),
            _buildSettingItem(
              'Email',
              _user?.email ?? 'Non défini',
              Icons.email,
              null,
              isMobile,
            ),
            _buildSettingItem(
              'Changer le mot de passe',
              '',
              Icons.lock,
              () => _showChangePasswordDialog(),
              isMobile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(bool isMobile) {
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
              'Apparence',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 16.0 : 20.0),
            _buildSwitchItem(
              'Mode sombre',
              'Activer le thème sombre',
              Icons.dark_mode,
              _isDarkMode,
              (value) {
                setState(() {
                  _isDarkMode = value;
                });
                // TODO: Implémenter le changement de thème
              },
              isMobile,
            ),
            _buildSettingItem(
              'Taille du texte',
              'Moyenne',
              Icons.text_fields,
              () => _showTextSizeDialog(),
              isMobile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackSection(bool isMobile) {
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
              'Lecture',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 16.0 : 20.0),
            _buildSwitchItem(
              'Lecture automatique',
              'Lancer automatiquement le prochain épisode',
              Icons.play_circle,
              _autoPlayEnabled,
              (value) {
                setState(() {
                  _autoPlayEnabled = value;
                });
              },
              isMobile,
            ),
            _buildSettingItem(
              'Qualité vidéo',
              _videoQuality,
              Icons.high_quality,
              () => _showVideoQualityDialog(),
              isMobile,
            ),
            _buildSettingItem(
              'Sous-titres',
              'Français',
              Icons.subtitles,
              () => _showSubtitlesDialog(),
              isMobile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection(bool isMobile) {
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
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 16.0 : 20.0),
            _buildSwitchItem(
              'Notifications push',
              'Recevoir les notifications',
              Icons.notifications,
              _notificationsEnabled,
              (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              isMobile,
            ),
            _buildSwitchItem(
              'Nouvelles sorties',
              'Être notifié des nouveaux contenus',
              Icons.new_releases,
              _notificationsEnabled,
              (value) {
                // TODO: Implémenter
              },
              isMobile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(bool isMobile) {
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
              'Compte',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 16.0 : 20.0),
            _buildSettingItem(
              'Supprimer le compte',
              '',
              Icons.delete_forever,
              () => _showDeleteAccountDialog(),
              isMobile,
              isDestructive: true,
            ),
            _buildSettingItem(
              'Se déconnecter',
              '',
              Icons.logout,
              () => _logout(),
              isMobile,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap,
    bool isMobile, {
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8.0 : 12.0,
        vertical: isMobile ? 4.0 : 8.0,
      ),
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.white,
        size: isMobile ? 20.0 : 24.0,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontSize: isMobile ? 14.0 : 16.0,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: isMobile ? 12.0 : 14.0,
              ),
            )
          : null,
      trailing: onTap != null
          ? Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: isMobile ? 16.0 : 20.0,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    bool isMobile,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8.0 : 12.0,
        vertical: isMobile ? 4.0 : 8.0,
      ),
      leading: Icon(
        icon,
        color: Colors.white,
        size: isMobile ? 20.0 : 24.0,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: isMobile ? 14.0 : 16.0,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: isMobile ? 12.0 : 14.0,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.amber,
      ),
    );
  }

  void _showEditUsernameDialog() {
    final TextEditingController controller = TextEditingController(text: _user?.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Modifier le nom d\'utilisateur',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Nom d\'utilisateur',
            labelStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.amber),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
              _updateUsername(controller.text);
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Changer le mot de passe',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Ancien mot de passe',
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
              _changePassword(
                oldPasswordController.text,
                newPasswordController.text,
                confirmPasswordController.text,
              );
            },
            child: const Text('Changer'),
          ),
        ],
      ),
    );
  }

  void _showTextSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Taille du texte',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextSizeOption('Petite', context),
            _buildTextSizeOption('Moyenne', context),
            _buildTextSizeOption('Grande', context),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSizeOption(String size, BuildContext context) {
    return ListTile(
      title: Text(
        size,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: () {
        Navigator.pop(context);
        // TODO: Implémenter le changement de taille de texte
      },
    );
  }

  void _showVideoQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Qualité vidéo',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQualityOption('Auto', context),
            _buildQualityOption('HD', context),
            _buildQualityOption('4K', context),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityOption(String quality, BuildContext context) {
    return ListTile(
      title: Text(
        quality,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: () {
        setState(() {
          _videoQuality = quality;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showSubtitlesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Sous-titres',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSubtitleOption('Désactivés', context),
            _buildSubtitleOption('Français', context),
            _buildSubtitleOption('Anglais', context),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitleOption(String language, BuildContext context) {
    return ListTile(
      title: Text(
        language,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: () {
        Navigator.pop(context);
        // TODO: Implémenter le changement de sous-titres
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Supprimer le compte',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _updateUsername(String newUsername) {
    // TODO: Implémenter la mise à jour du nom d'utilisateur
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nom d\'utilisateur mis à jour'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _changePassword(String oldPassword, String newPassword, String confirmPassword) {
    // TODO: Implémenter le changement de mot de passe
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mot de passe changé avec succès'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteAccount() {
    // TODO: Implémenter la suppression de compte
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de suppression à venir'),
      ),
    );
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      context.go('/login');
    }
  }
} 