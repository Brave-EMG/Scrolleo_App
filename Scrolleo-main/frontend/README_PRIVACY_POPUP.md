# Pop-up de Politique de Confidentialité - Scrolleo

Ce document explique comment utiliser et tester le pop-up de politique de confidentialité créé pour Scrolleo.

## 📋 Description

Le pop-up de politique de confidentialité s'affiche automatiquement lors de la première visite d'un utilisateur sur Scrolleo. Il contient :

- **Titre** : "Politique de Confidentialité"
- **Message de bienvenue** : Explication de l'engagement de Scrolleo envers la protection des données
- **Points clés** : 3 points importants sur la sécurité des données
- **Deux boutons** :
  - "Lire la Politique de Confidentialité" (ouvre l'URL externe)
  - "Accepter" (ferme le pop-up et enregistre l'acceptation)

## 🎨 Design

Le pop-up utilise le thème sombre de Scrolleo avec :
- Couleurs cohérentes avec l'application
- Bordures arrondies (20px)
- Ombres pour la profondeur
- Icônes Material Design
- Typographie hiérarchisée

## 🚀 Comment tester

### Option 1 : Application de test dédiée

1. **Lancer l'application de test** :
   ```bash
   cd frontend
   flutter run -t test_privacy_dialog.dart
   ```

2. **Le pop-up s'affiche automatiquement** après 500ms

3. **Prendre une capture d'écran** du pop-up

### Option 2 : Via l'application principale

1. **Lancer l'application principale** :
   ```bash
   cd frontend
   flutter run
   ```

2. **Naviguer vers l'écran de test** :
   - Aller à l'URL : `/test/privacy-dialog`
   - Ou ajouter un bouton temporaire dans l'interface

3. **Cliquer sur "Afficher le Pop-up"**

4. **Prendre une capture d'écran**

## 📱 Capture d'écran

Pour obtenir une belle capture d'écran du pop-up :

1. **Assurez-vous que l'application est en mode sombre**
2. **Affichez le pop-up**
3. **Prenez la capture d'écran** avec le pop-up centré
4. **Le pop-up ne peut pas être fermé** en cliquant à l'extérieur (barrierDismissible: false)

## 🔧 Fonctionnalités

### Service de gestion (`PrivacyService`)

- `hasAcceptedPrivacyPolicy()` : Vérifie si l'utilisateur a accepté
- `acceptPrivacyPolicy()` : Marque comme acceptée
- `resetPrivacyAcceptance()` : Réinitialise pour les tests

### Widget (`PrivacyPolicyDialog`)

- Design responsive
- Gestion des erreurs
- Ouverture de l'URL externe
- Callback d'acceptation

## 📄 Intégration dans l'application

Pour intégrer le pop-up dans l'application principale :

1. **Dans le SplashScreen ou HomeScreen**, vérifier si l'utilisateur a accepté :
   ```dart
   final hasAccepted = await PrivacyService.hasAcceptedPrivacyPolicy();
   if (!hasAccepted) {
     // Afficher le pop-up
   }
   ```

2. **Afficher le pop-up** :
   ```dart
   showDialog(
     context: context,
     barrierDismissible: false,
     builder: (context) => PrivacyPolicyDialog(
       onAccepted: () {
         // Continuer vers l'application
       },
     ),
   );
   ```

## 🎯 Points clés du design

- **Couleur primaire** : Utilise la couleur primaire de Scrolleo
- **Icône de confidentialité** : `Icons.privacy_tip_outlined`
- **Boutons** : Style cohérent avec l'application
- **Texte** : Hiérarchie claire avec différentes tailles
- **Espacement** : Marges et paddings harmonieux

## 📝 Personnalisation

Pour personnaliser le pop-up :

1. **Modifier le texte** dans `PrivacyPolicyDialog`
2. **Changer l'URL** de la politique de confidentialité
3. **Ajuster les couleurs** via le thème
4. **Modifier les icônes** des points clés

## 🔒 Sécurité

- L'acceptation est stockée localement avec `SharedPreferences`
- Le pop-up ne peut pas être fermé sans action de l'utilisateur
- L'URL externe s'ouvre dans le navigateur par défaut

---

**Note** : Ce pop-up respecte les normes RGPD et les bonnes pratiques de protection des données personnelles. 