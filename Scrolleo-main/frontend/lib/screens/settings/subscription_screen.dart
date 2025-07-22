import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  Widget _buildPlanCard({
    required String title,
    required String price,
    required List<String> features,
    required bool isPopular,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isPopular
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : null,
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Text(
                'PLUS POPULAIRE',
                style: TextStyle(
                  color: AppTheme.backgroundColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  price,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implémenter la souscription
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular
                          ? AppTheme.primaryColor
                          : AppTheme.backgroundColor,
                      foregroundColor: isPopular
                          ? AppTheme.backgroundColor
                          : AppTheme.primaryColor,
                      side: isPopular
                          ? null
                          : const BorderSide(color: AppTheme.primaryColor),
                    ),
                    child: const Text('Choisir ce plan'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Abonnement'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choisissez votre plan',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildPlanCard(
              title: 'Basique',
              price: '4.99€/mois',
              features: [
                'Accès à tous les films',
                'Qualité HD',
                'Sur 1 appareil',
                'Sans publicité',
              ],
              isPopular: false,
            ),
            _buildPlanCard(
              title: 'Premium',
              price: '5000 FCFA/mois',
              features: [
                'Accès à tous les films',
                'Qualité 4K Ultra HD',
                'Sur 4 appareils',
                'Sans publicité',
                'Téléchargements disponibles',
                'Accès en avant-première',
              ],
              isPopular: true,
            ),
            _buildPlanCard(
              title: 'Famille',
              price: '14.99€/mois',
              features: [
                'Accès à tous les films',
                'Qualité 4K Ultra HD',
                'Sur 6 appareils',
                'Sans publicité',
                'Téléchargements disponibles',
                'Accès en avant-première',
                'Contrôle parental avancé',
              ],
              isPopular: false,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}