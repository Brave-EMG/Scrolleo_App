import 'package:flutter/material.dart';
import '../models/movie.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../config/environment.dart';
import '../theme/app_theme.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onManageEpisodes;
  final bool isLiked;
  final VoidCallback? onLikeToggle;

  const MovieCard({
    Key? key,
    required this.movie,
    this.onTap,
    this.isAdmin = false,
    this.onEdit,
    this.onDelete,
    this.onManageEpisodes,
    this.isLiked = false,
    this.onLikeToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppTheme.mobileBreakpoint;
    final isTablet = screenWidth < AppTheme.tabletBreakpoint && screenWidth >= AppTheme.mobileBreakpoint;
    
    // Calcul des dimensions responsives
    final cardWidth = isMobile ? 140.0 : (isTablet ? 160.0 : 170.0);
    final cardHeight = isMobile ? 235.0 : (isTablet ? 255.0 : 275.0);
    final imageHeight = isMobile ? 175.0 : (isTablet ? 195.0 : 205.0);
    final titleFontSize = isMobile ? 13.0 : (isTablet ? 14.0 : 15.0);
    final badgeFontSize = isMobile ? 11.0 : (isTablet ? 12.0 : 13.0);
    final iconSize = isMobile ? 24.0 : (isTablet ? 26.0 : 28.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: EdgeInsets.symmetric(
          horizontal: isMobile ? 6.0 : 8.0,
          vertical: isMobile ? 6.0 : 8.0,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.largeRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section image avec Stack
            Container(
              width: double.infinity,
              height: imageHeight,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.largeRadius),
                    child: Image.network(
                      _getValidImageUrl(movie.posterUrl),
                      width: double.infinity,
                      height: imageHeight,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: imageHeight,
                          color: Colors.grey[800],
                          child: const Center(
                            child: Icon(
                              Icons.movie,
                              color: Colors.white54,
                              size: 48,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Overlay dégradé + titre
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8.0 : 10.0,
                        vertical: isMobile ? 8.0 : 10.0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(AppTheme.largeRadius),
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black87,
                          ],
                        ),
                      ),
                      child: Text(
                        movie.title.isNotEmpty ? movie.title : 'Sans titre',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: titleFontSize,
                          shadows: const [
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Badge année orange
                  Positioned(
                    top: isMobile ? 8.0 : 10.0,
                    right: isMobile ? 10.0 : 12.0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 6.0 : 8.0,
                        vertical: isMobile ? 3.0 : 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        movie.releaseDate.year.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: badgeFontSize,
                        ),
                      ),
                    ),
                  ),
                  if (!isAdmin)
                    Positioned(
                      bottom: isMobile ? 10.0 : 12.0,
                      right: isMobile ? 10.0 : 12.0,
                      child: IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey,
                          size: iconSize,
                        ),
                        onPressed: () async {
                          if (onLikeToggle != null) {
                            final authService = Provider.of<AuthService>(context, listen: false);
                            if (!authService.isAuthenticated) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vous devez être connecté pour liker un film'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }
                            
                            onLikeToggle?.call();
                            // Animation de feedback
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isLiked ? 'Film retiré des likes' : 'Film ajouté aux likes'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        tooltip: isLiked ? 'Retirer des likes' : 'Liker',
                      ),
                    ),
                ],
              ),
            ),
            // Section infos et boutons
            Container(
              padding: EdgeInsets.all(isMobile ? 4.0 : 6.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Genres avec gestion de l'overflow
                  Wrap(
                    spacing: isMobile ? 2.0 : 4.0,
                    runSpacing: isMobile ? 1.0 : 2.0,
                    children: movie.genres.take(isMobile ? 2 : 3).map((g) => Chip(
                      label: Text(
                        g,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 9.0 : 11.0,
                        ),
                      ),
                      backgroundColor: Colors.blue[700],
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 4.0 : 6.0,
                        vertical: 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      visualDensity: VisualDensity.compact,
                    )).toList(),
                  ),
                  if (isAdmin) ...[
                    SizedBox(height: isMobile ? 4.0 : 6.0),
                    // Boutons admin responsifs
                    if (isMobile)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAdminButton(
                            context,
                            'Modifier',
                            Icons.edit,
                            Colors.blueAccent,
                            onEdit,
                            isMobile,
                          ),
                          SizedBox(height: isMobile ? 3.0 : 6.0),
                          _buildAdminButton(
                            context,
                            'Supprimer',
                            Icons.delete,
                            Colors.redAccent,
                            onDelete,
                            isMobile,
                          ),
                          SizedBox(height: isMobile ? 3.0 : 6.0),
                          _buildAdminButton(
                            context,
                            'Épisodes',
                            Icons.playlist_play,
                            Colors.deepPurple,
                            onManageEpisodes,
                            isMobile,
                          ),
                        ],
                      )
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildAdminButton(
                                context,
                                'Modifier',
                                Icons.edit,
                                Colors.blueAccent,
                                onEdit,
                                isMobile,
                              ),
                              SizedBox(width: isMobile ? 6.0 : 12.0),
                              _buildAdminButton(
                                context,
                                'Supprimer',
                                Icons.delete,
                                Colors.redAccent,
                                onDelete,
                                isMobile,
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 3.0 : 6.0),
                          _buildAdminButton(
                            context,
                            'Gérer les épisodes',
                            Icons.playlist_play,
                            Colors.deepPurple,
                            onManageEpisodes,
                            isMobile,
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
    bool isMobile,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: Colors.white,
        size: isMobile ? 14.0 : 18.0,
      ),
      label: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: isMobile ? 10.0 : 12.0,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 4.0 : 8.0,
          vertical: isMobile ? 3.0 : 6.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
      ),
    );
  }

  String _getValidImageUrl(String url) {
    if (url.isEmpty) {
      return 'https://via.placeholder.com/300x400?text=No+Image';
    }
    if (url.startsWith('http')) {
      return url;
    }
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      return 'https://via.placeholder.com/300x400?text=No+Image';
    }
    final baseUrl = Environment.apiBaseUrl.replaceAll('/api','');
    if (!cleanUrl.startsWith('/uploads/')) {
      final cleanPath = cleanUrl.replaceAll('/uploads/', '');
      return '$baseUrl/uploads/$cleanPath';
    }
    return '$baseUrl$cleanUrl';
  }
}