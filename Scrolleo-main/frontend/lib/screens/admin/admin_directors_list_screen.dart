import 'package:flutter/material.dart';

class AdminDirectorsListScreen extends StatelessWidget {
  const AdminDirectorsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Remplacer par la vraie liste des réalisateurs (API)
    final List<Map<String, dynamic>> directors = [
      {'id': 1, 'name': 'Réalisateur 1'},
      {'id': 2, 'name': 'Réalisateur 2'},
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des réalisateurs'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: ListView.builder(
        itemCount: directors.length,
        itemBuilder: (context, i) {
          final director = directors[i];
          return ListTile(
            title: Text(director['name'], style: const TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward, color: Colors.orange),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/admin/director_movies',
                arguments: {'directorId': director['id'], 'directorName': director['name']},
              );
            },
          );
        },
      ),
    );
  }
} 