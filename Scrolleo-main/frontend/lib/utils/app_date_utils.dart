import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');
  static final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayDateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
  
  // Convertir une date en format d'affichage français
  static String formatDateForDisplay(DateTime date) {
    return _displayDateFormat.format(date);
  }
  
  // Convertir une date en format pour l'API
  static String formatDateForApi(DateTime date) {
    return _apiDateFormat.format(date);
  }
  
  // Convertir une date en format court (ex: "15 Jan")
  static String formatShortDate(DateTime date) {
    return _dateFormat.format(date);
  }
  
  // Parser une date depuis l'API
  static DateTime parseApiDate(String date) {
    try {
      // Parser la date en UTC
      final utcDate = DateTime.parse(date);
      // Convertir en heure locale
      final localDate = utcDate.toLocal();
      // Créer une nouvelle date en utilisant les composants de la date locale
      return DateTime(
        localDate.year,
        localDate.month,
        localDate.day,
      );
    } catch (e) {
      print('Erreur de parsing de date: $e');
      return DateTime.now();
    }
  }
  
  // Vérifier si une date est dans le futur
  static bool isFutureDate(DateTime date) {
    return date.isAfter(DateTime.now());
  }
  
  // Obtenir le nom du mois en français
  static String getMonthName(int month) {
    const months = [
      '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return months[month];
  }
  
  // Convertir une date en UTC
  static DateTime toUtc(DateTime date) {
    return date.toUtc();
  }
  
  // Convertir une date UTC en locale
  static DateTime toLocal(DateTime date) {
    return date.toLocal();
  }

  static String formatLongDate(DateTime date) {
    const months = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return "${date.day.toString().padLeft(2, '0')} ${months[date.month]} ${date.year}";
  }

  static String formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return 'Il y a ${(difference.inDays / 365).floor()} an${(difference.inDays / 365).floor() > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      return 'Il y a ${(difference.inDays / 30).floor()} mois';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
} 