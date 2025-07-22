# Module de Transcodage (transcode)

Ce module permet de transcoder des vidéos en plusieurs qualités HLS (240p, 480p, 720p) et de générer les manifestes HLS (.m3u8).

## Fonctionnalités
- Transcodage d'une vidéo source en plusieurs résolutions
- Génération des playlists HLS pour chaque qualité
- Génération d'un master playlist HLS

## Utilisation

### 1. Lancer le transcodage via l'API

POST `/api/transcode/hls`

Body (JSON) :
```json
{
  "videoUrl": "/chemin/vers/video.mp4",
  "outputDir": "/chemin/vers/sortie" // optionnel
}
```

Réponse :
```json
{
  "message": "Transcodage terminé",
  "outputDir": "/chemin/vers/sortie",
  "masterManifest": "/chemin/vers/sortie/master.m3u8",
  "renditions": [
    { "name": "240p", "playlist": "/chemin/vers/sortie/240p.m3u8" },
    { "name": "480p", "playlist": "/chemin/vers/sortie/480p.m3u8" },
    { "name": "720p", "playlist": "/chemin/vers/sortie/720p.m3u8" }
  ]
}
```

### 2. Dépendances
- ffmpeg doit être installé sur le serveur

### 3. À venir
- Worker/queue pour automatiser le transcodage après upload
- Support DASH 