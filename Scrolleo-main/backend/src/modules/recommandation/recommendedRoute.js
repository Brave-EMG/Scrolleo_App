import express from 'express';
import { getRecommendedMovies } from './recommendedControllers.js';

const router = express.Router();

router.get('/recommendations/:user_id', getRecommendedMovies);

export default router;
