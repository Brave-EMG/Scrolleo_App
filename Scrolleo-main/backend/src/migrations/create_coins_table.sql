-- Ajout de la colonne coin_cost et is_premium dans la table episode
ALTER TABLE episodes
ADD COLUMN coin_cost INTEGER DEFAULT 1,
ADD COLUMN is_premium BOOLEAN DEFAULT FALSE;

-- Solde de coins pour chaque utilisateur
CREATE TABLE coins (
    user_id INTEGER PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    balance INTEGER DEFAULT 0
);

-- Transactions de coins
CREATE TABLE coin_transactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    amount INTEGER NOT NULL,  -- positif = gain, négatif = dépense
    reason TEXT,
    episode_id INTEGER REFERENCES episodes(episode_id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Épisodes débloqués pour chaque utilisateur
CREATE TABLE unlocked_episodes (
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    episode_id INTEGER REFERENCES episodes(episode_id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, episode_id)
);

-- Bonus : système de présence / récompenses quotidiennes
CREATE TABLE daily_rewards (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    reward_date DATE NOT NULL,
    coins_earned INTEGER DEFAULT 10,
    UNIQUE (user_id, reward_date)
);
