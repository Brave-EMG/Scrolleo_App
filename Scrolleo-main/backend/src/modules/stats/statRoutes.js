import express from 'express';
import authMiddleware from '../auth/authMiddleware.js';
import {
    getMovieStats,
    getDirectorStats,
    getPendingMoviesByDirector,
    getTopRatedMoviesByDirector,
    getRecentMoviesByDirector,
    getUpcomingMoviesByDirector,
    getDirectorRevenueStats
} from './statControllers.js';

const router = express.Router();

// Toutes les routes nécessitent d'être authentifié
router.use(authMiddleware);

// Routes des statistiques
router.get('/:director_id/MovieStats', getMovieStats);
router.get('/:director_id/DirectorStats', getDirectorStats);
router.get('/:director_id/PendingMoviesByDirector', getPendingMoviesByDirector);
router.get('/:director_id/TopRatedMoviesByDirector', getTopRatedMoviesByDirector);
router.get('/:director_id/RecentMoviesByDirector', getRecentMoviesByDirector);
router.get('/:director_id/upcoming-movies', getUpcomingMoviesByDirector);
router.get('/revenue', getDirectorRevenueStats);

export default router;
