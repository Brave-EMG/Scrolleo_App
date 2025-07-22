# Backend - Streaming Platform

API backend pour la plateforme de streaming.

## Fonctionnalités

- Upload de fichiers multiples avec validation
- Gestion des formats de fichiers
- Stockage sécurisé
- API RESTful
- Gestion des erreurs détaillée

## Installation

1. Installer les dépendances
```bash
npm install
```

2. Configurer l'environnement
```bash
cp .env.example .env
# Éditer le fichier .env
```

3. Démarrer le serveur
```bash
npm start
```

## API Endpoints

### Uploads

- `POST /api/uploads`
  - Upload multiple de fichiers (vidéos, miniatures, sous-titres)
  - Formats acceptés :
    - Vidéos : MP4, QuickTime, AVI, MKV, WebM
    - Miniatures : JPEG, PNG, GIF, WebP
    - Sous-titres : TXT, SRT, VTT
  - Limite : 10 fichiers par type
  - Taille maximale : 500MB par fichier

- `GET /api/uploads/:id`
  - Récupérer les détails d'un upload

- `PATCH /api/uploads/:id/status`
  - Mettre à jour le statut d'un upload

- `DELETE /api/uploads/:id`
  - Supprimer un upload

## Structure du code

```
backend/
├── src/
│   ├── config/          # Configuration
│   │   ├── database.js  # Configuration DB
│   │   └── app.js       # Configuration Express
│   ├── routes/          # Routes API
│   ├── services/        # Services métier
│   └── models/          # Modèles de données
├── uploads/             # Dossiers d'upload
│   ├── videos/          # Vidéos
│   ├── thumbnails/      # Miniatures
│   └── subtitles/       # Sous-titres
└── package.json
```

## Configuration

### Base de données

Configuration PostgreSQL dans `src/config/database.js` :

```javascript
const pool = new Pool({
  user: process.env.POSTGRES_USER,
  host: process.env.POSTGRES_HOST,
  database: process.env.POSTGRES_DB,
  password: process.env.POSTGRES_PASSWORD,
  port: process.env.POSTGRES_PORT
});
```

### Uploads

Configuration des dossiers d'upload dans `src/services/uploadService.js` :

```javascript
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    // Dossiers par type de fichier
  },
  filename: function (req, file, cb) {
    // Nommage des fichiers
  }
});
```

## Tests

```bash
npm test
```

## Déploiement

1. Construire l'application
```bash
npm run build
```

2. Démarrer en production
```bash
npm start
```

## Sécurité

- Validation des formats de fichiers
- Limitation de la taille des fichiers
- Nettoyage des fichiers invalides
- Gestion sécurisée des uploads 