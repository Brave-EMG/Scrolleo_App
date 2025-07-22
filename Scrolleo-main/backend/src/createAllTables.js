import pool from './config/database.js'; // adapte le chemin si besoin

async function createTables() {
    const queries = [
        // === USERS ===
        {
          name: 'users',
          query: `
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
          `
        },
        {
          name: 'idx_reset_token',
          query: `CREATE INDEX IF NOT EXISTS idx_reset_token ON users(reset_token);`
        },
      
        // === MOVIES ===
        {
          name: 'movies',
          query: `
            CREATE TABLE IF NOT EXISTS movies (
              movie_id SERIAL PRIMARY KEY,
              title VARCHAR(255) NOT NULL,
              genre VARCHAR(100),
              description TEXT,
              release_date DATE,
              cover_image TEXT,
              director_id INTEGER REFERENCES users(user_id),
              episodes_count INTEGER DEFAULT 0,
              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
              updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
              views INTEGER DEFAULT 0,
              likes INTEGER DEFAULT 0,
              status VARCHAR(100) DEFAULT 'approved',
              season INTEGER DEFAULT 1
            );
          `
        },
      
        // === EPISODES ===
        {
          name: 'episodes',
          query: `
            CREATE TABLE IF NOT EXISTS episodes (
              episode_id SERIAL PRIMARY KEY,
              movie_id INTEGER NOT NULL REFERENCES movies(movie_id) ON DELETE CASCADE,
              title VARCHAR(255) NOT NULL,
              description TEXT DEFAULT NULL,
              episode_number INTEGER NOT NULL,
              season_number INTEGER NOT NULL,
              views INTEGER DEFAULT 0,
              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
              updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
              coin_cost INTEGER DEFAULT 100,
              is_premium BOOLEAN DEFAULT FALSE,
              UNIQUE(movie_id, season_number, episode_number)
            );
          `
        },
      
        // === EPISODE_VIEWS & MOVIE_VIEWS ===
        {
          name: 'episode_views',
          query: `
            CREATE TABLE IF NOT EXISTS episode_views (
              user_id INT NOT NULL,
              episode_id INT NOT NULL,
              movie_id INT NOT NULL,
              PRIMARY KEY (user_id, episode_id),
              FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
              FOREIGN KEY (episode_id) REFERENCES episodes(episode_id) ON DELETE CASCADE
            );
          `
        },
        {
          name: 'movie_views',
          query: `
            CREATE TABLE IF NOT EXISTS movie_views (
              user_id INT NOT NULL,
              movie_id INT NOT NULL,
              viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
              PRIMARY KEY (user_id, movie_id),
              FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
              FOREIGN KEY (movie_id) REFERENCES movies(movie_id) ON DELETE CASCADE
            );
          `
        },
      
        // === FAVORITES, LIKES, HISTORY ===
        {
          name: 'user_favorites',
          query: `
            CREATE TABLE IF NOT EXISTS user_favorites (
              user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
              episode_id INTEGER REFERENCES episodes(episode_id) ON DELETE CASCADE,
              movie_id INTEGER REFERENCES movies(movie_id) ON DELETE CASCADE,
              added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
              last_watched_at TIMESTAMP,
              PRIMARY KEY (user_id, movie_id)
            );
          `
        },
        {
          name: 'user_history',
          query: `
            CREATE TABLE IF NOT EXISTS user_history (
              user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
              episode_id INTEGER REFERENCES episodes(episode_id) ON DELETE CASCADE,
              movie_id INTEGER REFERENCES movies(movie_id) ON DELETE CASCADE,
              watched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
              last_position INTEGER DEFAULT 0,
              PRIMARY KEY (user_id, episode_id)
            );
          `
        },
        {
          name: 'user_likes',
          query: `
            CREATE TABLE IF NOT EXISTS user_likes (
              user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
              movie_id INTEGER REFERENCES movies(movie_id) ON DELETE CASCADE,
              PRIMARY KEY (user_id, movie_id)
            );
          `
        },
      
        // === COINS ===
        {
          name: 'coins',
          query: `
            CREATE TABLE coins (
              user_id INTEGER PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
              balance INTEGER DEFAULT 0
            );
          `
        },
        {
          name: 'coin_transactions',
          query: `
            CREATE TABLE coin_transactions (
              id SERIAL PRIMARY KEY,
              user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
              amount INTEGER NOT NULL,
              reason TEXT,
              episode_id INTEGER REFERENCES episodes(episode_id) ON DELETE CASCADE,
              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
          `
        },
        {
          name: 'unlocked_episodes',
          query: `
            CREATE TABLE unlocked_episodes (
              user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
              episode_id INTEGER REFERENCES episodes(episode_id) ON DELETE CASCADE,
              unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
              PRIMARY KEY (user_id, episode_id)
            );
          `
        },
        {
          name: 'daily_rewards',
          query: `
            CREATE TABLE daily_rewards (
              id SERIAL PRIMARY KEY,
              user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
              reward_date DATE NOT NULL,
              coins_earned INTEGER DEFAULT 10,
              UNIQUE (user_id, reward_date)
            );
          `
        },
      
        // === PAYMENTS & SUBSCRIPTIONS ===
        {
          name: 'payments',
          query: `
            CREATE TABLE payments (
              id SERIAL PRIMARY KEY,
              user_id INTEGER REFERENCES users(user_id),
              amount INTEGER NOT NULL,
              coins_added INTEGER NOT NULL,
              provider VARCHAR(50) DEFAULT 'feexpay',
              status VARCHAR(20) DEFAULT 'pending',
              type VARCHAR(20) NOT NULL,
              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
              updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
          `
        },
        {
          name: 'subscriptions',
          query: `
            CREATE TABLE subscriptions (
              id SERIAL PRIMARY KEY,
              user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
              payment_id INTEGER REFERENCES payments(id),
              start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
              end_date TIMESTAMP NOT NULL,
              status VARCHAR(20) DEFAULT 'active',
              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
              updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
          `
        },
        {
          name: 'feexpay_transactions',
          query: `
            CREATE TABLE feexpay_transactions (
              id SERIAL PRIMARY KEY,
              transaction_id VARCHAR(255) NOT NULL UNIQUE,
              payment_id INTEGER NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
              created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
              updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
          `
        },
        {
          name: 'idx_feexpay_transaction_id',
          query: `
            CREATE INDEX IF NOT EXISTS idx_feexpay_transaction_id ON feexpay_transactions(transaction_id);
          `
        },
        {
          name: 'idx_feexpay_payment_id',
          query: `
            CREATE INDEX IF NOT EXISTS idx_feexpay_payment_id ON feexpay_transactions(payment_id);
          `
        },
        {
          name: 'idx_subscriptions_user_id',
          query: `
            CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
          `
        },
        {
          name: 'idx_payments_user_id',
          query: `
            CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);
          `
        },
      
        // === UPLOADS ===
        { 
          name: 'uploads',
          query: `
            CREATE TABLE uploads (
              upload_id SERIAL PRIMARY KEY,
              episode_id INTEGER NOT NULL REFERENCES episodes(episode_id) ON DELETE CASCADE,
              filename VARCHAR(255) NOT NULL,
              original_name VARCHAR(255) NOT NULL,
              mime_type VARCHAR(100) NOT NULL,
              size BIGINT NOT NULL,
              path TEXT NOT NULL,
              type VARCHAR(20) NOT NULL CHECK (type IN ('video', 'thumbnail', 'subtitle')),
              status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
              metadata JSONB DEFAULT '{}',
              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
              updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
          `
        }
      ];
      
  for (const {name, query} of queries) {
    try {
      await pool.query(query);
      console.log(`✅ Table/Index "${name}" créée ou vérifiée.`);
    } catch (err) {
      console.error(`❌ Erreur sur "${name}":\n`, err);
    }
  }  

  console.log('🎉 Toutes les tables ont été créées ou vérifiées avec succès.');
  process.exit(0);
}

createTables();
