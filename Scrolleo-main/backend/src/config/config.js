import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

//dotenv.config({ path: path.join(__dirname, '../.env') });
const envFile = process.env.NODE_ENV === 'production' ? '../.env.production' : '../.env';
console.log('🌱 ENV File Loaded:', envFile);
console.log('📦 Current DB:', process.env.POSTGRES_DB);
//dotenv.config({ path: envFile });

dotenv.config({ path: path.join(__dirname, envFile) });