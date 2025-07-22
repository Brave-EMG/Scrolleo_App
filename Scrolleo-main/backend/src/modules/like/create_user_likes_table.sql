-- Création de la table user_likes
CREATE TABLE IF NOT EXISTS user_likes (
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    movie_id INTEGER REFERENCES movies(movie_id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, movie_id)
);
