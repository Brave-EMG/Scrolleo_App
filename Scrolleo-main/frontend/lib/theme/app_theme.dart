import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Couleurs personnalisées
  static const Color redDeep = Color(0xFF9C1B1F); // Rouge profond
  static const Color whitePure = Color(0xFFFFFFFF); // Blanc pur
  static const Color blackNight = Color(0xFF111111); // Noir nuit

  // Couleurs du thème sombre
  static const darkBackgroundColor = Color(0xFF0F0F0F);
  static const darkSecondaryBackgroundColor = Color(0xFF1E1E1E);
  static const darkPrimaryTextColor = Color(0xFFFFFFFF);
  static const darkSecondaryTextColor = Color(0xFFB3B3B3);
  static const darkAccentColor = Color(0xFFE50914);
  static const darkAccentHoverColor = Color(0xFFB81D24);
  static const darkBorderColor = Color(0xFF2C2C2C);
  
  // Couleurs du thème clair
  static const lightBackgroundColor = Color(0xFFFFFFFF);
  static const lightSecondaryBackgroundColor = Color(0xFFF5F5F5);
  static const lightPrimaryTextColor = Color(0xFF0F0F0F);
  static const lightSecondaryTextColor = Color(0xFF4A4A4A);
  static const lightAccentColor = Color(0xFFE50914);
  static const lightAccentHoverColor = Color(0xFFB81D24);
  static const lightBorderColor = Color(0xFFE0E0E0);
  
  // Constantes pour la responsivité
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  
  // Tailles de police responsives
  static const double h1Size = 24.0;
  static const double h2Size = 20.0;
  static const double h3Size = 18.0;
  static const double bodySize = 16.0;
  static const double captionSize = 14.0;
  static const double smallSize = 12.0;
  
  // Espacements responsifs
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;
  
  // Rayons de bordure
  static const double smallRadius = 8.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 18.0;
  
  // Hauteurs responsives
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 60.0;
  static const double cardHeight = 200.0;
  static const double movieCardHeight = 280.0;
  
  // Largeurs responsives
  static const double movieCardWidth = 170.0;
  static const double smallCardWidth = 120.0;
  
  // Méthode pour obtenir la taille de police responsive
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return baseSize * 0.9; // Plus petit sur mobile
    } else if (width < tabletBreakpoint) {
      return baseSize; // Taille normale sur tablette
    } else {
      return baseSize * 1.1; // Plus grand sur desktop
    }
  }
  
  // Méthode pour obtenir le padding responsive
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return const EdgeInsets.all(smallPadding);
    } else if (width < tabletBreakpoint) {
      return const EdgeInsets.all(mediumPadding);
    } else {
      return const EdgeInsets.all(largePadding);
    }
  }
  
  // Méthode pour obtenir le nombre de colonnes responsive
  static int getResponsiveCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return 2; // 2 colonnes sur mobile
    } else if (width < tabletBreakpoint) {
      return 3; // 3 colonnes sur tablette
    } else {
      return 4; // 4 colonnes sur desktop
    }
  }

  // Thème sombre
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: redDeep,
      secondary: redDeep,
      background: blackNight,
      surface: blackNight,
      onPrimary: whitePure,
      onSecondary: whitePure,
      onBackground: whitePure,
      onSurface: whitePure,
      error: redDeep,
      onError: whitePure,
    ),
    scaffoldBackgroundColor: blackNight,
    appBarTheme: AppBarTheme(
      backgroundColor: blackNight,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: whitePure),
      titleTextStyle: GoogleFonts.comfortaa(
        color: redDeep,
        fontSize: h2Size,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      toolbarHeight: appBarHeight,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: blackNight,
      selectedItemColor: redDeep,
      unselectedItemColor: Colors.grey[400],
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    cardTheme: CardThemeData(
      color: Colors.grey[900],
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
        side: const BorderSide(color: Color(0xFF222222)),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        color: whitePure,
        fontSize: h1Size,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.poppins(
        color: whitePure,
        fontSize: h2Size,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: GoogleFonts.poppins(
        color: whitePure,
        fontSize: h3Size,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.comfortaa(
        color: redDeep,
        fontSize: h2Size,
        fontWeight: FontWeight.bold,
      ), // Pour le logo
      bodyLarge: GoogleFonts.inter(
        color: whitePure,
        fontSize: bodySize,
      ),
      bodyMedium: GoogleFonts.inter(
        color: whitePure,
        fontSize: captionSize,
      ),
      bodySmall: GoogleFonts.inter(
        color: Colors.grey[400],
        fontSize: smallSize,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: redDeep,
        foregroundColor: whitePure,
        textStyle: GoogleFonts.poppins(
          fontSize: bodySize,
          fontWeight: FontWeight.bold,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: largePadding,
          vertical: mediumPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(mediumRadius),
        ),
        minimumSize: const Size(120, 48),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF222222),
      thickness: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[900]!,
      selectedColor: redDeep,
      labelStyle: GoogleFonts.inter(color: whitePure),
      padding: const EdgeInsets.symmetric(horizontal: smallPadding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
      ),
    ),
  );

  // Thème clair (similaire, mais fond blanc et texte noir)
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: redDeep,
      secondary: redDeep,
      background: whitePure,
      surface: whitePure,
      onPrimary: blackNight,
      onSecondary: blackNight,
      onBackground: blackNight,
      onSurface: blackNight,
      error: redDeep,
      onError: whitePure,
    ),
    scaffoldBackgroundColor: whitePure,
    appBarTheme: AppBarTheme(
      backgroundColor: whitePure,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: blackNight),
      titleTextStyle: GoogleFonts.comfortaa(
        color: redDeep,
        fontSize: h2Size,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      toolbarHeight: appBarHeight,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: whitePure,
      selectedItemColor: redDeep,
      unselectedItemColor: Colors.grey[700],
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    cardTheme: CardThemeData(
      color: Colors.grey[100],
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        color: blackNight,
        fontSize: h1Size,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.poppins(
        color: blackNight,
        fontSize: h2Size,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: GoogleFonts.poppins(
        color: blackNight,
        fontSize: h3Size,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.comfortaa(
        color: redDeep,
        fontSize: h2Size,
        fontWeight: FontWeight.bold,
      ), // Pour le logo
      bodyLarge: GoogleFonts.inter(
        color: blackNight,
        fontSize: bodySize,
      ),
      bodyMedium: GoogleFonts.inter(
        color: blackNight,
        fontSize: captionSize,
      ),
      bodySmall: GoogleFonts.inter(
        color: Colors.grey[700],
        fontSize: smallSize,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: redDeep,
        foregroundColor: whitePure,
        textStyle: GoogleFonts.poppins(
          fontSize: bodySize,
          fontWeight: FontWeight.bold,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: largePadding,
          vertical: mediumPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(mediumRadius),
        ),
        minimumSize: const Size(120, 48),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[100]!,
      selectedColor: redDeep,
      labelStyle: GoogleFonts.inter(color: blackNight),
      padding: const EdgeInsets.symmetric(horizontal: smallPadding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
      ),
    ),
  );

  // Styles de texte réutilisables avec responsivité
  static TextStyle getH1Style(BuildContext context) => TextStyle(
    fontSize: getResponsiveFontSize(context, h1Size),
    fontWeight: FontWeight.bold,
    color: darkPrimaryTextColor,
  );

  static TextStyle getH2Style(BuildContext context) => TextStyle(
    fontSize: getResponsiveFontSize(context, h2Size),
    fontWeight: FontWeight.w600,
    color: darkPrimaryTextColor,
  );

  static TextStyle getH3Style(BuildContext context) => TextStyle(
    fontSize: getResponsiveFontSize(context, h3Size),
    fontWeight: FontWeight.w500,
    color: darkPrimaryTextColor,
  );

  static TextStyle getBodyStyle(BuildContext context) => TextStyle(
    fontSize: getResponsiveFontSize(context, bodySize),
    color: darkPrimaryTextColor,
  );

  static TextStyle getCaptionStyle(BuildContext context) => TextStyle(
    fontSize: getResponsiveFontSize(context, captionSize),
    color: darkSecondaryTextColor,
  );

  static TextStyle getSmallStyle(BuildContext context) => TextStyle(
    fontSize: getResponsiveFontSize(context, smallSize),
    color: darkSecondaryTextColor,
  );
} 