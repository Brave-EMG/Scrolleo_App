import pool from '../../config/database.js';


const episode_views = `
  CREATE TABLE IF NOT EXISTS episode_views (
    user_id INT NOT NULL,
    episode_id INT NOT NULL,
    movie_id INT NOT NULL,
    PRIMARY KEY (user_id, episode_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (episode_id) REFERENCES episodes(episode_id) ON DELETE CASCADE
  );
`;

const movie_views = `
  CREATE TABLE IF NOT EXISTS movie_views (
    user_id INT NOT NULL,
    movie_id INT NOT NULL,
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, movie_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (movie_id) REFERENCES movies(movie_id) ON DELETE CASCADE
  );
`;

pool.query(episode_views)
  .then(() => {
    console.log('Table episode_views created successfully');
    return pool.query(movie_views);
  })
  .then(() => {
    console.log('Table movie_views created successfully');
  })
  .catch((err) => {
    console.error('Error creating tables:', err);
  });