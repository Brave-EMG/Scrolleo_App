import { Upload } from './uploadModels.js';
import { Episode } from '../episodes/episodeModels.js';
import { S3Client, DeleteObjectCommand, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import ffmpeg from 'fluent-ffmpeg';
import { promisify } from 'util';
import { exec } from 'child_process';
import { v4 as uuidv4 } from 'uuid';
import path from 'path';
import os from 'os';
import fs from 'fs/promises';
import { TranscodeController } from '../transcode/transcodeController.js';
import pool from '../../config/database.js';

const execAsync = promisify(exec);

export class UploadController {
    constructor() {
        // Configuration AWS S3 avec SDK v3
        this.s3Client = new S3Client({
            region: process.env.AWS_REGION || 'eu-west-3',
            credentials: {
                accessKeyId: process.env.AWS_ACCESS_KEY_ID,
                secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
            }
        });

        // Nom du bucket S3
        this.s3Bucket = process.env.S3_BUCKET || 'myscrolleobucket';

        // Bind des méthodes
        this.uploadFiles = this.uploadFiles.bind(this);
        this.getUpload = this.getUpload.bind(this);
        this.updateUploadStatus = this.updateUploadStatus.bind(this);
        this.deleteUpload = this.deleteUpload.bind(this);
        this.getUploadsByEpisode = this.getUploadsByEpisode.bind(this);
    }
    
    // Détermine le type de fichier en fonction de son MIME type et de l'extension
    determineFileType(file) {
        const ext = file.originalname.split('.').pop().toLowerCase();
        if (file.mimetype.startsWith('video/') || ['mp4', 'webm', 'mov', 'mkv'].includes(ext)) {
            return 'video';
        } else if (file.mimetype.startsWith('image/') || ['jpg', 'jpeg', 'png'].includes(ext)) {
            // Distinguer les cover images des thumbnails basé sur le nom du fichier
            const filename = file.originalname.toLowerCase();
            if (filename.includes('cover') || filename.includes('poster') || filename.includes('banner')) {
                return 'coverimage';
            } else {
                return 'thumbnail';
            }
        } else if (
            file.mimetype.includes('text') ||
            ['srt', 'vtt', 'txt', 'ass'].includes(ext)
        ) {
            return 'subtitle';
        }
        return 'unknown';
    }

    // Crée un enregistrement d'upload dans la base de données
    async createUploadRecord(episodeId, file, type) {
        try {
            console.log(`Création de l'enregistrement d'upload pour ${type}:`, {
                episodeId,
                filename: file.key,
                originalName: file.originalname,
                mimeType: file.mimetype,
                size: file.size,
                location: file.location
            });

            // Créer l'objet Upload
            const upload = new Upload({
                episode_id: episodeId,
                filename: file.key,
                original_name: file.originalname, // Modifié pour correspondre au modèle
                mime_type: file.mimetype, // Modifié pour correspondre au modèle
                size: file.size,
                path: file.location, // URL S3 complète
                type: type,
                status: 'completed', // Statut "completed" car l'upload S3 est déjà terminé
                metadata: { 
                    s3Key: file.key,
                    s3Location: file.location,
                    etag: file.etag,
                    bucket: file.bucket
                }
            });

            // Enregistrer dans la base de données
            const savedUpload = await upload.save();
            console.log('Upload enregistré avec succès:', savedUpload);
            return savedUpload;
        } catch (error) {
            console.error(`Erreur lors de la création de l'enregistrement d'upload pour ${type}:`, error);
            throw error;
        }
    }

    // Vérifie l'existence des fichiers par type pour un épisode
    async checkExistingUploads(episodeId) {
        const existingUploads = {
            video: await Upload.findVideoByEpisode(episodeId),
            thumbnail: await Upload.findThumbnailByEpisode(episodeId),
            coverimage: await Upload.findCoverImageByEpisode(episodeId),
            subtitle: await Upload.findSubtitleByEpisode(episodeId)
        };

        return existingUploads;
    }

    // Supprime un fichier de S3
    async deleteFileFromS3(s3Key) {
        try {
            const command = new DeleteObjectCommand({
                Bucket: this.s3Bucket,
                Key: s3Key
            });
            await this.s3Client.send(command);
            console.log(`Fichier supprimé de S3: ${s3Key}`);
            return true;
        } catch (error) {
            // Gérer spécifiquement les erreurs de permissions
            if (error.Code === 'AccessDenied' || error.$metadata?.httpStatusCode === 403) {
                console.warn(`Permissions insuffisantes pour supprimer le fichier S3: ${s3Key}. Le fichier restera dans S3.`);
                // Ne pas faire échouer le processus pour une erreur de permissions
                return false;
            } else {
                console.error('Erreur lors de la suppression du fichier de S3:', error);
                return false;
            }
        }
    }

    async replaceExistingUpload(existingUpload, newFile, type) {
        try {
            console.log(`Remplacement du fichier ${type} existant (ID: ${existingUpload.upload_id}) par un nouveau fichier`);
            
            // 1. Supprimer l'ancien fichier de S3
            if (existingUpload.isS3File()) {
                await this.deleteFileFromS3(existingUpload.metadata.s3Key);
                console.log(`Ancien fichier supprimé de S3: ${existingUpload.metadata.s3Key}`);
            }
            
            // 2. Mettre à jour l'enregistrement dans la base de données
            existingUpload.filename = newFile.key;
            existingUpload.original_name = newFile.originalname;
            existingUpload.mime_type = newFile.mimetype;
            existingUpload.size = newFile.size;
            existingUpload.path = newFile.location;
            existingUpload.status = 'completed';
            existingUpload.metadata = {
                s3Key: newFile.key,
                s3Location: newFile.location,
                etag: newFile.etag,
                bucket: newFile.bucket
            };
            
            // 3. Sauvegarder les modifications
            const updatedUpload = await existingUpload.update();
            console.log(`Enregistrement d'upload mis à jour avec succès:`, updatedUpload);
            
            return updatedUpload;
        } catch (error) {
            console.error(`Erreur lors du remplacement du fichier ${type}:`, error);
            throw error;
        }
    }

    // Méthode pour vérifier si l'épisode existe
    async verifyEpisode(episodeId) {
        const episode = await Episode.findById(episodeId);
        return episode;
    }

    // Méthode pour générer une clé S3 organisée
    async generateOrganizedS3Key(file, episodeId, type) {
        try {
            // Récupérer les informations de l'épisode pour obtenir le réalisateur
            const episode = await Episode.findById(episodeId);
            if (!episode) {
                throw new Error(`Épisode ${episodeId} non trouvé`);
            }

            // Récupérer les informations du film pour obtenir le réalisateur
            const { rows: movieRows } = await pool.query(
                'SELECT m.*, d.name as director_name FROM movies m LEFT JOIN directors d ON m.director_id = d.director_id WHERE m.movie_id = $1',
                [episode.movie_id]
            );

            if (movieRows.length === 0) {
                throw new Error(`Film associé à l'épisode ${episodeId} non trouvé`);
            }

            const movie = movieRows[0];
            const directorName = movie.director_name || 'unknown_director';
            
            // Nettoyer le nom du réalisateur pour l'utiliser comme nom de dossier
            const cleanDirectorName = directorName
                .toLowerCase()
                .replace(/[^a-z0-9]/g, '_')
                .replace(/_+/g, '_')
                .replace(/^_|_$/g, '');

            // Générer un nom de fichier unique
            const timestamp = Date.now();
            const fileExtension = file.originalname.split('.').pop().toLowerCase();
            const cleanFileName = file.originalname
                .toLowerCase()
                .replace(/[^a-z0-9.]/g, '_')
                .replace(/_+/g, '_')
                .replace(/^_|_$/g, '');

            // Organiser par type de fichier
            let s3Key;
            switch (type) {
                case 'video':
                    s3Key = `videos/${cleanDirectorName}/${episodeId}_${cleanFileName}`;
                    break;
                case 'coverimage':
                    s3Key = `coverimages/${episodeId}_cover.${fileExtension}`;
                    break;
                case 'thumbnail':
                    s3Key = `thumbnails/${episodeId}_thumbnail.${fileExtension}`;
                    break;
                case 'subtitle':
                    s3Key = `subtitles/${episodeId}_subtitle.${fileExtension}`;
                    break;
                default:
                    s3Key = `misc/${episodeId}_${cleanFileName}`;
            }

            return s3Key;
        } catch (error) {
            console.error('Erreur lors de la génération de la clé S3:', error);
            // Fallback vers une clé simple si erreur
            const timestamp = Date.now();
            const fileExtension = file.originalname.split('.').pop().toLowerCase();
            return `${type}s/${episodeId}_${timestamp}.${fileExtension}`;
        }
    }

    // Méthode pour déplacer un fichier de l'emplacement temporaire vers l'emplacement organisé
    async moveFileToOrganizedLocation(file, newKey) {
        try {
            const { CopyObjectCommand, DeleteObjectCommand } = await import('@aws-sdk/client-s3');
            
            // Copier le fichier vers le nouvel emplacement
            const copyCommand = new CopyObjectCommand({
                Bucket: this.s3Bucket,
                CopySource: `${this.s3Bucket}/${file.key}`,
                Key: newKey,
                ContentType: file.mimetype
            });
            
            await this.s3Client.send(copyCommand);
            console.log(`Fichier copié de ${file.key} vers ${newKey}`);
            
            // Supprimer le fichier temporaire
            const deleteCommand = new DeleteObjectCommand({
                Bucket: this.s3Bucket,
                Key: file.key
            });
            
            await this.s3Client.send(deleteCommand);
            console.log(`Fichier temporaire supprimé: ${file.key}`);
            
            // Retourner un objet file mis à jour avec la nouvelle clé
            return {
                ...file,
                key: newKey,
                location: `https://${this.s3Bucket}.s3.amazonaws.com/${newKey}`
            };
        } catch (error) {
            console.error('Erreur lors du déplacement du fichier:', error);
            // En cas d'erreur, retourner le fichier original
            return file;
        }
    }

    // Nouvelle méthode pour générer une miniature
    async generateThumbnail(videoPath, outputPath) {
        return new Promise((resolve, reject) => {
            ffmpeg(videoPath)
                .screenshots({
                    count: 1,
                    folder: path.dirname(outputPath),
                    filename: path.basename(outputPath),
                    size: '320x240'
                })
                .on('end', () => resolve(outputPath))
                .on('error', (err) => reject(err));
        });
    }

    // Nouvelle méthode pour compresser une vidéo
    async compressVideo(inputPath, outputPath) {
        return new Promise((resolve, reject) => {
            ffmpeg(inputPath)
                .outputOptions([
                    '-c:v libx264',
                    '-crf 23',
                    '-preset medium',
                    '-c:a aac',
                    '-b:a 128k'
                ])
                .output(outputPath)
                .on('end', () => resolve(outputPath))
                .on('error', (err) => reject(err))
                .run();
        });
    }

    // Nouvelle méthode pour extraire les sous-titres
    async extractSubtitles(videoPath, outputPath) {
        try {
            // Utiliser ffmpeg pour extraire les sous-titres
            await execAsync(`ffmpeg -i "${videoPath}" -map 0:s:0 "${outputPath}"`);
            return outputPath;
        } catch (error) {
            console.error('Erreur lors de l\'extraction des sous-titres:', error);
            return null;
        }
    }

    // Méthode pour traiter un fichier vidéo
    async processVideoFile(file, episodeId) {
        const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'upload-'));
        const videoPath = path.join(tempDir, file.originalname);
        const thumbnailPath = path.join(tempDir, `${uuidv4()}.jpg`);
        const compressedPath = path.join(tempDir, `compressed-${file.originalname}`);
        const subtitlesPath = path.join(tempDir, `${uuidv4()}.srt`);

        try {
            // 1. Sauvegarder le fichier temporairement
            let videoBuffer = file.buffer;
            if (!videoBuffer) {
                if (file.path) {
                    videoBuffer = await fs.readFile(file.path);
                } else if (file.key && file.bucket) {
                    // Télécharger depuis S3 si nécessaire
                    const { S3Client, GetObjectCommand } = await import('@aws-sdk/client-s3');
                    const s3 = new S3Client({
                        region: process.env.AWS_REGION || 'eu-west-3',
                        credentials: {
                            accessKeyId: process.env.AWS_ACCESS_KEY_ID,
                            secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
                        }
                    });
                    const getObjectParams = {
                        Bucket: file.bucket,
                        Key: file.key
                    };
                    const data = await s3.send(new GetObjectCommand(getObjectParams));
                    videoBuffer = Buffer.from(await data.Body.transformToByteArray());
                } else {
                    throw new Error('Le buffer du fichier vidéo est manquant.');
                }
            }
            await fs.writeFile(videoPath, videoBuffer);

            // 2. Générer la miniature
            await this.generateThumbnail(videoPath, thumbnailPath);
            const thumbnailBuffer = await fs.readFile(thumbnailPath);
            const thumbnailKey = `thumbnails/${episodeId}/${path.basename(thumbnailPath)}`;
            await this.uploadToS3(thumbnailBuffer, thumbnailKey, 'image/jpeg');

            // 3. Compresser la vidéo
            await this.compressVideo(videoPath, compressedPath);
            const compressedBuffer = await fs.readFile(compressedPath);
            const compressedKey = `videos/${episodeId}/compressed-${file.originalname}`;
            await this.uploadToS3(compressedBuffer, compressedKey, file.mimetype);

            // 4. Extraire les sous-titres si présents
            const subtitlesExtracted = await this.extractSubtitles(videoPath, subtitlesPath);
            if (subtitlesExtracted) {
                const subtitlesBuffer = await fs.readFile(subtitlesPath);
                const subtitlesKey = `subtitles/${episodeId}/${path.basename(subtitlesPath)}`;
                await this.uploadToS3(subtitlesBuffer, subtitlesKey, 'application/x-subrip');
            }

            // 5. Nettoyer les fichiers temporaires
            await fs.rm(tempDir, { recursive: true, force: true });

            return {
                video: {
                    key: compressedKey,
                    originalname: file.originalname,
                    mimetype: file.mimetype,
                    size: compressedBuffer.length,
                    location: `https://${this.s3Bucket}.s3.amazonaws.com/${compressedKey}`
                },
                thumbnail: {
                    key: thumbnailKey,
                    originalname: path.basename(thumbnailPath),
                    mimetype: 'image/jpeg',
                    size: thumbnailBuffer.length,
                    location: `https://${this.s3Bucket}.s3.amazonaws.com/${thumbnailKey}`
                },
                subtitles: subtitlesExtracted ? {
                    key: subtitlesKey,
                    originalname: path.basename(subtitlesPath),
                    mimetype: 'application/x-subrip',
                    size: subtitlesBuffer.length,
                    location: `https://${this.s3Bucket}.s3.amazonaws.com/${subtitlesKey}`
                } : null
            };
        } catch (error) {
            // Nettoyer en cas d'erreur
            await fs.rm(tempDir, { recursive: true, force: true });
            throw error;
        }
    }

    // Méthode pour uploader un fichier vers S3
    async uploadToS3(buffer, key, contentType) {
        const command = new PutObjectCommand({
            Bucket: this.s3Bucket,
            Key: key,
            Body: buffer,
            ContentType: contentType
        });
        await this.s3Client.send(command);
        return `https://${this.s3Bucket}.s3.amazonaws.com/${key}`;
    }

    // Méthode pour traiter un fichier pour un épisode spécifique
    async processFileForEpisode(episodeId, file, existingUploads) {
        const type = this.determineFileType(file);
        const result = {
            episodeId: episodeId,
            fileKey: file.key,
            type: type,
            action: null,
            upload: null,
            error: null
        };
        
        if (type === 'unknown') {
            result.action = 'skip';
            result.error = `Type de fichier inconnu pour ${file.originalname}`;
            return result;
        }

        try {
            // Générer la clé S3 organisée
            const organizedKey = await this.generateOrganizedS3Key(file, episodeId, type);
            
            // Déplacer le fichier de l'emplacement temporaire vers l'emplacement organisé
            const movedFile = await this.moveFileToOrganizedLocation(file, organizedKey);
            
            if (type === 'video') {
                // Traitement spécial pour les vidéos
                const processedFiles = await this.processVideoFile(movedFile, episodeId);
                
                // Créer les enregistrements pour la vidéo, la miniature et les sous-titres
                const videoUpload = await this.createUploadRecord(episodeId, processedFiles.video, 'video');
                const thumbnailUpload = await this.createUploadRecord(episodeId, processedFiles.thumbnail, 'thumbnail');
                
                if (processedFiles.subtitles) {
                    await this.createUploadRecord(episodeId, processedFiles.subtitles, 'subtitle');
                }

                // Déclencher le transcodage automatiquement en tâche de fond
                (async () => {
                    try {
                        // Utiliser l'URL CloudFront au lieu de l'URL S3 directe
                        const cloudfrontUrl = processedFiles.video.location.replace(
                            `https://${this.s3Bucket}.s3.amazonaws.com`,
                            process.env.CLOUDFRONT_URL || 'https://d1xxxxxxxx.cloudfront.net'
                        );
                        
                        await TranscodeController.transcodeToHLS(   
                            { body: { 
                                videoUrl: cloudfrontUrl,
                                episodeId: episodeId 
                            } },
                            { status: () => ({ json: () => {} }), json: () => {} }
                        );
                        console.log('Transcodage lancé pour', cloudfrontUrl);
                    } catch (e) {
                        console.error('Erreur lors du déclenchement du transcodage:', e);
                    }
                })();

                result.action = 'create';
                result.upload = videoUpload;
            } else {
                // Traitement normal pour les autres types de fichiers
                if (existingUploads[type]) {
                    const updatedUpload = await this.replaceExistingUpload(existingUploads[type], movedFile, type);
                    result.action = 'replace';
                    result.upload = updatedUpload;
                } else {
                    const upload = await this.createUploadRecord(episodeId, movedFile, type);
                    result.action = 'create';
                    result.upload = upload;
                }
            }
        } catch (error) {
            result.action = 'skip';
            result.error = `Échec du traitement: ${error.message}`;
        }
        
        return result;
    }

    // Nouvelle version de uploadFiles qui prend en charge plusieurs épisodes
    async uploadFiles(req, res) {
        try {
            console.log('=== Début du traitement upload de fichiers pour plusieurs épisodes ===');
            console.log('Corps de la requête:', req.body);
            console.log('Liste des fichiers:', req.files);

            // Vérifier si des fichiers ont été uploadés
            if (!req.files || req.files.length === 0) {
                return res.status(400).json({ 
                    error: 'Aucun fichier n\'a été envoyé',
                    receivedFiles: req.files || 'aucun'
                });
            }

            // Récupérer les informations d'association fichier-épisode
            let filesMapping;
            try {
                // Vérifier si le mapping est fourni au format JSON
                filesMapping = req.body.files_mapping ? JSON.parse(req.body.files_mapping) : null;
            } catch (e) {
                console.error('Erreur de parsing du files_mapping:', e);
                filesMapping = null;
            }

            // Si pas de mapping, essayer l'ancienne méthode avec un seul episode_id
            if (!filesMapping) {
                const { episode_id } = req.body;
                if (!episode_id) {
                    return res.status(400).json({ error: 'Aucune information d\'épisode fournie. Utilisez soit episode_id soit files_mapping.' });
                }
                
                // Créer un mapping simple pour rester compatible avec l'ancienne API
                filesMapping = {};
                for (const file of req.files) {
                    // Utiliser originalname pour la cohérence avec le reste du code
                    filesMapping[file.originalname] = episode_id;
                }
            }

            // Résultats pour chaque épisode
            const results = {
                success: true,
                episodes: {},
                success_count: 0,
                error_count: 0,
                skipped_files: []
            };

            // Traiter chaque fichier selon le mapping
            for (const file of req.files) {
                // Correction : utiliser uniquement le nom original du fichier pour le mapping
                const episodeId = filesMapping[file.originalname];
                console.log('Traitement du fichier:', file.originalname, '| episodeId trouvé:', episodeId);
                console.log('Mapping disponible:', Object.keys(filesMapping));
                console.log('Fichier complet:', {
                    originalname: file.originalname,
                    key: file.key,
                    fieldname: file.fieldname,
                    mimetype: file.mimetype
                });
                
                if (!episodeId) {
                    console.warn(`Aucun épisode associé au fichier ${file.originalname}`);
                    console.warn('Mapping complet:', filesMapping);
                    results.skipped_files.push({
                        filename: file.originalname,
                        reason: 'Pas d\'association avec un épisode'
                    });
                    // Supprimer le fichier orphelin de S3
                    await this.deleteFileFromS3(file.key);
                    continue;
                }

                // Initialiser les résultats pour cet épisode s'ils n'existent pas encore
                if (!results.episodes[episodeId]) {
                    results.episodes[episodeId] = {
                        exists: false,
                        new_uploads: [],
                        replaced_uploads: [],
                        errors: []
                    };
                    // Vérifier si l'épisode existe
                    const episode = await this.verifyEpisode(episodeId);
                    if (!episode) {
                        results.episodes[episodeId].errors.push(`Épisode ${episodeId} non trouvé`);
                        // Supprimer le fichier de S3 car l'épisode n'existe pas
                        await this.deleteFileFromS3(file.key);
                        continue;
                    }
                    results.episodes[episodeId].exists = true;
                    results.episodes[episodeId].existing_uploads = await this.checkExistingUploads(episodeId);
                }

                // Si l'épisode existe, traiter le fichier
                if (results.episodes[episodeId].exists) {
                    const processResult = await this.processFileForEpisode(
                        episodeId,
                        file,
                        results.episodes[episodeId].existing_uploads
                    );
                    if (processResult.error) {
                        results.episodes[episodeId].errors.push(processResult.error);
                        results.error_count++;
                        // Supprimer le fichier de S3 en cas d'erreur
                        await this.deleteFileFromS3(file.key);
                    } else if (processResult.action === 'create') {
                        results.episodes[episodeId].new_uploads.push(processResult.upload);
                        results.success_count++;
                    } else if (processResult.action === 'replace') {
                        results.episodes[episodeId].replaced_uploads.push(processResult.upload);
                        results.success_count++;
                    }
                }
            }

            // Nettoyer les résultats pour la réponse API
            const cleanedResults = {
                success: results.success_count > 0,
                total_success: results.success_count,
                total_errors: results.error_count,
                episodes: {}
            };
            
            for (const episodeId in results.episodes) {
                const episodeResult = results.episodes[episodeId];
                cleanedResults.episodes[episodeId] = {
                    success: episodeResult.exists && (episodeResult.new_uploads.length > 0 || episodeResult.replaced_uploads.length > 0),
                    exists: episodeResult.exists,
                    new_uploads: episodeResult.new_uploads,
                    replaced_uploads: episodeResult.replaced_uploads,
                    errors: episodeResult.errors
                };
            }

            res.status(201).json(cleanedResults);
        } catch (error) {
            console.error('Erreur lors du traitement des uploads:', error);
            res.status(500).json({
                error: 'Erreur lors du traitement des uploads',
                details: error.message
            });
        }
    }

    // Récupère un upload par son ID
    async getUpload(req, res) {
        try {
            const { id } = req.params;
            const upload = await Upload.findById(id);
            
            if (!upload) {
                return res.status(404).json({ error: 'Upload non trouvé' });
            }
            
            res.json(upload);
        } catch (error) {
            console.error('Erreur lors de la récupération de l\'upload:', error);
            res.status(500).json({ 
                error: 'Erreur lors de la récupération de l\'upload',
                details: error.message
            });
        }
    }

    // Met à jour le statut d'un upload
    async updateUploadStatus(req, res) {
        try {
            const { id } = req.params;
            const { status } = req.body;
            
            if (!status) {
                return res.status(400).json({ error: 'Le statut est requis' });
            }
            
            const upload = await Upload.findById(id);
            if (!upload) {
                return res.status(404).json({ error: 'Upload non trouvé' });
            }
            
            const updatedUpload = await Upload.updateStatus(id, status);
            
            res.json({
                success: true,
                upload: updatedUpload
            });
        } catch (error) {
            console.error('Erreur lors de la mise à jour du statut:', error);
            res.status(500).json({ 
                error: 'Erreur lors de la mise à jour du statut',
                details: error.message
            });
        }
    }

    // Supprime un upload et son fichier associé sur S3
    async deleteUpload(req, res) {
        try {
            const { id } = req.params;
            
            // Récupérer l'upload à supprimer
            const upload = await Upload.findById(id);
            if (!upload) {
                return res.status(404).json({ error: 'Upload non trouvé' });
            }
            
            // Supprimer le fichier de S3 si des métadonnées sont disponibles
            if (upload.isS3File()) {
                await this.deleteFileFromS3(upload.metadata.s3Key);
            }
            
            // Supprimer l'enregistrement de la base de données
            await Upload.delete(id);

            res.json({ 
                success: true,
                message: 'Upload supprimé avec succès',
                upload_id: id
            });
        } catch (error) {
            console.error('Erreur lors de la suppression de l\'upload:', error);
            res.status(500).json({ 
                error: 'Erreur lors de la suppression de l\'upload',
                details: error.message
            });
        }
    }

    
    // Récupère tous les uploads associés à un épisode
    async getUploadsByEpisode(req, res) {
        try {
            const { episodeId } = req.params;
            const userEmail = req.user?.email;

            console.log(`[DEBUG] getUploadsByEpisode - episodeId: ${episodeId}, userEmail: ${userEmail}`);

            // Vérifier si l'épisode existe
            const episode = await Episode.findById(episodeId);
            console.log(`[DEBUG] Épisode trouvé:`, episode);
            
            if (!episode) {
                console.log(`[DEBUG] Épisode non trouvé`);
                return res.status(404).json({ error: 'Épisode non trouvé' });
            }

            // Vérifier l'accès à l'épisode
            const hasAccess = await this.checkEpisodeAccess(episodeId, userEmail);
            console.log(`[DEBUG] Résultat vérification accès: ${hasAccess}`);
            
            if (!hasAccess) {
                console.log(`[DEBUG] Accès refusé - episode_payant_non_debloque`);
                return res.status(403).json({ 
                    error: 'Accès refusé',
                    reason: 'episode_payant_non_debloque'
                });
            }

            // Récupérer les uploads existants
            const { rows: existingUploads } = await pool.query(
                'SELECT * FROM uploads WHERE episode_id = $1 AND path LIKE $2',
                [episodeId, 'public/hls/%']
            );
            // Récupérer tous les uploads pour cet épisode
            const uploads = await Upload.findByEpisode(episodeId);
            // Nettoyer les données pour l'affichage côté client (pas d'instance Upload, pas de méthodes)
            const cleanedUploads = uploads.map(upload => {
                const cleaned = {
                    upload_id: upload.upload_id,
                    episode_id: upload.episode_id,
                    filename: upload.filename,
                    original_name: upload.original_name,
                    mime_type: upload.mime_type,
                    size: upload.size,
                    path: upload.path,
                    type: upload.type,
                    status: upload.status,
                    metadata: upload.metadata,
                    created_at: upload.created_at,
                    updated_at: upload.updated_at
                };

                // Convertir les URLs S3 en URLs CloudFront
                if (cleaned.path && cleaned.path.includes('.s3.amazonaws.com')) {
                    cleaned.path = cleaned.path.replace(
                        `https://${process.env.S3_BUCKET}.s3.amazonaws.com`,
                        process.env.CLOUDFRONT_URL
                    );
                }
                if (cleaned.metadata && cleaned.metadata.s3Location) {
                    cleaned.metadata.s3Location = cleaned.metadata.s3Location.replace(
                        `https://${process.env.S3_BUCKET}.s3.amazonaws.com`,
                        process.env.CLOUDFRONT_URL
                    );
                }

                return cleaned;
            });
            res.json(cleanedUploads);
        } catch (error) {
            console.error('Erreur lors de la récupération des uploads par épisode:', error);
            res.status(500).json({ 
                error: 'Erreur lors de la récupération des uploads',
                details: error.message
            });
        }
    }

    // Méthode privée pour vérifier l'accès à un épisode
    async checkEpisodeAccess(episodeId, userEmail) {
        try {
            console.log(`[DEBUG] Vérification accès épisode ${episodeId} pour utilisateur ${userEmail}`);
            
            // Si l'épisode est gratuit, accès autorisé
            const episode = await Episode.findById(episodeId);
            console.log(`[DEBUG] Épisode trouvé:`, episode);
            
            if (episode.is_free) {
                console.log(`[DEBUG] Épisode gratuit - accès autorisé`);
                return true;
            }

            // Si pas d'utilisateur connecté, pas d'accès
            if (!userEmail) {
                console.log(`[DEBUG] Pas d'utilisateur connecté - accès refusé`);
                return false;
            }

            // Récupérer l'ID utilisateur et le rôle
            const { rows: userRows } = await pool.query(
                'SELECT user_id, role FROM users WHERE email = $1',
                [userEmail]
            );

            console.log(`[DEBUG] Résultat requête utilisateur:`, userRows);

            if (userRows.length === 0) {
                console.log(`[DEBUG] Utilisateur non trouvé - accès refusé`);
                return false;
            }

            const userId = userRows[0].user_id;
            const userRole = userRows[0].role;

            console.log(`[DEBUG] User ID: ${userId}, Role: ${userRole}`);

            // Si l'utilisateur est admin, accès autorisé
            if (userRole === 'admin') {
                console.log(`[DEBUG] Utilisateur admin - accès autorisé`);
                return true;
            }

            // Vérifier si l'utilisateur a un abonnement actif
            const subscriptionResult = await pool.query(
                `SELECT * FROM subscriptions 
                 WHERE user_id = $1 
                 AND status = 'active' 
                 AND end_date > CURRENT_TIMESTAMP`,
                [userId]
            );

            if (subscriptionResult.rows.length > 0) {
                console.log(`[DEBUG] Abonnement actif - accès autorisé`);
                return true;
            }

            // Vérifier si l'épisode est déjà débloqué
            const unlockedResult = await pool.query(
                'SELECT * FROM unlocked_episodes WHERE user_id = $1 AND episode_id = $2',
                [userId, episodeId]
            );

            console.log(`[DEBUG] Épisode débloqué: ${unlockedResult.rows.length > 0}`);

            return unlockedResult.rows.length > 0;

        } catch (error) {
            console.error('Erreur lors de la vérification d\'accès:', error);
            return false;
        }
    }
}