import 'package:flutter/material.dart';

class AdminUserDetailsDialog extends StatelessWidget {
  final Map<String, String> user;
  const AdminUserDetailsDialog({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Données fictives pour la démo
    final isRealisateur = user['role'] == 'Réalisateur';
    final visionnages = user['name'] == 'Alice' ? 12 : 5;
    final likes = user['name'] == 'Alice' ? 7 : 2;
    final dateCreation = '2023-01-15';
    final derniereConnexion = '2024-06-01';
    final statut = 'Actif';
    final abonnement = 'Premium';
    final dateFinAbo = '2024-12-31';
    final filmsUploades = isRealisateur ? 3 : 0;
    final films = isRealisateur ? ['Film A', 'Film B', 'Film C'] : [];

    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blueGrey,
                    child: Text(user['name']![0], style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['name']!, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(user['email']!, style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isRealisateur ? Colors.orange : Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(user['role']!, style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _infoChip(Icons.calendar_today, 'Créé le', dateCreation),
                  _infoChip(Icons.login, 'Dernière connexion', derniereConnexion),
                  _infoChip(Icons.verified_user, 'Statut', statut),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _infoChip(Icons.remove_red_eye, 'Visionnages', visionnages.toString()),
                  _infoChip(Icons.favorite, "J'aime", likes.toString()),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _infoChip(Icons.workspace_premium, 'Abonnement', abonnement),
                  _infoChip(Icons.date_range, 'Fin abonnement', dateFinAbo),
                ],
              ),
              if (isRealisateur) ...[
                const SizedBox(height: 20),
                Text('Films uploadés', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                for (var film in films)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.movie, color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Text(film, style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                _infoChip(Icons.movie_creation, 'Total films', filmsUploades.toString()),
              ],
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text('$label : ', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
} 