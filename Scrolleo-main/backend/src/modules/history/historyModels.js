import pool from '../../config/database.js';

const createhistoryTable = `

CREATE TABLE IF NOT EXISTS user_history (
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    episode_id INTEGER REFERENCES episodes(episode_id) ON DELETE CASCADE,
    movie_id INTEGER REFERENCES movies(movie_id) ON DELETE CASCADE,
    watched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_position INTEGER DEFAULT 0, -- en secondes si tu veux la reprise exacte
    PRIMARY KEY (user_id, episode_id)
); 
 `;

 pool.query(createhistoryTable)
     .then(() => console.log('Table history created successfully'))
     .catch((err) => console.error('Error creating table:', err));
 