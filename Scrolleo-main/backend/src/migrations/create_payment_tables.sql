-- Supprimer les anciennes tables
DROP TABLE IF EXISTS feexpay_transactions;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS subscriptions;
DROP TABLE IF EXISTS fedapay_transactions;
DROP TABLE IF EXISTS paypal_orders;

-- Paiements (achat de pièces ou abonnement)
CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    amount INTEGER NOT NULL,          -- montant payé en XOF
    coins_added INTEGER NOT NULL,     -- combien de pièces reçues
    provider VARCHAR(50) DEFAULT 'feexpay',
    status VARCHAR(20) DEFAULT 'pending',  -- pending, success, failed
    type VARCHAR(20) NOT NULL,        -- subscription, coins
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Abonnements pour chaque utilisateur
CREATE TABLE subscriptions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    payment_id INTEGER REFERENCES payments(id),
    start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'active',  -- active, expired, cancelled
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Créer la table pour Feexpay
CREATE TABLE feexpay_transactions (
    id SERIAL PRIMARY KEY,
    transaction_id VARCHAR(255) NOT NULL UNIQUE,
    payment_id INTEGER NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Créer les index
CREATE INDEX IF NOT EXISTS idx_feexpay_transaction_id ON feexpay_transactions(transaction_id);
CREATE INDEX IF NOT EXISTS idx_feexpay_payment_id ON feexpay_transactions(payment_id); 
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id); 