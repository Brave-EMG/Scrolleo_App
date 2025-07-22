import express from 'express';
import multer from 'multer';

const upload = multer(); // stocke le fichier en mémoire (buffer)

// import upload from './moviesMiddleware.js';

// import upload  from './moviesControllers.js';
import  {
    createMovie,
    getAllMovies,
    updateMovie,
    deleteMovie,
    getMovieById,
    getMoviesByGenre,
    getMoviesByDirector,
    getUpcomingMovies,
    getNewMovies,
    getMostViewedMovies,
    getMostLikedMovies,
    getTrendingAndTopMovies,
    getDiscoveryMovies,//ici
    getRecommendedMovies,
    getDirectorMoviesYoungerThan2Years,
    getDirectorMoviesBetween2And5Years,
    getDirectorMoviesBetween5And20Years,
    getMoviesYoungerThan2Years,
    getMoviesBetween2And5Years,
    getMoviesBetween5And20Years,
    getExclusiveMovies

    // getapprovedMovies,
    // incrementMovieLikes,
    // searchMovies,
    // incrementMovieViews,
    // approveMovie,
    // rejectMovie,
    // getPendingMovies,
    // getRejectedMovies,


} from './moviesControllers.js'

const router = express.Router();

// Routes pour les films
router.post('/create', upload.single('cover_image'), createMovie);
router.get('/movies', getAllMovies); 
router.get('/detail/:id', getMovieById); 
router.put('/:id', upload.single('cover_image'), updateMovie); 
router.delete('/:id', deleteMovie);
router.get('/director/:director_id', getMoviesByDirector); 

router.get('/genre/:genre', getMoviesByGenre);
router.get('/upcoming', getUpcomingMovies);
router.get('/recentlyadded', getNewMovies);
router.get('/mostview', getMostViewedMovies);
router.get('/mostliked', getMostLikedMovies);

router.get('/trendingMovies', getTrendingAndTopMovies);
router.get('/discoveryMovies', getDiscoveryMovies);
router.get('/RecommendedMovies', getRecommendedMovies);

router.get('/director/recent', getDirectorMoviesYoungerThan2Years);
router.get('/director/mid-old', getDirectorMoviesBetween2And5Years);
router.get('/director/old', getDirectorMoviesBetween5And20Years);

router.get('/recent', getMoviesYoungerThan2Years);
router.get('/mid-old', getMoviesBetween2And5Years);
router.get('/old', getMoviesBetween5And20Years);

router.get('/exclusive', getExclusiveMovies);


// router.get('/rejected', async (req, res) => {
//   try {
//     const rejectedMovies = await Movie.find({ status: 'rejected' });
//     res.json(rejectedMovies);
//   } catch (error) {
//     res.status(500).json({ message: error.message });
//   }
// });

// router.put('/:id/reaccept', async (req, res) => {
//   try {
//     const movie = await Movie.findById(req.params.id);
//     if (!movie) {
//       return res.status(404).json({ message: 'Film non trouvé' });
//     }
//     movie.status = 'pending';
//     await movie.save();
//     res.json(movie);
//   } catch (error) {
//     res.status(500).json({ message: error.message });
//   }
// });

// router.get('/search', searchMovies);
// router.patch('/view/:id', incrementMovieViews);
// router.patch('/likes/:id', incrementMovieLikes);
// router.patch('/:id/approve', approveMovie);
// router.patch('/:id/reject', rejectMovie);
// router.get('/Pending', getPendingMovies);
// router.get('/rejected', getRejectedMovies);
// router.post('/favorites/add', addFavorite);
// router.delete('/favorites/remove', removeFavorite);
// router.get('/favorites/:user_id', getUserFavorites);


export default router;
