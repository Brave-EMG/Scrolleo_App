-- Création de la table `movies`
CREATE TABLE IF NOT EXISTS movies (
  movie_id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  genre VARCHAR(100),
  description TEXT,
  release_date DATE,
  cover_image TEXT,
  director_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
  episodes_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  views INTEGER DEFAULT 0,
  likes INTEGER DEFAULT 0,
  status VARCHAR(100) DEFAULT 'NoExclusive',
  season INTEGER DEFAULT 1
);
