import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment.dart';
import 'dart:html' as html; // Added for web platform
import 'package:url_launcher/url_launcher.dart'; // Added for mobile platform
import 'package:feexpay_flutter/feexpay_flutter.dart';
import 'dart:math';

class WalletService extends ChangeNotifier {
  final String _baseUrl = Environment.apiBaseUrl;
  
  int _coins = 0;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;

  int get coins => _coins;
  List<Map<String, dynamic>> get transactions => _transactions;
  bool get isLoading => _isLoading;

  // Méthode pour récupérer le token depuis SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      // Afficher seulement les premiers et derniers caractères pour la sécurité
      final maskedToken = token.length > 10 
          ? '${token.substring(0, 10)}...${token.substring(token.length - 10)}'
          : '***';
      print('DEBUG: Token récupéré (masqué): $maskedToken');
    } else {
      print('DEBUG: Aucun token trouvé');
    }
    return token;
  }

  // Générer une clé de transaction aléatoire de 15 caractères
  String _generateTransKey() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(15, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  // Acheter des coins
  Future<Map<String, dynamic>> purchaseCoins(String packId) async {
    try {
      final token = await _getToken();
      print('DEBUG: Token récupéré pour achat: ${token != null ? 'OUI' : 'NON'}');
      if (token == null) {
        throw Exception('Utilisateur non connecté');
      }

      final url = '$_baseUrl/payments/create';
      print('DEBUG: URL d\'achat: $url');
      print('DEBUG: Pack ID: $packId');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'type': 'coins',
          'planId': packId,
        }),
      );

      print('DEBUG: Status code achat: ${response.statusCode}');
      print('DEBUG: Response body achat: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Générer la clé de transaction
        final transKey = _generateTransKey();
        print('DEBUG: TransKey généré: $transKey');
        
        // Construire l'URL de redirection après paiement
        final redirectUrl = '${Environment.apiBaseUrl}/payments/success';
        
        // Ajouter les paramètres nécessaires pour Feexpay
        responseData['feexpayParams']['trans_key'] = transKey;
        responseData['feexpayParams']['redirecturl'] = redirectUrl;
        
        return responseData;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Erreur lors de l\'achat');
      }
    } catch (e) {
      print('Erreur lors de l\'achat de coins: $e');
      rethrow;
    }
  }

  // Récupérer le solde de coins
  Future<int> getBalance() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/coins/balance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['balance'] ?? 0;
      } else {
        throw Exception('Erreur lors de la récupération du solde: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la récupération du solde: $e');
      rethrow;
    }
  }

  // Méthode pour charger le solde (compatible avec l'ancien code)
  Future<void> loadBalance() async {
    try {
      _isLoading = true;
      notifyListeners();

      final token = await _getToken();
      if (token == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/coins/balance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _coins = data['balance'] ?? 0;
      } else {
        _coins = 0;
      }
    } catch (e) {
      print('Erreur lors du chargement du solde: $e');
      _coins = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Récupérer l'historique des transactions
  Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/coins/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Erreur lors de la récupération des transactions: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des transactions: $e');
      rethrow;
    }
  }

  // Méthode pour charger les transactions (compatible avec l'ancien code)
  Future<void> loadTransactions() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/coins/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _transactions = List<Map<String, dynamic>>.from(data);
      } else {
        _transactions = [];
      }
    } catch (e) {
      print('Erreur lors du chargement des transactions: $e');
      _transactions = [];
    } finally {
      notifyListeners();
    }
  }

  // Réclamer la récompense quotidienne
  Future<Map<String, dynamic>> claimDailyReward() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/coins/daily-reward'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Erreur lors de la réclamation');
      }
    } catch (e) {
      print('Erreur lors de la réclamation de la récompense: $e');
      rethrow;
    }
  }

  // Récupérer les packs de coins disponibles
  Future<List<Map<String, dynamic>>> getCoinPacks() async {
    try {
      final token = await _getToken();
      print('DEBUG: Token récupéré: ${token != null ? 'OUI' : 'NON'}');
      if (token == null) {
        throw Exception('Utilisateur non connecté');
      }

      final url = '$_baseUrl/payments/coins/packs';
      print('DEBUG: URL appelée: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: Status code: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Erreur lors de la récupération des packs: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des packs: $e');
      rethrow;
    }
  }

  // Vérifier le statut d'un paiement
  Future<Map<String, dynamic>> checkPaymentStatus(String paymentId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/payments/status/$paymentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur lors de la vérification du statut: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la vérification du statut: $e');
      rethrow;
    }
  }

  // Méthodes pour la compatibilité avec l'ancien code
  Future<void> addCoins(int amount) async {
    _coins += amount;
    notifyListeners();
  }

  Future<void> useCoins(int amount) async {
    if (_coins >= amount) {
      _coins -= amount;
      notifyListeners();
    } else {
      throw Exception('Solde insuffisant');
    }
  }
} 