import { v4 as uuidv4 } from 'uuid';
import  pool  from '../../config/database.js';

// Fonction pour obtenir l'ID utilisateur à partir de l'email
const getUserIdFromEmail = async (email) => {
    const result = await pool.query('SELECT user_id FROM users WHERE email = $1', [email]);
    if (result.rows.length === 0) {
        throw new Error('Utilisateur non trouvé');
    }
    return result.rows[0].user_id;
};

// Obtenir le solde de coins d'un utilisateur
export const getBalance = async (req, res) => {
    console.log('=== DÉBUT getBalance ===');
    console.log('👤 User object:', req.user);
    console.log('📧 User email:', req.user?.email);
    
    try {
        const userEmail = req.user.email;
        console.log('Getting balance for user email:', userEmail);

        if (!userEmail) {
            console.log('❌ Pas d\'utilisateur authentifié');
            return res.status(401).json({ error: 'Utilisateur non authentifié' });
        }

        // Obtenir l'ID utilisateur à partir de l'email
        const userId = await getUserIdFromEmail(userEmail);
        console.log('User ID:', userId);

        // Obtenir le solde
        console.log('🔍 Recherche solde pour user_id:', userId);
        const result = await pool.query(
            'SELECT balance FROM coins WHERE user_id = $1',
            [userId]
        );
        
        console.log('💰 Résultat requête solde:', result.rows);
        
        if (result.rows.length === 0) {
            console.log('💳 Création nouveau compte coins pour user:', userId);
            // Si l'utilisateur n'a pas de compte coins, en créer un
            await pool.query(
                'INSERT INTO coins (user_id, balance) VALUES ($1, 0)',
                [userId]
            );
            console.log('✅ Compte coins créé avec solde 0');
            console.log('=== FIN getBalance ===');
            return res.json({ balance: 0 });
        }
        
        const balance = result.rows[0].balance;
        console.log('✅ Solde trouvé:', balance);
        console.log('=== FIN getBalance ===');
        res.json({ balance: balance });
    } catch (error) {
        console.error('💥 Error getting balance:', error);
        console.log('=== FIN getBalance (ERREUR) ===');
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Ajouter des coins (pour les achats)
export const addCoins = async (req, res) => {
    try {
        const { amount, paymentMethod, paymentDetails } = req.body;
        const userId = req.user.id;

        // Vérifier le paiement (à implémenter selon la méthode de paiement)
        const paymentVerified = await verifyPayment(paymentMethod, paymentDetails);
        
        if (!paymentVerified) {
            return res.status(400).json({ error: 'Payment verification failed' });
        }

        // Ajouter les coins
        await pool.query(
            'INSERT INTO coin_transactions (user_id, amount, reason) VALUES ($1, $2, $3)',
            [userId, amount, 'Purchase']
        );

        // Mettre à jour le solde
        await pool.query(
            'UPDATE coins SET balance = balance + $1 WHERE user_id = $2',
            [amount, userId]
        );

        res.json({ message: 'Coins added successfully' });
    } catch (error) {
        console.error('Error adding coins:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Dépenser des coins pour regarder un épisode
export const spendCoinsForEpisode = async (req, res) => {
    try {
        const { episodeId } = req.params;
        const userId = req.user.id;
        const userEmail = req.user.email;
        const COIN_COST = 1; // 1 coin = 0.6 FCFA

        // Vérifier le rôle de l'utilisateur
        const userResult = await pool.query(
            'SELECT role FROM users WHERE user_id = $1',
            [userId]
        );

        if (userResult.rows.length === 0) {
            return res.status(404).json({ error: 'Utilisateur non trouvé' });
        }

        const userRole = userResult.rows[0].role;

        // Si l'utilisateur est admin, accès autorisé sans dépenser de coins
        if (userRole === 'admin') {
            // Vérifier si l'épisode est déjà débloqué
            const unlockedResult = await pool.query(
                'SELECT * FROM unlocked_episodes WHERE user_id = $1 AND episode_id = $2',
                [userId, episodeId]
            );

            if (unlockedResult.rows.length === 0) {
                // Débloquer l'épisode pour l'admin
                await pool.query(
                    'INSERT INTO unlocked_episodes (user_id, episode_id) VALUES ($1, $2)',
                    [userId, episodeId]
                );
            }

            return res.json({ 
                message: 'Episode accessible (accès admin)',
                cost: 0,
                remainingBalance: null
            });
        }

        // Vérifier si l'utilisateur a un abonnement actif
        const subscriptionResult = await pool.query(
            `SELECT * FROM subscriptions 
             WHERE user_id = $1 
             AND status = 'active' 
             AND end_date > CURRENT_TIMESTAMP`,
            [userId]
        );

        // Si l'utilisateur a un abonnement actif, pas besoin de dépenser de coins
        if (subscriptionResult.rows.length > 0) {
            return res.json({ 
                message: 'Episode accessible avec abonnement',
                cost: 0,
                remainingBalance: null
            });
        }

        // Vérifier le solde
        const balanceResult = await pool.query(
            'SELECT balance FROM coins WHERE user_id = $1',
            [userId]
        );

        if (balanceResult.rows.length === 0 || balanceResult.rows[0].balance < COIN_COST) {
            return res.status(400).json({ 
                error: 'Solde insuffisant',
                required: COIN_COST,
                current: balanceResult.rows[0]?.balance || 0
            });
        }

        // Vérifier si l'épisode existe
        const episodeResult = await pool.query(
            'SELECT * FROM episodes WHERE episode_id = $1',
            [episodeId]
        );

        if (episodeResult.rows.length === 0) {
            return res.status(404).json({ error: 'Épisode non trouvé' });
        }

        // Vérifier si l'épisode est déjà débloqué
        const unlockedResult = await pool.query(
            'SELECT * FROM unlocked_episodes WHERE user_id = $1 AND episode_id = $2',
            [userId, episodeId]
        );

        if (unlockedResult.rows.length > 0) {
            return res.json({ 
                message: 'Épisode déjà débloqué',
                cost: 0,
                remainingBalance: balanceResult.rows[0].balance
            });
        }

        // Démarrer une transaction
        const client = await pool.connect();
        try {
            await client.query('BEGIN');

        // Enregistrer la transaction
            await client.query(
                'INSERT INTO coin_transactions (user_id, amount, reason, episode_id) VALUES ($1, $2, $3, $4)',
                [userId, -COIN_COST, 'Regard d\'épisode', episodeId]
        );

        // Mettre à jour le solde
            await client.query(
            'UPDATE coins SET balance = balance - $1 WHERE user_id = $2',
                [COIN_COST, userId]
            );

            // Débloquer l'épisode
            await client.query(
                'INSERT INTO unlocked_episodes (user_id, episode_id) VALUES ($1, $2)',
                [userId, episodeId]
        );

            await client.query('COMMIT');

            // Récupérer le nouveau solde
            const newBalanceResult = await client.query(
                'SELECT balance FROM coins WHERE user_id = $1',
                [userId]
            );

            res.json({ 
                message: 'Épisode débloqué avec succès',
                cost: COIN_COST,
                remainingBalance: newBalanceResult.rows[0].balance
            });
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    } catch (error) {
        console.error('Error spending coins:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Obtenir l'historique des transactions
export const getTransactions = async (req, res) => {
    try {
        const userId = req.user.id;
        const result = await pool.query(
            `SELECT ct.*, e.title as episode_title 
             FROM coin_transactions ct 
             LEFT JOIN episodes e ON ct.episode_id = e.episode_id 
             WHERE ct.user_id = $1 
             ORDER BY ct.created_at DESC`,
            [userId]
        );
        
        res.json(result.rows);
    } catch (error) {
        console.error('Error getting transactions:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Réclamer la récompense quotidienne
export const claimDailyReward = async (req, res) => {
    try {
        const userId = req.user.id;
        const today = new Date().toISOString().split('T')[0];

        // Vérifier si la récompense a déjà été réclamée aujourd'hui
        const existingReward = await pool.query(
            'SELECT * FROM daily_rewards WHERE user_id = $1 AND reward_date = $2',
            [userId, today]
        );

        if (existingReward.rows.length > 0) {
            return res.status(400).json({ error: 'Daily reward already claimed' });
        }

        // Ajouter la récompense
        await pool.query(
            'INSERT INTO daily_rewards (user_id, reward_date, coins_earned) VALUES ($1, $2, $3)',
            [userId, today, 10]
        );

        // Mettre à jour le solde
        await pool.query(
            'UPDATE coins SET balance = balance + 10 WHERE user_id = $1',
            [userId]
        );

        res.json({ message: 'Daily reward claimed successfully' });
    } catch (error) {
        console.error('Error claiming daily reward:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Acheter un abonnement
export const purchaseSubscription = async (req, res) => {
    try {
        const { subscriptionType, paymentMethod, paymentDetails } = req.body;
        const userId = req.user.id;

        // Vérifier le paiement
        const paymentVerified = await verifyPayment(paymentMethod, paymentDetails);
        
        if (!paymentVerified) {
            return res.status(400).json({ error: 'Payment verification failed' });
        }

        // Calculer la date d'expiration
        const startDate = new Date();
        const endDate = new Date();
        endDate.setDate(endDate.getDate() + 7); // Abonnement hebdomadaire

        // Enregistrer l'abonnement
        await pool.query(
            'INSERT INTO subscriptions (user_id, start_date, end_date, platform, price) VALUES ($1, $2, $3, $4, $5)',
            [userId, startDate, endDate, paymentMethod, 20.00]
        );

        // Mettre à jour le type d'abonnement de l'utilisateur
        await pool.query(
            'UPDATE users SET subscription_type = $1, subscription_expiry = $2 WHERE id = $3',
            [subscriptionType, endDate, userId]
        );

        res.json({ message: 'Subscription purchased successfully' });
    } catch (error) {
        console.error('Error purchasing subscription:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Fonction utilitaire pour vérifier les paiements
async function verifyPayment(paymentMethod, paymentDetails) {
    // Implémenter la logique de vérification selon la méthode de paiement
    // Pour l'instant, on retourne true pour la démo
    return true;
}