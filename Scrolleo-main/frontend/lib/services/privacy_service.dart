import 'package:shared_preferences/shared_preferences.dart';

class PrivacyService {
  static const String _privacyAcceptedKey = 'privacy_policy_accepted';
  
  /// Vérifie si l'utilisateur a déjà accepté la politique de confidentialité
  static Future<bool> hasAcceptedPrivacyPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_privacyAcceptedKey) ?? false;
  }
  
  /// Marque la politique de confidentialité comme acceptée
  static Future<void> acceptPrivacyPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyAcceptedKey, true);
  }
  
  /// Réinitialise l'acceptation (pour les tests)
  static Future<void> resetPrivacyAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_privacyAcceptedKey);
  }
} 