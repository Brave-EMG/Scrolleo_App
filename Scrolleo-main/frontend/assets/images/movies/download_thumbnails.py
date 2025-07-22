import os
import requests
from PIL import Image
from io import BytesIO

# Dossier de destination
THUMBNAILS_DIR = 'thumbnails'

# Liste des films avec leurs URLs (utilisant des images libres de droits de Unsplash)
MOVIES = [
    {
        'id': '1',
        'title': 'Saloum',
        'url': 'https://images.unsplash.com/photo-1618519764620-7403abdbdfe9'
    },
    {
        'id': '2',
        'title': 'Timbuktu',
        'url': 'https://images.unsplash.com/photo-1516962080544-eac695c93791'
    },
    {
        'id': '3',
        'title': 'La Nuit des Rois',
        'url': 'https://images.unsplash.com/photo-1534809027769-b00d750a6bac'
    },
    {
        'id': '4',
        'title': 'Félicité',
        'url': 'https://images.unsplash.com/photo-1534447677768-be436bb09401'
    },
    {
        'id': '5',
        'title': 'Lingui',
        'url': 'https://images.unsplash.com/photo-1517230878791-4d28214057c2'
    },
    {
        'id': '6',
        'title': 'This Is Not a Burial',
        'url': 'https://images.unsplash.com/photo-1516195851888-6f1a981a862e'
    },
    {
        'id': '7',
        'title': 'Black Girl',
        'url': 'https://images.unsplash.com/photo-1519011985187-444d62641929'
    },
    {
        'id': '8',
        'title': 'Rafiki',
        'url': 'https://images.unsplash.com/photo-1589156280159-27698a70f29e'
    },
    {
        'id': '9',
        'title': 'The Gravedigger\'s Wife',
        'url': 'https://images.unsplash.com/photo-1517230878791-4d28214057c2'
    }
]

def download_and_optimize_image(movie):
    try:
        # Télécharger l'image
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        response = requests.get(movie['url'], headers=headers)
        response.raise_for_status()
        
        # Ouvrir l'image avec PIL
        img = Image.open(BytesIO(response.content))
        
        # Redimensionner l'image à 300x450 pixels
        img = img.resize((300, 450), Image.Resampling.LANCZOS)
        
        # Sauvegarder l'image optimisée
        output_path = os.path.join(THUMBNAILS_DIR, f"{movie['id']}.jpg")
        img.save(output_path, 'JPEG', quality=85, optimize=True)
        
        print(f"✓ {movie['title']} - Image téléchargée et optimisée")
        
    except Exception as e:
        print(f"✗ {movie['title']} - Erreur: {str(e)}")

def main():
    # Créer le dossier thumbnails s'il n'existe pas
    if not os.path.exists(THUMBNAILS_DIR):
        os.makedirs(THUMBNAILS_DIR)
    
    # Télécharger et optimiser toutes les images
    for movie in MOVIES:
        download_and_optimize_image(movie)

if __name__ == '__main__':
    main() 