import express from 'express';
import {
  addEpisodeView,
  addMovieView,
  getAllEpisodeViews,
  updateEpisodeView,
  getAllMovieViews
} from './viewControllers.js';

const router = express.Router();


router.post("/episode", addEpisodeView);
router.post("/movie", addMovieView);
router.get("/episode-views", getAllEpisodeViews);
router.put("/updateEpisodeView", updateEpisodeView);
router.get("/movie-views", getAllMovieViews);

export default router;