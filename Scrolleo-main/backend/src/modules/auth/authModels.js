import pool from '../../config/database.js';

const createTableQuery = `
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
`;

const createResetTokenIndex = `
  CREATE INDEX IF NOT EXISTS idx_reset_token ON users(reset_token);
`;

pool.query(createTableQuery)
  .then(() => {
    console.log('Table users created successfully');
    return pool.query(createResetTokenIndex);
  })
  .then(() => console.log('Index on reset_token created successfully'))
  .catch((err) => console.error('Error setting up users table:', err));
