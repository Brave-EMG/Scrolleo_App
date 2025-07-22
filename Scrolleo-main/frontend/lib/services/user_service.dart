import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class UserService extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  String? _name;
  String? _email;
  String? _profilePicture;
  String? _phoneNumber;
  String? _address;
  DateTime? _subscriptionEndDate;
  String? _paymentMethod;
  DateTime? _createdAt;
  bool _emailNotifications = false;
  bool _pushNotifications = false;
  String? _subscriptionPlan;
  bool _isLoggedIn = false;
  String _userId = '198806124';
  String _username = 'Visiteur';

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get name => _name;
  String? get email => _email;
  String? get profilePicture => _profilePicture;
  String? get phoneNumber => _phoneNumber;
  String? get address => _address;
  DateTime? get subscriptionEndDate => _subscriptionEndDate;
  String? get paymentMethod => _paymentMethod;
  DateTime? get createdAt => _createdAt;
  bool get emailNotifications => _emailNotifications;
  bool get pushNotifications => _pushNotifications;
  String? get subscriptionPlan => _subscriptionPlan;
  bool get isLoggedIn => _isLoggedIn;
  String get userId => _userId;
  String get username => _username;

  Future<void> loadUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      _name = prefs.getString('user_name');
      _email = prefs.getString('user_email');
      _phoneNumber = prefs.getString('user_phone');
      _profilePicture = prefs.getString('user_profile_picture');
      _subscriptionEndDate = DateTime.tryParse(prefs.getString('user_subscription_end_date') ?? '');
      _paymentMethod = prefs.getString('user_payment_method');

      if (_name == null || _email == null || _phoneNumber == null) {
        // Valeurs par défaut si aucune donnée n'est sauvegardée
        _name = 'John Doe';
        _email = 'john.doe@example.com';
        _phoneNumber = '+221 77 123 45 67';
        _profilePicture = 'https://via.placeholder.com/150';
        _subscriptionEndDate = DateTime.now();
        _paymentMethod = 'Gratuit';
        
        // Sauvegarder les valeurs par défaut
        await _saveUserData();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserData({
    String? name,
    String? email,
    String? phoneNumber,
    String? profilePicture,
    String? address,
    DateTime? subscriptionEndDate,
    String? paymentMethod,
    DateTime? createdAt,
    bool? emailNotifications,
    bool? pushNotifications,
    String? subscriptionPlan,
  }) async {
    if (name != null) _name = name;
    if (email != null) _email = email;
    if (phoneNumber != null) _phoneNumber = phoneNumber;
    if (profilePicture != null) _profilePicture = profilePicture;
    if (address != null) _address = address;
    if (subscriptionEndDate != null) _subscriptionEndDate = subscriptionEndDate;
    if (paymentMethod != null) _paymentMethod = paymentMethod;
    if (createdAt != null) _createdAt = createdAt;
    if (emailNotifications != null) _emailNotifications = emailNotifications;
    if (pushNotifications != null) _pushNotifications = pushNotifications;
    if (subscriptionPlan != null) _subscriptionPlan = subscriptionPlan;

    notifyListeners();
    await _saveUserToPrefs();
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('user_name', _name!);
    await prefs.setString('user_email', _email!);
    await prefs.setString('user_phone', _phoneNumber!);
    if (_profilePicture != null) {
      await prefs.setString('user_profile_picture', _profilePicture!);
    }
    if (_subscriptionEndDate != null) {
      await prefs.setString('user_subscription_end_date', _subscriptionEndDate!.toIso8601String());
    }
    if (_paymentMethod != null) {
      await prefs.setString('user_payment_method', _paymentMethod!);
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Simuler une requête API
      await Future.delayed(const Duration(seconds: 1));

      // Pour le test, on crée un utilisateur fictif
      _currentUser = UserModel(
        id: '1',
        email: email,
        name: 'Utilisateur Test',
        isDirector: false,
      );

      await _saveUserToPrefs();
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password, String name) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Simuler une requête API
      await Future.delayed(const Duration(seconds: 1));

      // Pour le test, on crée un utilisateur fictif
      _currentUser = UserModel(
        id: '1',
        email: email,
        name: name,
        isDirector: false,
      );

      await _saveUserToPrefs();
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle(GoogleSignInAccount googleUser) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Pour le test, on crée un utilisateur fictif basé sur les données Google
      _currentUser = UserModel(
        id: googleUser.id,
        email: googleUser.email,
        name: googleUser.displayName ?? '',
        photoUrl: googleUser.photoUrl,
        isDirector: false,
      );

      await _saveUserToPrefs();
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      _currentUser = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveUserToPrefs() async {
    if (_currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_currentUser!.toJson()));
    }
  }

  Future<void> loadUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> login() async {
    // TODO: Implémenter la logique de connexion avec le backend
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    // TODO: Implémenter la logique de déconnexion avec le backend
    _isLoggedIn = false;
    _username = 'Visiteur';
    notifyListeners();
  }
} 