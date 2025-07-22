import path from 'path';
import fs from 'fs/promises';
import { spawn } from 'child_process';
import { S3Client, PutObjectCommand, ListObjectsV2Command, CopyObjectCommand } from '@aws-sdk/client-s3';
import { v4 as uuidv4 } from 'uuid';
import Bull from 'bull';
import { CloudFrontClient } from '@aws-sdk/client-cloudfront';

// Configuration de la file d'attente Bull
const transcodeQueue = new Bull('transcode-queue', {
    redis: {
        host: process.env.REDIS_HOST || 'localhost',
        port: process.env.REDIS_PORT || 6379
    }
});

// Configuration des clients AWS
const s3Client = new S3Client({
    region: process.env.AWS_REGION || 'eu-west-3',
    credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
    }
});

const cloudfrontClient = new CloudFrontClient({
    region: process.env.AWS_REGION || 'eu-west-3',
    credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
    }
});

// Fonction de notification (console, prêt pour email/websocket)
async function notifyTranscodeDone({ episodeId, s3BaseUrl, masterManifestUrl }) {
    // Ici, tu peux ajouter l'envoi d'email, WebSocket, etc.
    console.log(`✅ Transcodage terminé pour épisode ${episodeId || ''} ! Master manifest S3 : ${masterManifestUrl}`);
}

export class TranscodeController {
    // Upload récursif d'un dossier vers S3
    static async uploadFolderToS3(localDir, s3Prefix) {
        const s3 = new S3Client({
            region: process.env.AWS_REGION || 'eu-west-3',
            credentials: {
                accessKeyId: process.env.AWS_ACCESS_KEY_ID,
                secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
            }
        });
        const files = await fs.readdir(localDir);
        const uploaded = [];
        for (const file of files) {
            const filePath = path.join(localDir, file);
            const stat = await fs.stat(filePath);
            if (stat.isDirectory()) {
                // Appel récursif si sous-dossier
                const subUploaded = await this.uploadFolderToS3(filePath, s3Prefix + '/' + file);
                uploaded.push(...subUploaded);
            } else {
                const fileContent = await fs.readFile(filePath);
                const s3Key = s3Prefix + '/' + file;
                await s3.send(new PutObjectCommand({
                    Bucket: process.env.S3_BUCKET,
                    Key: s3Key,
                    Body: fileContent,
                    ContentType: file.endsWith('.m3u8') ? 'application/vnd.apple.mpegurl' : 'video/MP2T'
                }));
                uploaded.push({ s3Key });
            }
        }
        return uploaded;
    }

    // Lance le transcodage d'une vidéo en plusieurs qualités HLS
    static async transcodeToHLS(req, res) {
        try {
            const { videoUrl, outputDir, episodeId } = req.body;
            if (!videoUrl) {
                return res.status(400).json({ error: 'Lien de la vidéo requis' });
            }

            // Ajouter la tâche à la file d'attente
            const job = await transcodeQueue.add('transcode', {
                videoUrl,
                outputDir,
                episodeId,
                attempts: 0
            }, {
                attempts: 3, // Nombre maximum de tentatives
                backoff: {
                    type: 'exponential',
                    delay: 5000 // Délai initial de 5 secondes
                }
            });

            res.json({ 
                message: 'Transcodage ajouté à la file d\'attente',
                jobId: job.id
            });
        } catch (error) {
            console.error('Erreur lors de l\'ajout à la file d\'attente:', error);
            res.status(500).json({ error: 'Erreur lors de l\'ajout à la file d\'attente' });
        }
    }

