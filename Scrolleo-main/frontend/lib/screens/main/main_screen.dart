import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../favorites/favorites_screen.dart';
import '../profile/profile_screen.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    HomeScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final role = authService.currentUserRole;
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < AppTheme.mobileBreakpoint;

        if (role == 'admin') {
          Future.microtask(() {
            context.go('/admin');
          });
          return const SizedBox.shrink();
        }
        if (role == 'realisateur') {
          Future.microtask(() {
            context.go('/director');
          });
          return const SizedBox.shrink();
        }
        return Scaffold(
          body: _screens[_selectedIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                top: BorderSide(
                  color: Colors.grey[800]!,
                  width: 0.5,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              backgroundColor: Colors.transparent,
              selectedItemColor: Colors.amber,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedFontSize: isMobile ? 12.0 : 14.0,
              unselectedFontSize: isMobile ? 11.0 : 13.0,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.home_outlined,
                    size: isMobile ? 20.0 : 24.0,
                  ),
                  activeIcon: Icon(
                    Icons.home,
                    size: isMobile ? 20.0 : 24.0,
                  ),
                  label: 'Accueil',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.favorite_outline,
                    size: isMobile ? 20.0 : 24.0,
                  ),
                  activeIcon: Icon(
                    Icons.favorite,
                    size: isMobile ? 20.0 : 24.0,
                  ),
                  label: 'Favoris',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.person_outline,
                    size: isMobile ? 20.0 : 24.0,
                  ),
                  activeIcon: Icon(
                    Icons.person,
                    size: isMobile ? 20.0 : 24.0,
                  ),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 