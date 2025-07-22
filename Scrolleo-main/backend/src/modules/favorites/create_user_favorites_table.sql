-- Création de la table user_favorites
CREATE TABLE IF NOT EXISTS user_favorites (
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    episode_id INTEGER REFERENCES episodes(episode_id) ON DELETE CASCADE,
    movie_id INTEGER REFERENCES movies(movie_id) ON DELETE CASCADE,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_watched_at TIMESTAMP,
    PRIMARY KEY (user_id, movie_id)
);
