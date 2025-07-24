import express from 'express';
import { UploadController } from './uploadController.js';
import multer from 'multer';
import multerS3 from 'multer-s3';
import { S3Client } from '@aws-sdk/client-s3';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import authMiddleware from '../auth/authMiddleware.js';
import cors from 'cors';

// Configuration de dotenv
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const router = express.Router();
const uploadController = new UploadController();

// Configuration CORS spécifique pour les uploads
const uploadCorsOptions = {
  origin: ['http://localhost:3001', 'https://localhost:3001', 'https://scrolleo.brave-emg.com'],
  credentials: true,
  methods: ['POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Content-Length'],
  optionsSuccessStatus: 200
};

// Configuration AWS S3 avec SDK v3
const s3Client = new S3Client({
  region: process.env.AWS_REGION,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  }
});

// Configuration Multer avec S3 (multer-s3 est compatible avec S3Client v3)
const upload = multer({
  storage: multerS3({
    s3: s3Client,
    bucket: process.env.S3_BUCKET,
    // Suppression de l'ACL car le bucket ne les supporte pas
    key: function (req, file, cb) {
      // Utiliser une clé temporaire, l'organisation sera faite dans le contrôleur
      const fileExtension = path.extname(file.originalname);
      const timestamp = Date.now();
      const randomId = uuidv4().substring(0, 8);
      const fileName = `temp/${timestamp}-${randomId}${fileExtension}`;
      cb(null, fileName);
    },
    contentType: multerS3.AUTO_CONTENT_TYPE
  }),
  limits: {
    fileSize: 100 * 1024 * 1024, // 100MB limit
  }
});

// Middleware pour logger les requêtes
const logRequest = (req, res, next) => {
    console.log('=== Début de la requête Upload ===');
    console.log('Headers:', JSON.stringify(req.headers, null, 2));
    console.log('Body:', JSON.stringify(req.body, null, 2));
    console.log('Files:', req.files ? Object.keys(req.files).length : 'aucun');
    console.log('=== Fin de la requête ===');
    next();
};

// Middleware pour gérer les erreurs multer
const handleMulterError = (err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        console.error('Erreur Multer:', err);
        return res.status(400).json({
            error: 'Erreur lors de l\'upload',
            details: err.message
        });
    } else if (err) {
        console.error('Erreur non-Multer dans le middleware:', err);
        return res.status(500).json({
            error: 'Erreur pendant le traitement du fichier',
            details: err.message
        });
    }
    next();
};

// Le middleware d'authentification est maintenant importé depuis authMiddleware.js

// Route OPTIONS pour les requêtes preflight CORS
router.options('/', cors(uploadCorsOptions), (req, res) => {
    res.status(200).end();
});

// Route pour l'upload de fichiers pour un ou plusieurs épisodes
router.post(
    '/',
    cors(uploadCorsOptions),
    authMiddleware,
    // Utilisez upload.fields pour spécifier plusieurs types de fichiers
    upload.array('files'), // Utilisez le nom 'files' comme paramètre du champ de fichier
    handleMulterError,
    // (req, res, next) => {
    //     // Middleware de vérification des fichiers
    //     console.log("Middleware de vérification des fichiers");
    //     console.log("Files:", req.files);
    //     if (!req.files || req.files.length === 0) {
    //         console.warn("Aucun fichier détecté dans la requête");
    //     }
    //     next();
    // },
    logRequest, // Déplacé après upload pour voir les fichiers traités
    uploadController.uploadFiles
);

// Route spécifique pour les uploads par épisode (doit être avant les routes génériques)
router.get(
    '/episodes/:episodeId/uploads',
    authMiddleware,
    (req, res, next) => {
        console.log(`[DEBUG ROUTE] Route /episodes/:episodeId/uploads appelée`);
        console.log(`[DEBUG ROUTE] req.user:`, req.user);
        console.log(`[DEBUG ROUTE] req.params:`, req.params);
        next();
    },
    uploadController.getUploadsByEpisode
);

// Routes pour la gestion des uploads individuels
router.get(
    '/:id',
    authMiddleware,
    uploadController.getUpload
);

router.patch(
    '/:id/status',
    authMiddleware,
    uploadController.updateUploadStatus
);

router.delete(
    '/:id',
    authMiddleware,
    uploadController.deleteUpload
);

export default router;