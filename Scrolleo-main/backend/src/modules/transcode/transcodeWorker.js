import { TranscodeController } from './transcodeController.js';

// Exemple de worker qui pourrait écouter une queue ou être appelé en CLI
export async function processTranscodeTask(task) {
    // task = { videoUrl, outputDir }
    // Ici, on simule un appel direct à la méthode du contrôleur
    return await TranscodeController.transcodeToHLS({ body: task }, {
        status: (code) => ({ json: (obj) => console.log('Résultat:', code, obj) }),
        json: (obj) => console.log('Résultat:', obj)
    });
}

// Exemple d'utilisation directe
if (require.main === module) {
    // Lancer avec : node transcodeWorker.js /chemin/vers/video.mp4 /chemin/vers/sortie
    const [,, videoUrl, outputDir] = process.argv;
    if (!videoUrl) {
        console.error('Usage: node transcodeWorker.js <videoUrl> [outputDir]');
        process.exit(1);
    }
    processTranscodeTask({ videoUrl, outputDir });
} 