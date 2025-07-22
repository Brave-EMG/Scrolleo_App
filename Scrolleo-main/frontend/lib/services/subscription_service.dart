import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/environment.dart';
import 'auth_service.dart';

class SubscriptionService extends ChangeNotifier {
  bool _isPremium = false;
  Map<String, dynamic>? _subscriptionDetails;
  bool _isLoading = false;
  
  bool get isPremium => _isPremium;
  Map<String, dynamic>? get subscriptionDetails => _subscriptionDetails;
  bool get isLoading => _isLoading;

  Future<void> loadSubscriptionStatus() async {
    try {
      _isLoading = true;
      notifyListeners();

      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Token non disponible');
      }

      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/payments/subscription/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _isPremium = data['hasActiveSubscription'] ?? false;
        _subscriptionDetails = data['subscription'];
      } else {
        _isPremium = false;
        _subscriptionDetails = null;
      }
    } catch (e) {
      print('Erreur lors du chargement du statut d\'abonnement: $e');
      _isPremium = false;
      _subscriptionDetails = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Token non disponible');
      }

      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/payments/subscription/plans'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erreur lors de la récupération des plans');
      }
    } catch (e) {
      print('Erreur lors de la récupération des plans: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> subscribe(String planId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('Token non disponible');
      }

      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}/payments/params'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'type': 'subscription',
          'planId': planId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final feexpayParams = data['feexpayParams'];
        
        // Retourner les paramètres pour que l'UI puisse ouvrir Feexpay
        return feexpayParams;
      } else {
        throw Exception('Erreur lors de la création du paiement');
      }
    } catch (e) {
      print('Erreur lors de l\'abonnement: $e');
      rethrow;
    }
  }

  Future<void> unsubscribe() async {
    // TODO: Implémenter la logique de désabonnement
    _isPremium = false;
    _subscriptionDetails = null;
    notifyListeners();
  }
} 