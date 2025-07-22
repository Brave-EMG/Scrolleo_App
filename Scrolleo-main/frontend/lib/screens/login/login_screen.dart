import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/movie.dart';
import '../../config/environment.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  int _totalFilms = 0;
  int _totalViews = 0;
  double _avgRating = 0.0;
  List<Movie> _recentMovies = [];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 370),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  'SCROLLEO',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Se connecter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Accédez à votre compte SCROLLEO',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Colors.red),
                          prefixIcon: const Icon(Icons.email_outlined, color: Colors.red),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre email';
                          }
                          if (!value.contains('@')) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          labelStyle: const TextStyle(color: Colors.red),
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.red),
                          filled: true,
                          fillColor: Colors.grey[850],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre mot de passe';
                          }
                          if (value.length < 6) {
                            return 'Le mot de passe doit contenir au moins 6 caractères';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Se connecter',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go('/signup'),
                        child: const Text('Créer un compte', style: TextStyle(color: Colors.red)),
                      ),
                      TextButton(
                        onPressed: () => context.go('/forgot-password'),
                        child: const Text('Mot de passe oublié ?', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final success = await authService.signIn(
          _emailController.text,
          _passwordController.text,
        );

        if (success) {
          print('Connexion réussie!');
          print('Rôle: ${authService.currentUserRole}');
          
          // Navigation basée sur le rôle
          if (!mounted) return;
          
          if (authService.currentUserRole == 'admin') {
            context.go('/admin');
          } else if (authService.currentUserRole == 'realisateur') {
            context.go('/director');
          } else {
            context.go('/home');
          }
        } else {
          setState(() {
            _error = authService.error ?? 'Email ou mot de passe incorrect';
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Erreur lors de la connexion: $e');
        setState(() {
          _error = 'Une erreur est survenue';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchDirectorStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Utilisateur non connecté';
          _isLoading = false;
        });
        return;
      }
      final response = await http.get(Uri.parse('${Environment.apiBaseUrl}/movies/approved'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Movie> allMovies = data.map((e) => Movie.fromJson(e)).toList();
        final List<Movie> myMovies = allMovies.where((m) => m.director == user.id || m.director == user.email || m.directorUsername == user.name).toList();

        // Calculs
        int totalFilms = myMovies.length;
        int totalViews = myMovies.fold(0, (sum, m) => sum + m.views);
        double avgRating = myMovies.isNotEmpty
            ? myMovies.map((m) => m.rating ?? 0.0).reduce((a, b) => a + b) / myMovies.length
            : 0.0;
        myMovies.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
        List<Movie> recentMovies = myMovies.take(3).toList();

        setState(() {
          _totalFilms = totalFilms;
          _totalViews = totalViews;
          _avgRating = avgRating;
          _recentMovies = recentMovies;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Erreur lors de la récupération des films';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la récupération des films: $e';
        _isLoading = false;
      });
    }
  }
} 