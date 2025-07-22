import pool from '../../config/database.js';

const createLikeTable = `
CREATE TABLE IF NOT EXISTS user_likes (
  user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
  movie_id INTEGER REFERENCES movies(movie_id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, movie_id)
);
`;

pool.query(createLikeTable)
  .then(() => console.log('Table user_likes created successfully'))
  .catch((err) => console.error('Error creating table:', err));
