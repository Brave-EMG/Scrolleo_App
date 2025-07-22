import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  String? _currentUserEmail;
  String? _currentUserRole;
  String? _jwtToken;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _jwtToken != null;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserRole => _currentUserRole;
  String? get jwtToken => _jwtToken;

  static final String baseUrl = '${Environment.apiBaseUrl}/auth';

  Future<List<Map<String, dynamic>>> getRealisateurs() async {
    try {
      print('Envoi de la requête pour obtenir les réalisateurs...');
      print('Token JWT: $_jwtToken');
      
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}${Environment.endpoints.auth.realisateurs}'),
        headers: {
          'Content-Type': 'application/json',
          if (_jwtToken != null) 'Authorization': 'Bearer $_jwtToken',
        },
      );

      print('Réponse du serveur: ${response.statusCode}');
      print('Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erreur lors de la récupération des réalisateurs: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur réseau: $e');
      throw Exception('Erreur réseau: $e');
    }
  }

  Future<bool> updateUser(String id, String name, String email) async {
    try {
      final response = await http.put(
        Uri.parse('${Environment.apiBaseUrl}${Environment.endpoints.auth.login}/users/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (_jwtToken != null) 'Authorization': 'Bearer $_jwtToken',
        },
        body: jsonEncode({'username': name, 'email': email}),
      );
      return response.statusCode == 200;
    } catch (e) {
      _error = 'Erreur réseau: $e';
      return false;
    }
  }

  Future<bool> deleteRealisateur(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${Environment.apiBaseUrl}${Environment.endpoints.auth.login}/users/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (_jwtToken != null) 'Authorization': 'Bearer $_jwtToken',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        _error = 'Erreur lors de la suppression du réalisateur';
        return false;
      }
    } catch (e) {
      _error = 'Erreur réseau: $e';
      return false;
    }
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    final token = prefs.getString('jwt_token');
    
    if (userJson != null && token != null) {
      try {
        final userData = jsonDecode(userJson);
        _currentUser = User.fromJson(userData);
        _jwtToken = token;
        _currentUserEmail = _currentUser?.email;
        _currentUserRole = _currentUser?.role;
        notifyListeners();
      } catch (e) {
        print('Erreur lors de la récupération des données utilisateur: $e');
        await logout();
      }
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}${Environment.endpoints.auth.login}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      print('Réponse backend login: $data'); // Debug

      if (response.statusCode == 200 && data['token'] != null) {
        _jwtToken = data['token'];
        _currentUser = User(
          id: data['user']['user_id'].toString(),
          name: data['user']['username'],
          email: data['user']['email'],
          coins: data['user']['coins'] ?? 0,
          createdAt: DateTime.parse(data['user']['created_at']),
          updatedAt: DateTime.parse(data['user']['created_at']), // Utilise created_at comme fallback
          profilePicture: null,
          role: data['user']['role'],
          jwtToken: data['token'],
        );
        _currentUserEmail = data['user']['email'];
        _currentUserRole = data['user']['role'];
        
        // Sauvegarder le token et les données utilisateur localement
        await _saveTokenLocally(data['token']);
        await _saveUserLocally(_currentUser!);
        
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'Erreur de connexion';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Erreur de connexion: $e');
      _error = 'Erreur de connexion';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String username,
    required String email,
    required String password,
    String? role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}${Environment.endpoints.auth.register}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'role': role,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Succès de l'inscription, même sans token
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'Erreur lors de l\'inscription';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erreur réseau ou serveur';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
    _jwtToken = null;
    await _clearUserLocally();
    await _clearTokenLocally();
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? photoUrl,
  }) async {
    try {
      if (_currentUser == null) throw Exception('Aucun utilisateur connecté');

      _isLoading = true;
      notifyListeners();

      // Simuler un délai de mise à jour
      await Future.delayed(const Duration(seconds: 1));

      _currentUser = _currentUser!.copyWith(
        name: name,
        photoUrl: photoUrl,
      );

      await _saveUserLocally(_currentUser!);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _saveUserLocally(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
    await prefs.setString('userRole', user.role ?? 'user');
    _jwtToken = user.jwtToken;
    _currentUser = user;
    _currentUserRole = user.role ?? 'user';
    notifyListeners();
  }

  Future<void> _saveTokenLocally(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<void> _clearUserLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('userRole');
  }

  Future<void> _clearTokenLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      print('Envoi de la requête pour obtenir tous les utilisateurs...');
      print('Token JWT: $_jwtToken');
      
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/auth/users/getuser'),
        headers: {
          'Content-Type': 'application/json',
          if (_jwtToken != null) 'Authorization': 'Bearer $_jwtToken',
        },
      );

      print('Réponse du serveur: ${response.statusCode}');
      print('Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic>? data = jsonDecode(response.body);
        return (data?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[]);
      } else {
        return <Map<String, dynamic>>[];
      }
    } catch (e) {
      print('Erreur réseau: $e');
      return <Map<String, dynamic>>[];
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${Environment.apiBaseUrl}${Environment.endpoints.auth.login}/users/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (_jwtToken != null) 'Authorization': 'Bearer $_jwtToken',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        _error = 'Erreur lors de la suppression de l\'utilisateur';
        return false;
      }
    } catch (e) {
      _error = 'Erreur réseau: $e';
      return false;
    }
  }

  Future<bool> createDirector({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}${Environment.endpoints.auth.login}/register'),
        headers: {
          'Content-Type': 'application/json',
          if (_jwtToken != null) 'Authorization': 'Bearer $_jwtToken',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'role': 'realisateur',
        }),
      );
      final data = jsonDecode(response.body);
      return response.statusCode == 201 || (response.statusCode == 200 && data['user'] != null);
    } catch (e) {
      _error = 'Erreur réseau ou serveur';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user');
    await prefs.remove('userRole');
    _jwtToken = null;
    _currentUser = null;
    _currentUserRole = null;
    _currentUserEmail = null;
    notifyListeners();
  }

  Future<String?> getToken() async {
    if (_jwtToken != null) {
      return _jwtToken;
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      _jwtToken = token;
      notifyListeners();
    }
    return token;
  }

  Future<User?> getCurrentUser() async {
    if (!isAuthenticated) return null;
    
    try {
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}${Environment.endpoints.auth.login}/users/me'),
        headers: {
          'Authorization': 'Bearer $_jwtToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        _currentUser = User.fromJson(userData);
        notifyListeners();
        return _currentUser;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  Future<void> _handleLoginResponse(Map<String, dynamic> data) async {
    _jwtToken = data['token'];
    _currentUser = User(
      id: data['user']['id'],
      name: data['user']['username'],
      email: data['user']['email'],
      coins: data['user']['coins'] ?? 0,
      createdAt: DateTime.parse(data['user']['created_at']),
      updatedAt: DateTime.parse(data['user']['updated_at']),
      profilePicture: data['user']['profile_picture'],
      role: data['user']['role'],
      jwtToken: data['token'],
    );
    _currentUserEmail = data['user']['email'];
    _currentUserRole = data['user']['role'];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}