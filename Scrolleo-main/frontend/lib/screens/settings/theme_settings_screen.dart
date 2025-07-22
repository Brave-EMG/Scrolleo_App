import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);
    final isDarkMode = settingsService.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.lightBackgroundColor,
      appBar: AppBar(
        title: const Text('Thème'),
        backgroundColor: isDarkMode ? AppTheme.darkBackgroundColor : AppTheme.lightBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildThemeOption(
            context,
            'Système',
            'Utiliser le thème du système',
            Icons.brightness_auto,
            ThemeMode.system,
            settingsService.themeMode == ThemeMode.system,
          ),
          _buildThemeOption(
            context,
            'Clair',
            'Utiliser le thème clair',
            Icons.brightness_high,
            ThemeMode.light,
            settingsService.themeMode == ThemeMode.light,
          ),
          _buildThemeOption(
            context,
            'Sombre',
            'Utiliser le thème sombre',
            Icons.brightness_4,
            ThemeMode.dark,
            settingsService.themeMode == ThemeMode.dark,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    ThemeMode mode,
    bool isSelected,
  ) {
    final settingsService = Provider.of<SettingsService>(context);
    final isDarkMode = settingsService.isDarkMode;

    return ListTile(
      leading: Icon(
        icon,
        color: isDarkMode ? AppTheme.darkAccentColor : AppTheme.lightAccentColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? AppTheme.darkPrimaryTextColor : AppTheme.lightPrimaryTextColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDarkMode ? AppTheme.darkSecondaryTextColor : AppTheme.lightSecondaryTextColor,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: isDarkMode ? AppTheme.darkAccentColor : AppTheme.lightAccentColor,
            )
          : null,
      onTap: () {
        settingsService.setThemeMode(mode);
      },
    );
  }
} 