import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import healthcheckRoutes from './modules/shared/healthcheck.js';

// Configuration de dotenv
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// CORS configuration
const corsOptions = {
  origin: process.env.NODE_ENV === 'production' 
    ? ['https://scrolleo.brave-emg.com', 'http://localhost:3001', 'https://localhost:3001'] // Remplacer par votre domaine frontend en production
    : ['http://localhost:5000', 'http://localhost:5001', 'http://localhost:3000', 'http://localhost:3001', 'https://localhost:3001'], // En développement, autoriser localhost
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Content-Length'],
  optionsSuccessStatus: 200 // Pour les navigateurs legacy
};

// Import des routes
//import authRoutes from './routes/authRoutes.js';
import episodeRoutes from '../src/modules/episodes/episodeRoute.js';
import viewRoutes from '../src/modules/view/viewRoutes.js';
import authRoutes from '../src/modules/auth/authRoutes.js'; // Routes d'authentification
import moviesRoutes from '../src/modules/movies/moviesRoutes.js'; // Routes movies
import uploadRoutes from './modules/upload/uploadRoutes.js'; // upload route
import historyRoutes from '../src/modules/history/historyRoutes.js' // history route
import favoritesRoutes from '../src/modules/favorites/favoriteRoutes.js' //  favorite route
import viewsRoutes from '../src/modules/view/viewRoutes.js'
import statsRoutes from '../src/modules/stats/statRoutes.js';  // stats route
// import { getRecommendedMovies } from '../src/modules/recommandation/recommendedControllers.js';// recommder routes

import coinsRoutes from '../src/modules/coins/coinsRoutes.js';

import likeRoutes from '../src/modules/like/likeRoute.js' //  like route
import paymentsRoutes from '../src/modules/payments/paymentsRoutes.js'; //  payments route
// import { getRecommendedMovies } from '../src/modules/recommandation/recommendedControllers.js';// recommder routes::
import statsAdminRoutes from '../src/modules/statsAdmin/statsAdminRoutes.js';

const app = express();

// Ajout pour Render/proxy
app.set('trust proxy', 1);

// CORS configuration (AVANT helmet pour éviter les conflits)
app.use(cors(corsOptions));

// Security middlewares
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" },
  crossOriginEmbedderPolicy: false
}));

// Rate limiting - plus permissif en développement
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: process.env.NODE_ENV === 'production' ? 100 : 1000, // 1000 requêtes en dev, 100 en prod
  message: {
    error: 'Too many requests, please try again later.',
    retryAfter: Math.ceil(15 * 60 / 1000) // 15 minutes en secondes
  },
  standardHeaders: true,
  legacyHeaders: false
});
app.use(limiter);

// Parsers JSON/urlencoded AVANT les routes qui attendent du JSON
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

app.get('/', (req, res) => {
  res.json({ message: 'Welcome to Streaming Platform API' });
});


// Servir les fichiers du dossier 'uploads' sous l'URL '/uploads'
app.use('/uploads', express.static(path.join(__dirname, '../uploads/')));

// Routes qui attendent du JSON
app.use('/api/auth', authRoutes);
app.use('/api/episodes', episodeRoutes);
//app.use('/api/movies', movieRoutes);

// Route d'upload APRÈS (pour que multer fonctionne)
app.use('/api/uploads', uploadRoutes);
app.use('/api/movies', moviesRoutes);
app.use('/api/history',historyRoutes);
app.use('/api/favorites',favoritesRoutes);
app.use('/api/likes',likeRoutes);
app.use('/api/payments',paymentsRoutes);
app.use('/api/coins', coinsRoutes);
app.use('/api/stats',statsRoutes);
app.use('/api/admin/stats', statsAdminRoutes);
app.use('/api/views', viewsRoutes);
// app.use('/api/favorites',getRecommendedMovies)

// Routes
app.use('/health', healthcheckRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Erreur détaillée:', err);
  res.status(500).json({ 
    error: 'Something went wrong!',
    details: err.message
  });
});

import { globalErrorHandler } from './modules/shared/errorHandler.js';

// Error handling middleware
app.use(globalErrorHandler);

const PORT = process.env.PORT || 3000;
const HOST = process.env.NODE_ENV === 'production' ? '0.0.0.0' : 'localhost';

const server = app.listen(PORT, HOST, () => {
  console.log(`🚀 Server is running at: http://${HOST}:${PORT}`);
});

// Handle unhandled rejections
process.on('unhandledRejection', (err) => {
  console.log('UNHANDLED REJECTION! 💥 Shutting down...');
  console.log(err.name, err.message);
  server.close(() => {
    process.exit(1);
  });
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.log('UNCAUGHT EXCEPTION! 💥 Shutting down...');
  console.log(err.name, err.message);
  process.exit(1);
});

// Handle SIGTERM
process.on('SIGTERM', () => {
  console.log('👋 SIGTERM RECEIVED. Shutting down gracefully');
  server.close(() => {
    console.log('💥 Process terminated!');
  });
});

export default app;
