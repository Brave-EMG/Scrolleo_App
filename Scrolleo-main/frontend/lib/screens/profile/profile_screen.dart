import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart' as theme;
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;
        final isLoggedIn = authService.isAuthenticated && user != null;
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < theme.AppTheme.mobileBreakpoint;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(
              'Profil',
              style: theme.AppTheme.screenTitle.copyWith(
                fontSize: isMobile ? 18.0 : 20.0,
                color: Colors.red[900],
              ),
            ),
            backgroundColor: Colors.black,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section d'en-tête
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: isMobile ? 40.0 : 50.0,
                        backgroundColor: Colors.grey[800],
                        child: Icon(
                          Icons.person,
                          size: isMobile ? 32.0 : 40.0,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: isMobile ? 12.0 : 16.0),
                      Text(
                        isLoggedIn ? (user?.name ?? 'Utilisateur') : 'Non connecté',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: isMobile ? 20.0 : 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isLoggedIn && user?.email != null) ...[
                        SizedBox(height: isMobile ? 4.0 : 8.0),
                        Text(
                          user!.email!,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: isMobile ? 14.0 : 16.0,
                          ),
                        ),
                      ],
                      if (!isLoggedIn) ...[
                        SizedBox(height: isMobile ? 8.0 : 12.0),
                        ElevatedButton(
                          onPressed: () => context.go('/login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16.0 : 20.0,
                              vertical: isMobile ? 8.0 : 12.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(theme.AppTheme.mediumRadius),
                            ),
                          ),
                          child: Text(
                            'Se connecter',
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 14.0 : 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 24.0 : 32.0),
                // Section des actions principales
                if (isLoggedIn) ...[
                  _buildActionCard(
                    context,
                    'Mon Abonnement',
                    Icons.star,
                    Colors.amber,
                    () => context.go('/subscription-details'),
                    isMobile,
                  ),
                  SizedBox(height: isMobile ? 12.0 : 16.0),
                  _buildActionCard(
                    context,
                    'Mon Portefeuille',
                    Icons.account_balance_wallet,
                    Colors.green,
                    () => context.go('/wallet'),
                    isMobile,
                  ),
                  SizedBox(height: isMobile ? 12.0 : 16.0),
                  _buildActionCard(
                    context,
                    'Paramètres',
                    Icons.settings,
                    Colors.blue,
                    () => context.go('/settings'),
                    isMobile,
                  ),
                  SizedBox(height: isMobile ? 12.0 : 16.0),
                ],
                _buildActionCard(
                  context,
                  'Aide & Support',
                  Icons.help,
                  Colors.orange,
                  () => context.go('/help-support'),
                  isMobile,
                ),
                SizedBox(height: isMobile ? 24.0 : 32.0),
                // Section des informations utilisateur
                // if (isLoggedIn && user != null) ...[
                //   _buildInfoSection(
                //     context,
                //     'Informations du compte',
                //     [
                //       _buildInfoRow('ID Utilisateur', user.id.toString(), isMobile),
                //       _buildInfoRow('Nom d\'utilisateur', user.name, isMobile),
                //       if (user.email != null)
                //         _buildInfoRow('Email', user.email!, isMobile),
                //       _buildInfoRow('Rôle', user.role ?? 'Utilisateur', isMobile),
                //     ],
                //     isMobile,
                //   ),
                // ],
                SizedBox(height: isMobile ? 24.0 : 32.0),
                // Bouton de déconnexion
                if (isLoggedIn) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await authService.logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 12.0 : 16.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(theme.AppTheme.mediumRadius),
                        ),
                      ),
                      child: Text(
                        'Se déconnecter',
                        style: theme.AppTheme.bodyLarge.copyWith(
                          fontSize: isMobile ? 16.0 : 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isMobile,
  ) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.AppTheme.mediumRadius),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: color,
          size: isMobile ? 24.0 : 28.0,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 16.0 : 18.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: isMobile ? 16.0 : 18.0,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    List<Widget> children,
    bool isMobile,
  ) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.AppTheme.mediumRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 12.0 : 16.0),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 4.0 : 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: isMobile ? 14.0 : 16.0,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 14.0 : 16.0,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} 