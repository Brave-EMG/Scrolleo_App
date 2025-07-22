import express from 'express';
import authMiddleware from '../auth/authMiddleware.js';
import {
    getUserStats,
    getRevenueStats,
    getContentStats,
    getEngagementStats,
    getDirectorStats
} from './statsAdminController.js';

const router = express.Router();

// Toutes les routes nécessitent d'être authentifié
router.use(authMiddleware);

// Routes des statistiques
router.get('/users', getUserStats);
router.get('/revenue', getRevenueStats);
router.get('/content', getContentStats);
router.get('/engagement', getEngagementStats);
router.get('/directors', getDirectorStats);

export default router; 