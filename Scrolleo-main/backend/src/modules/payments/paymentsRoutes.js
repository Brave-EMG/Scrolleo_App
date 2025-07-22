import express from 'express';
import { 
    getPaymentHistory,
    getSubscriptionPlans,
    getSubscriptionStatus,
    getCoinPacks,
    getPaymentParams,
    handleWebhook,
    checkPaymentStatus
} from './paymentsController.js';
import authMiddleware from '../auth/authMiddleware.js';

const router = express.Router();

// Webhook pour Feexpay (non protégé car appelé par Feexpay)
router.post('/webhook', handleWebhook);

// Routes protégées par authentification
router.use(authMiddleware);

// Routes d'abonnement
router.get('/subscription/plans', getSubscriptionPlans);
router.get('/subscription/status', getSubscriptionStatus);

// Routes de coins
router.get('/coins/packs', getCoinPacks);

// Routes de paiement
router.post('/params', getPaymentParams);
router.post('/create', getPaymentParams); // Route de compatibilité
router.get('/history', getPaymentHistory);

// Vérifier l'état d'un paiement
router.get('/status/:paymentId', checkPaymentStatus);

export default router; 
