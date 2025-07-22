import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final role = authService.currentUserRole;
    final localeService = Provider.of<LocaleService>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600.0; // Breakpoint mobile
    
    if (role == 'admin') {
      return const SizedBox.shrink();
    }
    if (role == 'realisateur') {
      return const SizedBox.shrink();
    }
    
    return Container(
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
        currentIndex: selectedIndex,
        onTap: onItemTapped,
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
    );
  }
} 