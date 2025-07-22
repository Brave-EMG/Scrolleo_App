import pool from '../../config/database.js';
import axios from 'axios';
import nodemailer from 'nodemailer';

// Configuration de Feexpay
const FEEXPAY_API_KEY = process.env.FEEXPAY_API_KEY;
const FEEXPAY_SHOP_ID = process.env.FEEXPAY_SHOP_ID;
const FEEXPAY_API_URL = 'https://api.feexpay.me'; // Retiré /v1
const FEEXPAY_SANDBOX_URL = 'https://api.feexpay.me/v1'; // URL de sandbox

// Configuration d'Axios pour Feexpay
const feexpayAxios = axios.create({
    baseURL: FEEXPAY_API_URL,
    timeout: 30000,
    headers: {
        'Authorization': `Bearer ${FEEXPAY_API_KEY}`,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
});

// Vérifier la configuration de Feexpay
if (!FEEXPAY_API_KEY) {
    console.error('FEEXPAY_API_KEY n\'est pas définie dans les variables d\'environnement');
}

// Configuration de l'email
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: process.env.SMTP_PORT,
  secure: process.env.SMTP_SECURE === 'true',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS
  }
});

// Plans d'abonnement disponibles
const SUBSCRIPTION_PLANS = [
    {
        id: 'monthly',
        name: 'Abonnement Mensuel',
        price: 5000, // 5000 FCFA
        duration: 30, // 30 jours
        features: ['Accès illimité aux épisodes', 'Pas de publicités']
    },
    {
        id: 'yearly',
        name: 'Abonnement Annuel',
        price: 50000, // 50000 FCFA
        duration: 365, // 365 jours
        features: ['Accès illimité aux épisodes', 'Pas de publicités']
    }
];

// Packs de coins disponibles
const COIN_PACKS = [
    {
        id: 'small',
        name: 'Petit Pack',
        price: 2,//250, //250 FCFA
        coins: 400, //400 coins
        description: 'Environ 400 coins'
    },
    {
        id: 'medium',
        name: 'Pack Moyen',
        price: 500, //500 FCFA
        coins: 800, //800 coins
        description: 'Environ 800 coins'
    },
    {
        id: 'large',
        name: 'Grand Pack',
        price: 1000, //1000 FCFA
        coins: 1600, //1600 coins
        description: 'Environ 1600 coins'
    }
];

// Fonction pour obtenir l'email de l'utilisateur
const getUserEmail = async (userId) => {
    const result = await pool.query('SELECT email FROM users WHERE user_id = $1', [userId]);
  if (result.rows.length === 0) {
    throw new Error('Utilisateur non trouvé');
  }
  return result.rows[0].email;
};

// Fonction pour envoyer un email
const sendEmail = async (mailOptions) => {
  return transporter.sendMail({
    from: process.env.SMTP_FROM,
    ...mailOptions
  });
};

// Fonction utilitaire pour générer le texte de la facture
const generateInvoiceText = ({ userEmail, amount, transactionId, type, date, coinsAdded }) => {
    return `
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { text-align: center; margin-bottom: 30px; }
            .details { margin: 20px 0; }
            .footer { margin-top: 30px; font-size: 12px; color: #666; }
            .amount { font-size: 24px; color: #2ecc71; font-weight: bold; }
            .transaction-id { color: #666; font-size: 14px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Facture de Paiement</h1>
            </div>
            <div class="details">
                <p>Bonjour,</p>
                <p>Merci pour votre paiement. Voici les détails de votre transaction :</p>
                <ul>
                    <li><strong>Montant :</strong> <span class="amount">${amount} XOF</span></li>
                    <li><strong>Date :</strong> ${date}</li>
                    <li><strong>Type :</strong> ${type === 'subscription' ? 'Abonnement' : 'Achat de coins'}</li>
                    ${coinsAdded ? `<li><strong>Coins crédités :</strong> ${coinsAdded}</li>` : ''}
                </ul>
                <p class="transaction-id">Numéro de transaction : ${transactionId}</p>
            </div>
            <div class="footer">
                <p>Ceci fait office de reçu/facture officiel.</p>
                <p>Pour toute question concernant votre paiement, n'hésitez pas à contacter notre service client.</p>
                <p>Cordialement,<br>L'équipe support</p>
            </div>
        </div>
    </body>
    </html>
    `;
};

