-- SQL script to create the episodes table
CREATE TABLE IF NOT EXISTS episodes (
  episode_id SERIAL PRIMARY KEY,
  movie_id INTEGER NOT NULL REFERENCES movies(movie_id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT DEFAULT NULL,
  episode_number INTEGER NOT NULL,
  season_number INTEGER NOT NULL,
  views INTEGER DEFAULT 0,
  is_favorite BOOLEAN DEFAULT FALSE,
  is_free BOOLEAN DEFAULT FALSE,
  coin_cost INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(movie_id, season_number, episode_number)
);