    // Traitement du transcodage
    static async processTranscode(job) {
        const { videoUrl, outputDir, episodeId, attempts } = job.data;
        const tempDir = path.join('/tmp', `transcode_${uuidv4()}`);
        
        try {
            await fs.mkdir(tempDir, { recursive: true });
            console.log('Début du transcodage avec les paramètres:', {
                videoUrl,
                outputDir,
                episodeId,
                attempts
            });

            // Vérifier si FFmpeg est installé
            try {
                await new Promise((resolve, reject) => {
                    const ffmpegCheck = spawn('ffmpeg', ['-version']);
                    ffmpegCheck.on('close', code => code === 0 ? resolve() : reject(new Error('FFmpeg n\'est pas installé')));
                });
            } catch (error) {
                throw new Error('FFmpeg n\'est pas installé ou n\'est pas accessible');
            }

            // Dossier de sortie par défaut
            const outDir = outputDir || path.join('/tmp', 'hls_' + Date.now());
            await fs.mkdir(outDir, { recursive: true });

            // Résolutions à générer
            const renditions = [
                { name: '240p', width: 426, height: 240, bitrate: '400k', audioBitrate: '64k' },
                { name: '480p', width: 854, height: 480, bitrate: '800k', audioBitrate: '96k' },
                { name: '720p', width: 1280, height: 720, bitrate: '2000k', audioBitrate: '128k' }
            ];

            // Commandes FFmpeg pour chaque qualité avec support des sous-titres
            const ffmpegCmds = renditions.map(rendition => [
                '-i', videoUrl,
                '-vf', `scale=w=${rendition.width}:h=${rendition.height}:force_original_aspect_ratio=decrease,format=yuv420p`,
                '-c:a', 'aac',
                '-b:a', rendition.audioBitrate,
                '-ar', '48000',
                '-c:v', 'libx264',
                '-profile:v', 'main',
                '-level', '3.0',
                '-preset', 'medium',
                '-crf', '23',
                '-sc_threshold', '0',
                '-g', '48',
                '-keyint_min', '48',
                '-b:v', rendition.bitrate,
                '-maxrate', rendition.bitrate,
                '-bufsize', rendition.bitrate,
                '-hls_time', '4',
                '-hls_playlist_type', 'vod',
                '-hls_segment_filename', path.join(outDir, `${rendition.name}_%03d.ts`),
                // Support des sous-titres
                '-map', '0:v',
                '-map', '0:a',
                '-map', '0:s?', // Sous-titres optionnels
                path.join(outDir, `${rendition.name}.m3u8`)
            ]);

            // Lancer les transcodages en série
            for (const cmd of ffmpegCmds) {
                await new Promise((resolve, reject) => {
                    console.log('Lancement de la commande FFmpeg:', cmd.join(' '));
                    const ffmpeg = spawn('ffmpeg', cmd);
                    
                    let errorOutput = '';
                    let normalOutput = '';

                    ffmpeg.stdout.on('data', data => {
                        const output = data.toString();
                        normalOutput += output;
                        console.log('FFmpeg stdout:', output);
                    });

                    ffmpeg.stderr.on('data', data => {
                        const output = data.toString();
                        errorOutput += output;
                        console.log('FFmpeg stderr:', output);
                    });

                    ffmpeg.on('close', code => {
                        if (code === 0) {
                            console.log('FFmpeg command completed successfully');
                            resolve();
                        } else {
                            console.error('FFmpeg failed with code:', code);
                            console.error('FFmpeg error output:', errorOutput);
                            reject(new Error(`FFmpeg failed with code ${code}: ${errorOutput}`));
                        }
                    });

                    ffmpeg.on('error', err => {
                        console.error('FFmpeg process error:', err);
                        reject(err);
                    });
                });
            }

            // Vérifier si les fichiers ont été créés
            const files = await fs.readdir(outDir);
            if (files.length === 0) {
                throw new Error('Aucun fichier n\'a été généré par FFmpeg');
            }

            // Upload des fichiers vers S3
            for (const file of files) {
                const filePath = path.join(outDir, file);
                const fileContent = await fs.readFile(filePath);
                const s3Key = `hls/${episodeId}/${file}`;

                await s3Client.send(new PutObjectCommand({
                    Bucket: process.env.AWS_BUCKET_NAME,
                    Key: s3Key,
                    Body: fileContent,
                    ContentType: file.endsWith('.m3u8') ? 'application/vnd.apple.mpegurl' : 'video/MP2T'
                }));
            }

            // Nettoyer les fichiers temporaires
            await fs.rm(tempDir, { recursive: true, force: true });
            await fs.rm(outDir, { recursive: true, force: true });

            return { success: true, message: 'Transcodage terminé avec succès' };
        } catch (error) {
            console.error('Erreur lors du transcodage:', error);
            
            // Si c'est la dernière tentative, on nettoie
            if (attempts >= 2) {
                try {
                    await fs.rm(tempDir, { recursive: true, force: true });
                    await fs.rm(outDir, { recursive: true, force: true });
                } catch (cleanupError) {
                    console.error('Erreur lors du nettoyage:', cleanupError);
                }
            }
            
            throw error;
        }
    }