// Fonction pour obtenir l'ID de l'utilisateur à partir de son email
const getUserIdFromEmail = async (email) => {
    const result = await pool.query('SELECT user_id FROM users WHERE email = $1', [email]);
    if (result.rows.length === 0) {
        throw new Error('Utilisateur non trouvé');
    }
    return result.rows[0].user_id;
};

// Obtenir les plans d'abonnement disponibles
export const getSubscriptionPlans = async (req, res) => {
    try {
        res.json(SUBSCRIPTION_PLANS);
    } catch (error) {
        console.error('Error getting subscription plans:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Obtenir les packs de coins disponibles
export const getCoinPacks = async (req, res) => {
    try {
        res.json(COIN_PACKS);
    } catch (error) {
        console.error('Error getting coin packs:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Fonction pour obtenir les paramètres de paiement
export const getPaymentParams = async (req, res) => {
    try {
        const { type, planId } = req.body;
        const userEmail = req.user.email;
        
        console.log('=== DÉBUT getPaymentParams ===');
        console.log('Type de paiement:', type);
        console.log('Plan ID:', planId);
        console.log('Email utilisateur:', userEmail);
        
        // Récupérer l'ID de l'utilisateur à partir de son email
        const userId = await getUserIdFromEmail(userEmail);
        console.log('Extracted userId:', userId);

        if (!userId) {
            console.log('❌ Utilisateur non authentifié');
            return res.status(401).json({ error: 'Utilisateur non authentifié' });
        }

        let amount, description, coinsAdded;
        let paymentType = type;

        if (type === 'subscription') {
            const plan = SUBSCRIPTION_PLANS.find(p => p.id === planId);
            if (!plan) {
                console.log('❌ Plan d\'abonnement invalide:', planId);
                return res.status(400).json({ error: 'Plan d\'abonnement invalide' });
            }
            amount = plan.price;
            description = `Abonnement ${plan.name} - ${plan.duration} jours`;
            coinsAdded = 0;
            console.log('✅ Plan d\'abonnement trouvé:', plan);
        } else if (type === 'coins') {
            const pack = COIN_PACKS.find(p => p.id === planId);
            if (!pack) {
                console.log('❌ Pack de coins invalide:', planId);
                return res.status(400).json({ error: 'Pack de coins invalide' });
            }
            amount = pack.price;
            description = `Achat de ${pack.coins} coins`;
            paymentType = 'coins';
            coinsAdded = pack.coins;
            console.log('✅ Pack de coins trouvé:', pack);
        } else {
            console.log('❌ Type de paiement invalide:', type);
            return res.status(400).json({ error: 'Type de paiement invalide' });
        }

        console.log('💰 Montant:', amount);
        console.log('📝 Description:', description);
        console.log('🪙 Coins ajoutés:', coinsAdded);
        console.log('🏷️ Type de paiement:', paymentType);

        // Créer l'enregistrement de paiement
        const paymentResult = await pool.query(
            `INSERT INTO payments (user_id, amount, type, status, provider, coins_added)
             VALUES ($1, $2, $3, 'pending', 'feexpay', $4)
             RETURNING id`,
            [userId, amount, paymentType, coinsAdded]
        );

        const paymentId = paymentResult.rows[0].id;
        console.log('💾 Paiement créé avec ID:', paymentId);

        // Construire l'URL de callback
        const baseUrl = process.env.API_URL || 'http://localhost:3000';
        const callbackUrl = `${baseUrl.replace(/\/$/, '')}/payments/webhook`;
        console.log('🔗 URL de callback:', callbackUrl);

        // Préparer les paramètres Feexpay
        const feexpayParams = {
            token: FEEXPAY_API_KEY,
            id: FEEXPAY_SHOP_ID,
            amount: amount.toString(),
            description: description,
            callback_url: callbackUrl,
            callback_info: {
                payment_id: paymentId,
                type: paymentType,
                plan_id: planId
            }
        };

        console.log('📤 Paramètres envoyés à Feexpay:', JSON.stringify(feexpayParams, null, 2));

        // Retourner les paramètres pour le composant Feexpay
        const response = {
            paymentId,
            amount,
            description,
            coinsAdded,
            feexpayParams
        };

        console.log('📤 Réponse envoyée au frontend:', JSON.stringify(response, null, 2));
        console.log('=== FIN getPaymentParams ===');

        res.json(response);
    } catch (error) {
        console.error('Error getting payment params:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Gérer un paiement réussi
async function handleSuccessfulPayment(paymentId, type, planId, userId) {
    try {
        // Démarrer une transaction
        await pool.query('BEGIN');

        // Mettre à jour le statut du paiement
        await pool.query(
            'UPDATE payments SET status = $1 WHERE id = $2',
            ['success', paymentId]
        );

        if (type === 'subscription') {
            const plan = SUBSCRIPTION_PLANS.find(p => p.id === planId);
            const endDate = new Date();
            endDate.setDate(endDate.getDate() + plan.duration);

            // Créer l'abonnement
            await pool.query(
                `INSERT INTO subscriptions (user_id, payment_id, start_date, end_date, status)
                 VALUES ($1, $2, CURRENT_TIMESTAMP, $3, 'active')`,
                [userId, paymentId, endDate]
            );
        } else if (type === 'coins') {
            const pack = COIN_PACKS.find(p => p.id === planId);

            // Ajouter les coins
            await pool.query(
                `INSERT INTO coin_transactions (user_id, amount, reason)
                 VALUES ($1, $2, 'Achat de coins')`,
                [userId, pack.coins]
            );

            // Mettre à jour le solde
            await pool.query(
                `INSERT INTO coins (user_id, balance)
                 VALUES ($1, $2)
                 ON CONFLICT (user_id)
                 DO UPDATE SET balance = coins.balance + $2`,
                [userId, pack.coins]
            );
        }

        // Valider la transaction
        await pool.query('COMMIT');
    } catch (error) {
        // En cas d'erreur, annuler la transaction
        await pool.query('ROLLBACK');
        throw error;
    }
}

// Obtenir l'historique des paiements
export const getPaymentHistory = async (req, res) => {
    try {
        const userId = req.user.id;
        const result = await pool.query(
            `SELECT p.*, 
                    CASE 
                        WHEN p.type = 'subscription' THEN s.end_date
                        ELSE NULL
                    END as subscription_end_date
             FROM payments p
             LEFT JOIN subscriptions s ON p.id = s.payment_id
             WHERE p.user_id = $1
             ORDER BY p.created_at DESC`,
            [userId]
        );
        
        res.json(result.rows);
    } catch (error) {
        console.error('Error getting payment history:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Obtenir le statut de l'abonnement
export const getSubscriptionStatus = async (req, res) => {
    try {
        const userId = req.user.id;
        const result = await pool.query(
            `SELECT s.*, p.amount, p.created_at as payment_date
             FROM subscriptions s
             JOIN payments p ON s.payment_id = p.id
             WHERE s.user_id = $1
             AND s.status = 'active'
             AND s.end_date > CURRENT_TIMESTAMP
             ORDER BY s.end_date DESC
             LIMIT 1`,
            [userId]
        );

        if (result.rows.length === 0) {
            return res.json({
                hasActiveSubscription: false,
                message: 'Aucun abonnement actif'
            });
        }

        const subscription = result.rows[0];
        res.json({
            hasActiveSubscription: true,
            subscription: {
                endDate: subscription.end_date,
                amount: subscription.amount,
                paymentDate: subscription.payment_date
            }
        });
    } catch (error) {
        console.error('Error getting subscription status:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// POST /payments/webhook : gérer le webhook pour créditer les coins
export const handleWebhook = async (req, res) => {
    console.log('=== DÉBUT WEBHOOK FEEXPAY ===');
    console.log('📥 Headers reçus:', JSON.stringify(req.headers, null, 2));
    console.log('📥 Body reçu:', JSON.stringify(req.body, null, 2));
    
    // Extraire les données selon le format de Feexpay
    const { reference, order_id, status, callback_info } = req.body;
    const transactionId = reference || order_id;
    
    // Parser les callback_info si c'est une string
    let paymentInfo = {};
    if (callback_info) {
        try {
            paymentInfo = typeof callback_info === 'string' ? JSON.parse(callback_info) : callback_info;
        } catch (e) {
            console.log('⚠️ Erreur parsing callback_info:', e.message);
        }
    }

    try {
        console.log('🆔 Transaction ID:', transactionId);
        console.log('📊 Status:', status);
        console.log('📋 Payment Info:', paymentInfo);
        
        // Vérifier la signature du webhook
        const signature = req.headers['x-feexpay-signature'];
        console.log('🔐 Signature reçue:', signature);
        
        if (!verifyWebhookSignature(req.body, signature)) {
            console.log('❌ Signature invalide');
            return res.status(401).json({ message: 'Signature invalide' });
        }
        console.log('✅ Signature valide');

        if (status === 'SUCCESSFUL' || status === 'success') {
            console.log('✅ Paiement réussi, traitement en cours...');
            
            // Utiliser le payment_id des callback_info
            const paymentId = paymentInfo.payment_id || transactionId;
            console.log('💾 Payment ID à utiliser:', paymentId);
            
            // Récupérer les détails de la transaction
            const paymentResult = await pool.query(
                'SELECT user_id, coins_added, type, amount FROM payments WHERE id = $1',
                [paymentId]
            );

            console.log('🔍 Résultat de la requête paiement:', paymentResult.rows);

            if (paymentResult.rows.length === 0) {
                console.log('❌ Transaction non trouvée dans la base de données');
                return res.status(404).json({ message: 'Transaction non trouvée' });
            }

            const { user_id, coins_added, type, amount } = paymentResult.rows[0];
            console.log('👤 User ID:', user_id);
            console.log('🪙 Coins à ajouter:', coins_added);
            console.log('🏷️ Type:', type);
            console.log('💰 Montant:', amount);

            console.log('🔄 Début de la transaction de base de données...');
            await pool.query('BEGIN');

            if (type === 'subscription') {
                console.log('📅 Traitement d\'un abonnement...');
                // Créer ou mettre à jour l'abonnement
                const subscriptionEnd = new Date();
                subscriptionEnd.setDate(subscriptionEnd.getDate() + 30); // 30 jours par défaut

                await pool.query(
                    `INSERT INTO subscriptions (user_id, start_date, end_date, status)
                     VALUES ($1, NOW(), $2, 'active')
                     ON CONFLICT (user_id) 
                     DO UPDATE SET 
                        start_date = NOW(),
                        end_date = $2,
                        status = 'active'`,
                    [user_id, subscriptionEnd]
                );
                console.log('✅ Abonnement créé/mis à jour');
            }

            console.log('🪙 Créditation des coins...');
            // Créditer les coins à l'utilisateur
            await pool.query(
                `INSERT INTO coins (user_id, balance)
                 VALUES ($1, $2)
                 ON CONFLICT (user_id)
                 DO UPDATE SET balance = coins.balance + $2`,
                [user_id, coins_added]
            );
            console.log('✅ Coins crédités');

            console.log('📝 Enregistrement de la transaction...');
            await pool.query(
                'INSERT INTO coin_transactions (user_id, amount, reason) VALUES ($1, $2, $3)',
                [user_id, coins_added, type === 'subscription' ? 'Abonnement' : 'Achat de coins']
            );
            console.log('✅ Transaction enregistrée');

            console.log('🔄 Mise à jour du statut du paiement...');
            await pool.query(
                'UPDATE payments SET status = $1 WHERE id = $2',
                ['success', paymentId]
            );
            console.log('✅ Statut du paiement mis à jour');

            await pool.query('COMMIT');
            console.log('✅ Transaction de base de données validée');

            console.log('📧 Envoi de l\'email de confirmation...');
            // Envoyer la facture détaillée par email
            const userEmail = await getUserEmail(user_id);
            const invoiceText = generateInvoiceText({
                userEmail,
                amount,
                transactionId,
                type,
                date: new Date().toLocaleString(),
                coinsAdded: coins_added
            });
            await sendEmail({
                to: userEmail,
                subject: 'Votre facture de paiement - Scrolleo',
                html: invoiceText
            });
            console.log('✅ Email envoyé');

            console.log('🔔 Envoi de la notification...');
            // Envoyer une notification simple (optionnel)
            await sendNotification(
                user_id,
                type === 'subscription' ?
                    'Votre abonnement a été activé avec succès !' :
                    'Paiement réussi ! Vos coins ont été crédités.'
            );
            console.log('✅ Notification envoyée');

            console.log('📤 Réponse de succès envoyée à Feexpay');
            console.log('=== FIN WEBHOOK FEEXPAY ===');
            res.json({ message: 'Transaction traitée avec succès' });
        } else {
            console.log('❌ Paiement échoué, statut:', status);
            const paymentId = paymentInfo.payment_id || transactionId;
            await pool.query(
                'UPDATE payments SET status = $1 WHERE id = $2',
                ['failed', paymentId]
            );
            console.log('✅ Statut mis à jour: failed');
            console.log('=== FIN WEBHOOK FEEXPAY ===');
            res.json({ message: 'Transaction échouée' });
        }
  } catch (error) {
        console.log('💥 ERREUR dans le webhook:', error.message);
        await pool.query('ROLLBACK');
        console.error('Erreur lors du traitement du webhook:', error);
        console.log('=== FIN WEBHOOK FEEXPAY (ERREUR) ===');
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

// Fonction pour vérifier la signature du webhook
const verifyWebhookSignature = (payload, signature) => {
    // TODO: Implémenter la vérification de la signature selon la documentation de Feexpay
    return true; // Temporairement retourne true pour les tests
};

// Fonction pour envoyer une notification
const sendNotification = async (userId, message) => {
  try {
    // Envoyer un email via nodemailer
    const mailOptions = {
      to: await getUserEmail(userId),
      subject: 'Notification de paiement',
      text: message
    };
    await sendEmail(mailOptions);

    // Enregistrer la notification dans la base de données
        await pool.query(
      'INSERT INTO notifications (user_id, message, type) VALUES ($1, $2, $3)',
      [userId, message, 'payment']
    );

    // Envoyer une notification temps réel si WebSocket est configuré
    if (global.io) {
      global.io.to(`user_${userId}`).emit('notification', {
        type: 'payment',
        message
      });
    }

    console.log(`Notification envoyée à l'utilisateur ${userId}: ${message}`);
  } catch (error) {
    console.error('Erreur lors de l\'envoi de la notification:', error);
    // On ne relance pas l'erreur pour ne pas bloquer le flux principal
  }
};

// Vérifier l'état d'un paiement
export const checkPaymentStatus = async (req, res) => {
    try {
        const { paymentId } = req.params;
        const userEmail = req.user.email;
        
        // Obtenir l'ID utilisateur
        const userId = await getUserIdFromEmail(userEmail);

        // Vérifier le paiement
        const result = await pool.query(
            `SELECT p.*, c.balance as current_balance 
             FROM payments p 
             LEFT JOIN coins c ON p.user_id = c.user_id 
             WHERE p.id = $1 AND p.user_id = $2`,
            [paymentId, userId]
    );

    if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Paiement non trouvé' });
    }

        const payment = result.rows[0];
    res.json({
            paymentId: payment.id,
            status: payment.status,
            amount: payment.amount,
            coinsAdded: payment.coins_added,
            currentBalance: payment.current_balance || 0,
            createdAt: payment.created_at
    });
  } catch (error) {
        console.error('Error checking payment status:', error);
        res.status(500).json({ error: 'Internal server error' });
  }
}; 