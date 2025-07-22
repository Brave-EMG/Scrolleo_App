import 'package:flutter/material.dart';
import '../screens/directors_screen.dart';
import '../screens/profile/subscription_details_screen.dart';
import '../screens/profile/wallet_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/profile/help_support_screen.dart';

class AppRoutes {
  static const String directors = '/directors';
  static const String subscriptionDetails = '/subscription-details';
  static const String wallet = '/wallet';
  static const String settings = '/settings';
  static const String helpSupport = '/help-support';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      directors: (context) => const DirectorsScreen(),
      subscriptionDetails: (context) => const SubscriptionDetailsScreen(),
      wallet: (context) => const WalletScreen(),
      settings: (context) => const SettingsScreen(),
      helpSupport: (context) => const HelpSupportScreen(),
    };
  }
} 