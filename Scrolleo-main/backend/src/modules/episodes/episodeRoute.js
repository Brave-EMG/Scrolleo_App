import express from 'express';
import { EpisodeController } from './episodeControllers.js';
import authMiddleware from '../auth/authMiddleware.js';

const router = express.Router();
const episodeController = new EpisodeController();

// Middleware pour logger les requêtes
const logRequest = (req, res, next) => {
    console.log('=== Début de la requête Episode ===');
    console.log('Headers:', JSON.stringify(req.headers, null, 2));
    console.log('Body:', JSON.stringify(req.body, null, 2));
    console.log('=== Fin de la requête ===');
    next();
};

// Routes pour les épisodes
router.post(
    '/',
    // logRequest,
    // authMiddleware,
    episodeController.createEpisode
);

// router.post(
//     '/batch',
//     // logRequest,
//     // authMiddleware,
//     episodeController.createMultipleEpisodes
// );

// Routes spécifiques avant les routes génériques
router.get(
    '/first/:movieId/:userId',
    // authMiddleware,
    episodeController.getFirstEpisode
);

router.get(
    '/next/:movieId/:seasonNumber/:episodeNumber',
    // authMiddleware,
    episodeController.getNextEpisode
);

router.get(
    '/movie/:movieId',
    // authMiddleware,
    episodeController.getEpisodesByMovie
);

// Nouvelles routes pour la gestion des accès aux épisodes
router.get(
    '/:episodeId/access',
    authMiddleware,
    episodeController.checkEpisodeAccess
);

router.post(
    '/:episodeId/unlock',
    authMiddleware,
    episodeController.unlockEpisode
);

// Route pour configurer automatiquement les épisodes d'un film
router.post(
    '/movie/:movieId/configure',
    authMiddleware,
    episodeController.configureEpisodesForMovie
);

// Route générique pour l'ID à la fin
router.get(
    '/:id',
    // authMiddleware,
    episodeController.getEpisode
);

router.put(
    '/:id',
    // logRequest,
    // authMiddleware,
    episodeController.updateEpisode
);

router.delete(
    '/:id',
    // authMiddleware,
    episodeController.deleteEpisode
);

export default router;
