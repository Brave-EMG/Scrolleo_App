import express from 'express';
import authenticateToken from '../auth/authMiddleware.js';
import {
    getBalance,
    spendCoinsForEpisode,
    getTransactions
} from './coinsControllers.js';

const router = express.Router();

// Routes protégées par authentification
router.use(authenticateToken);

// Obtenir le solde de coins
router.get('/balance', getBalance);

// Dépenser des coins pour regarder un épisode
router.post('/spend/:episodeId', spendCoinsForEpisode);

// Obtenir l'historique des transactions
router.get('/transactions', getTransactions);

export default router; 