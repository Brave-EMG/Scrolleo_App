-- Création de la table users
CREATE TABLE IF NOT EXISTS users (
  user_id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password TEXT NOT NULL,
  username VARCHAR(100),
  role VARCHAR(20) DEFAULT 'user',
  coins INT DEFAULT 0,
  subscription_type VARCHAR(20),
  subscription_expiry DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  reset_token TEXT DEFAULT NULL,
  reset_token_expiration TIMESTAMP DEFAULT NULL
);

-- Création de l'index sur reset_token
CREATE INDEX IF NOT EXISTS idx_reset_token ON users(reset_token);
