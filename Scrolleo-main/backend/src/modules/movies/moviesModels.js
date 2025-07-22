import pool from '../../config/database.js';
const createMoviesTable = `
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
      status VARCHAR(100) DEFAULT 'NoExclusive',
      season INTEGER DEFAULT 1
    );
  `;



// const createUserFavoriteMoviesTable = `

//   CREATE TABLE user_favorites (
//     id SERIAL PRIMARY KEY,
//     user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
//     movie_id INTEGER REFERENCES movies(movie_id) ON DELETE CASCADE,
//     added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
//     UNIQUE (user_id, movie_id)
// );
//   `;


pool.query(createMoviesTable)
    .then(() => console.log('Table Movies created successfully'))
    .catch((err) => console.error('Error creating table:', err));

// pool.query(createUserFavoriteMoviesTable)
//     .then(() => console.log('Table UserFavoriteMovies created successfully'))
//     .catch((err) => console.error('Error creating table:', err));