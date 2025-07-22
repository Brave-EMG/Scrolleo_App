import { Router } from 'express';
import { Pool } from 'pg';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.join(__dirname, '../../.env') });

const router = Router();

// Test de connexion à la base de données
const testDBConnection = async () => {
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.POSTGRES_SSL === 'true' ? { rejectUnauthorized: false } : false
  });

  try {
    const client = await pool.connect();
    await client.query('SELECT NOW()');
    client.release();
    return true;
  } catch (err) {
    console.error('Database connection error:', err);
    return false;
  }
};

router.get('/', async (req, res) => {
  const dbStatus = await testDBConnection();
  
  const health = {
    uptime: process.uptime(),
    timestamp: Date.now(),
    database: dbStatus ? 'healthy' : 'unhealthy',
    message: dbStatus ? 'OK' : 'Database connection failed'
  };

  res.status(dbStatus ? 200 : 503).json(health);
});

export default router;
