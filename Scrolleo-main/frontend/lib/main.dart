import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'screens/home/home_screen.dart';
import 'screens/favorites/favorites_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/reels/reels_screen.dart';
import 'screens/subscription/subscription_screen.dart';
import 'screens/signup/signup_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_episode_upload_screen.dart';
import 'screens/admin/admin_manage_episodes_screen.dart' show EpisodeVideoScreen;
import 'screens/splash/splash_screen.dart';
import 'screens/director/director_dashboard_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/admin/admin_directors_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/test/privacy_dialog_test_screen.dart';
import 'screens/profile/subscription_details_screen.dart';
import 'screens/profile/wallet_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/profile/help_support_screen.dart';
import 'services/movie_service.dart';
import 'services/user_service.dart';
import 'services/settings_service.dart';
import 'services/locale_service.dart';
import 'providers/favorites_provider.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'services/auth_service.dart';
import 'providers/likes_provider.dart';
import 'providers/favorites_episodes_provider.dart';
import 'services/favorites_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/history_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => MovieService(),
        ),
        ChangeNotifierProvider(
          create: (context) => UserService(),
        ),
        ChangeNotifierProvider(
          create: (context) => SettingsService()..loadSettings(),
        ),
        ChangeNotifierProvider(
          create: (context) => LocaleService()..loadLocale(),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthService(),
        ),
        Provider<FavoritesService>(
          create: (context) => FavoritesService(prefs),
        ),
        ChangeNotifierProxyProvider<MovieService, FavoritesProvider>(
          create: (context) => FavoritesProvider(context.read<MovieService>()),
          update: (context, movieService, previous) =>
              previous ?? FavoritesProvider(movieService),
        ),
        ChangeNotifierProvider(
          create: (context) => LikesProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => FavoritesEpisodesProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => HistoryProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleService>(
      builder: (context, localeService, child) {
        final router = GoRouter(
          initialLocation: '/splash',
          routes: [
            GoRoute(
              path: '/splash',
              builder: (context, state) => const SplashScreen(),
            ),
            GoRoute(
              path: '/',
              builder: (context, state) => const MainScreen(initialIndex: 0),
            ),
            GoRoute(
              path: '/home',
              builder: (context, state) => const MainScreen(initialIndex: 0),
            ),
            GoRoute(
              path: '/reels',
              builder: (context, state) => const MainScreen(initialIndex: 1),
            ),
            GoRoute(
              path: '/favorites',
              builder: (context, state) => const MainScreen(initialIndex: 2),
            ),
            GoRoute(
              path: '/history',
              builder: (context, state) => const MainScreen(initialIndex: 3),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const MainScreen(initialIndex: 4),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
            GoRoute(
              path: '/subscription-details',
              builder: (context, state) => const SubscriptionDetailsScreen(),
            ),
            GoRoute(
              path: '/wallet',
              builder: (context, state) => const WalletScreen(),
            ),
            GoRoute(
              path: '/help-support',
              builder: (context, state) => const HelpSupportScreen(),
            ),
            GoRoute(
              path: '/subscription',
              builder: (context, state) => const SubscriptionScreen(),
            ),
            GoRoute(
              path: '/signup',
              builder: (context, state) => const SignUpScreen(),
            ),
            GoRoute(
              path: '/login',
              builder: (context, state) => const LoginScreen(),
            ),
            GoRoute(
              path: '/admin',
              builder: (context, state) => const AdminDashboardScreen(),
            ),
            GoRoute(
              path: '/director',
              builder: (context, state) => const DirectorDashboardScreen(),
            ),
            GoRoute(
              path: '/admin/episode_upload',
              builder: (context, state) => const AdminEpisodeUploadScreen(),
            ),
            GoRoute(
              path: '/admin/episode_video',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                final videoUrl = extra?['videoUrl'] as String? ?? '';
                return EpisodeVideoScreen();
              },
            ),
            GoRoute(
              path: '/admin/directors',
              builder: (context, state) => const AdminDirectorsScreen(),
            ),
            GoRoute(
              path: '/forgot-password',
              builder: (context, state) => const ForgotPasswordScreen(),
            ),
            GoRoute(
              path: '/reset-password/:token',
              builder: (context, state) {
                final token = state.pathParameters['token']!;
                return ResetPasswordScreen(token: token);
              },
            ),
            GoRoute(
              path: '/test/privacy-dialog',
              builder: (context, state) => const PrivacyDialogTestScreen(),
            ),
          ],
        );

        return MaterialApp.router(
          title: 'SCROLLEO',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          debugShowCheckedModeBanner: false,
          locale: localeService.locale,
          supportedLocales: const [
            Locale('fr'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ReelsScreen(),
    const FavoritesScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            label: 'Pour Vous',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoris',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
} 