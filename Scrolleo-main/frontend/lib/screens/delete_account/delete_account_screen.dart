import 'package:flutter/material.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({Key? key}) : super(key: key);

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232323),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232323),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Suppression de compte',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Si vous supprimez votre compte, toutes les informations de ce compte seront supprimées et ne pourront pas être récupérées.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Vous devez accepter de supprimer les informations suivantes :',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            _infoCard(
              icon: Icons.person,
              color: Colors.orange,
              title: 'Informations personnelles',
              description: 'Vos informations personnelles comprenant l\'adresse électronique et le pseudonyme seront supprimées.',
            ),
            _infoCard(
              icon: Icons.assignment,
              color: Colors.deepOrange,
              title: 'Informations sur le compte tiers',
              description: '',
            ),
            _infoCard(
              icon: Icons.access_time,
              color: Colors.lightBlue,
              title: 'Historique',
              description: 'Historique de consommation, Historique de recharge, Historique de déverrouillage des chapitres, Mes Favoris.',
            ),
            _infoCard(
              icon: Icons.account_balance_wallet,
              color: Colors.amber,
              title: 'Solde du compte',
              description: 'Toutes vos monnaies virtuelles ont été consommées et vous pouvez supprimer votre compte.',
            ),
            _infoCard(
              icon: Icons.workspace_premium,
              color: Colors.brown,
              title: 'Avantages liés aux VIP',
              description: 'Votre compte n\'est pas actuellement en statut VIP.',
            ),
            _infoCard(
              icon: Icons.error_outline,
              color: Colors.red,
              title: '',
              description: 'Veuillez vous déconnecter à temps votre compte sur d\'autres appareils, sinon l\'application sur d\'autres appareils sera indisponible.',
            ),
            const Spacer(),
            Row(
              children: [
                Checkbox(
                  value: _accepted,
                  onChanged: (val) {
                    setState(() {
                      _accepted = val ?? false;
                    });
                  },
                  activeColor: Colors.deepOrange,
                ),
                const Expanded(
                  child: Text(
                    "J'accepte le risque de suppression et je suis d'accord pour supprimer mon compte",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _accepted ? () {/* Action de suppression */} : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  backgroundColor: _accepted ? Colors.deepOrange : Colors.grey,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                child: const Text('Supprimer le compte'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 24),
            radius: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                if (description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      description,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 