    // Vérifier le statut d'un transcodage
    static async getTranscodeStatus(req, res) {
        try {
            const { jobId } = req.params;
            const job = await transcodeQueue.getJob(jobId);
            
            if (!job) {
                return res.status(404).json({ error: 'Tâche non trouvée' });
            }

            const state = await job.getState();
            const progress = job._progress;
            const result = job.returnvalue;
            const error = job.failedReason;

            res.json({
                jobId,
                state,
                progress,
                result,
                error
            });
        } catch (error) {
            console.error('Erreur lors de la récupération du statut:', error);
            res.status(500).json({ error: 'Erreur lors de la récupération du statut' });
        }
    }

    // Méthode pour mettre à jour les métadonnées des fichiers HLS existants (sans ACL)
    static async updateHLSFilesMetadata() {
        try {
            const s3Client = new S3Client({
                region: process.env.AWS_REGION || 'eu-west-3',
                credentials: {
                    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
                    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
                }
            });

            const bucketName = process.env.S3_BUCKET;
            if (!bucketName) {
                throw new Error('S3_BUCKET environment variable is not set');
            }

            // Lister tous les fichiers dans le dossier public/hls
            const listCommand = new ListObjectsV2Command({
                Bucket: bucketName,
                Prefix: 'public/hls/'
            });

            const listedObjects = await s3Client.send(listCommand);
            if (!listedObjects.Contents) {
                console.log('Aucun fichier HLS trouvé');
                return;
            }

            console.log(`Mise à jour des métadonnées pour ${listedObjects.Contents.length} fichiers...`);

            // Pour chaque fichier, copier sur lui-même avec les nouvelles métadonnées (sans ACL)
            for (const object of listedObjects.Contents) {
                const copyCommand = new CopyObjectCommand({
                    Bucket: bucketName,
                    Key: object.Key,
                    CopySource: `${bucketName}/${object.Key}`,
                    MetadataDirective: 'REPLACE',
                    ContentType: object.Key.endsWith('.m3u8') ? 'application/vnd.apple.mpegurl' : 'video/MP2T',
                    CacheControl: 'max-age=31536000',
                    Metadata: {
                        'x-amz-meta-public': 'true'
                    }
                });

                await s3Client.send(copyCommand);
                console.log(`✅ Métadonnées mises à jour pour ${object.Key}`);
            }

            console.log('✅ Mise à jour des métadonnées terminée !');
        } catch (error) {
            console.error('Erreur lors de la mise à jour des métadonnées:', error);
            throw error;
        }
    }
}

// Configuration des gestionnaires de la file d'attente
transcodeQueue.process('transcode', async (job) => {
    return await TranscodeController.processTranscode(job);
});

// Gestion des erreurs de la file d'attente
transcodeQueue.on('failed', (job, error) => {
    console.error(`Tâche ${job.id} échouée:`, error);
});

transcodeQueue.on('completed', (job, result) => {
    console.log(`Tâche ${job.id} terminée avec succès:`, result);
}); 