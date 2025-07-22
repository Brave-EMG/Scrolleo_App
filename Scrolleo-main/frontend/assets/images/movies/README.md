# Images des Films

Ce dossier contient les images associées aux films de la plateforme de streaming.

## Structure des dossiers

- `thumbnails/` : Contient les miniatures des films (format recommandé : 300x450 pixels)
  - Les miniatures doivent être au format JPG ou PNG
  - Le nom du fichier doit correspondre à l'ID du film dans la base de données
  - Exemple : `1.jpg` pour le film avec l'ID 1

## Bonnes pratiques

1. Optimisez les images pour le web (compression sans perte de qualité visible)
2. Utilisez des noms de fichiers cohérents avec les IDs de la base de données
3. Maintenez un ratio d'aspect cohérent pour toutes les miniatures
4. Vérifiez les droits d'auteur avant d'ajouter des images

## Ajout de nouvelles images

1. Placez la miniature dans le dossier `thumbnails/`
2. Nommez le fichier selon l'ID du film
3. Vérifiez que l'image est correctement optimisée
4. Mettez à jour la documentation si nécessaire 