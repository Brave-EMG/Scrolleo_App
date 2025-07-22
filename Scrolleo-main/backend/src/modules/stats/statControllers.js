import pool from '../../config/database.js';

//recuperer les stats en fonction du movie id
export async function getMovieStats(req, res) {
  const { director_id } = req.params;

  try {
    const result = await pool.query(`
      SELECT 
        movies.title,
        movies.likes,
        movies.views,
        movies.release_date,
        movies.genre,
        COUNT(user_favorites.movie_id) AS favorites
      FROM movies
      LEFT JOIN user_favorites ON movies.movie_id = user_favorites.movie_id
      WHERE movies.director_id = $1
      GROUP BY movies.title, movies.likes, movies.views, movies.release_date, movies.genre
    `, [director_id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Film non trouvé' });
    }

    res.status(200).json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des stats du film:', error);
    res.status(500).json({ error: 'Erreur serveur', details: error.message });
  }
}

//recuperer les stats par realisateur

export async function getDirectorStats(req, res) {
  const { director_id } = req.params;

  try {
    const result = await pool.query(`
        SELECT 
          users.user_id,
          users.username,
          COUNT(DISTINCT movies.movie_id) AS total_movies,
          COALESCE(SUM(movies.views), 0) AS total_views,
          COALESCE(SUM(movies.likes), 0) AS total_likes,
          COALESCE(COUNT(user_favorites.movie_id), 0) AS total_favorites
        FROM users
        LEFT JOIN movies ON movies.director_id = users.user_id
        LEFT JOIN user_favorites ON movies.movie_id = user_favorites.movie_id
        WHERE movies.director_id = $1
        GROUP BY  users.user_id, users.username
      `, [director_id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Réalisateur non trouvé' });
    }

    res.status(200).json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des stats du réalisateur:', error);
    res.status(500).json({ error: 'Erreur serveur', details: error.message });
  }
}


//recuperer les meilleur films d'un realisateur 
export async function getTopRatedMoviesByDirector(req, res) {
  const { director_id } = req.params;

  try {
    const topRatedMoviesQuery = `
        SELECT 
          movies.title,
          movies.likes,
          movies.views,
          movies.genre,
          movies.release_date,
          COUNT(user_favorites.movie_id) AS favorites,
         ((movies.likes::float / NULLIF(MAX(movies.likes) OVER (), 0)) * 50 + 
         (movies.views::float / NULLIF(MAX(movies.views) OVER (), 0)) * 30 + 
         (COUNT(user_favorites.movie_id)::float / NULLIF(MAX(COUNT(user_favorites.movie_id)) OVER (), 0)) * 20) AS rating
        FROM movies
        LEFT JOIN user_favorites ON movies.movie_id = user_favorites.movie_id
        WHERE movies.director_id = $1
        GROUP BY movies.movie_id, movies.title, movies.likes, movies.views, movies.genre, movies.release_date
        ORDER BY rating DESC
        LIMIT 5;
      `;

    const result = await pool.query(topRatedMoviesQuery, [director_id]);
    res.status(200).json({
      topRatedMovies: result.rows
    });
  } catch (error) {
    console.error('Error fetching top rated movies for director:', error);
    res.status(500).json({
      error: 'Error fetching top rated movies for director',
      details: error.message
    });
  }
}


//recuperer les films recents d'un realisateur 

export async function getRecentMoviesByDirector(req, res) {
  const director_id = req.params.director_id;

  try {
    const recentTopRatedMoviesQuery = `
        SELECT 
          movies.title,
          movies.likes,
          movies.views,
          COUNT(user_favorites.movie_id) AS favorites,
         ((movies.likes::float / NULLIF(MAX(movies.likes) OVER (), 0)) * 50 + 
         (movies.views::float / NULLIF(MAX(movies.views) OVER (), 0)) * 30 + 
        (COUNT(user_favorites.movie_id)::float / NULLIF(MAX(COUNT(user_favorites.movie_id)) OVER (), 0)) * 20) AS rating,
          movies.created_at
        FROM movies
        LEFT JOIN user_favorites ON movies.movie_id = user_favorites.movie_id
        WHERE movies.director_id = $1
        GROUP BY movies.movie_id, movies.title, movies.likes, movies.views, movies.created_at
        ORDER BY movies.release_date DESC
        LIMIT 5;
      `;

    const result = await pool.query(recentTopRatedMoviesQuery, [director_id]);  // Passe le director_id comme paramètre
    res.status(200).json({
      recentTopRatedMovies: result.rows
    });
  } catch (error) {
    console.error('Error fetching recent top rated movies for director:', error);
    res.status(500).json({
      error: 'Error fetching recent top rated movies for director',
      details: error.message
    });
  }
}


//recuperer les films en attentes d'un realisateur 
export async function getPendingMoviesByDirector(req, res) {
  const directorId = req.params.directorId;

  try {
    const pendingTopRatedMoviesQuery = `
      SELECT 
        movies.title,
        movies.created_at,
        movies.genre
      FROM movies
      WHERE movies.status = 'pending'
        AND movies.director_id = $1 
      ORDER BY movies.created_at DESC
      LIMIT 5;
    `;

    const result = await pool.query(pendingTopRatedMoviesQuery, [directorId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        message: "Aucun film en attente trouvé pour ce réalisateur."
      });
    }

    res.status(200).json({
      pendingTopRatedMovies: result.rows
    });
  } catch (error) {
    console.error('Error fetching pending movies for director:', error);
    res.status(500).json({
      error: 'Erreur lors de la récupération des films en attente pour le réalisateur',
      details: error.message
    });
  }
}


//   les films qui sont pas encore sortie par realisateur

export const getUpcomingMoviesByDirector = async (req, res) => {
  const { director_id } = req.params;

  try {
    const result = await pool.query(
      `SELECT * FROM movies 
       WHERE director_id = $1
         AND release_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '14 days'
       ORDER BY release_date ASC`,
      [director_id]
    );

    if (result.rows.length > 0) {
      res.json(result.rows);
    } else {
      res.status(404).json({ message: 'Aucun film prévu pour sortir dans les deux prochaines semaines pour ce réalisateur' });
    }
  } catch (error) {
    console.error('Erreur lors de la récupération des films à venir:', error);
    res.status(500).json({ message: 'Erreur du serveur' });
  }
};

// Statistiques détaillées des revenus du réalisateur (par épisode et par film)
export const getDirectorRevenueStats = async (req, res) => {
    try {
        const { period = '30' } = req.query;
        const REVENUE_PER_VIEW = 0.6; // 0,6 FCFA par vue
        const userId = req.user.user_id;

        // 1. Récupérer tous les films du réalisateur avec leur date de sortie et status
        const moviesResult = await pool.query(`
            SELECT m.movie_id, m.title, m.release_date, m.status
            FROM movies m
            WHERE m.director_id = $1 AND m.status IN ('approved', 'Exclusive')
        `, [userId]);
        const movies = moviesResult.rows;

        // 2. Récupérer tous les épisodes de ces films
        const movieIds = movies.map(m => m.movie_id);
        let episodes = [];
        if (movieIds.length > 0) {
            const episodesResult = await pool.query(`
                SELECT e.episode_id, e.title, e.movie_id
                FROM episodes e
                WHERE e.movie_id = ANY($1)
            `, [movieIds]);
            episodes = episodesResult.rows;
        }

        // 3. Récupérer les vues par épisode sur la période
        let episodeViews = [];
        if (episodes.length > 0) {
            const episodeIds = episodes.map(e => e.episode_id);
            const viewsResult = await pool.query(`
                SELECT h.episode_id, COUNT(*) as views
                FROM user_history h
                WHERE h.episode_id = ANY($1)
                  AND h.watched_at >= NOW() - INTERVAL '${period} days'
                GROUP BY h.episode_id
            `, [episodeIds]);
            episodeViews = viewsResult.rows;
        }

        // 4. Calcul détaillé par épisode
        const episodeDetails = episodes.map(ep => {
            const movie = movies.find(m => m.movie_id === ep.movie_id);
            const viewsRow = episodeViews.find(v => v.episode_id === ep.episode_id);
            const views = viewsRow ? parseInt(viewsRow.views) : 0;
            // Calcul de l'âge du film
            const releaseDate = movie.release_date ? new Date(movie.release_date) : null;
            const now = new Date();
            const diffYears = releaseDate ? ((now - releaseDate) / (1000 * 60 * 60 * 24 * 365.25)) : 0;

            // Détermination de la catégorie et du pourcentage
            let category = '';
            let percentage = 0;
            let percentageAfter2Years = 0;
            if (movie.status === 'Exclusive') {
                category = 'Exclusivités SCROLLEO';
                percentage = 50;
                percentageAfter2Years = 20;
            } else if (diffYears < 2) {
                category = 'Très récents';
                percentage = 35;
                percentageAfter2Years = 20;
            } else if (diffYears >= 2 && diffYears < 5) {
                category = 'Récents';
                percentage = 30;
                percentageAfter2Years = 20;
            } else if (diffYears >= 5 && diffYears < 20) {
                category = 'Anciens';
                percentage = 20;
                percentageAfter2Years = 20;
            } else {
                category = 'Non catégorisé';
                percentage = 0;
                percentageAfter2Years = 0;
            }

            // Appliquer la dégressivité après 2 ans
            const percentageApplied = diffYears >= 2 ? percentageAfter2Years : percentage;
            const revenue = views * REVENUE_PER_VIEW * (percentageApplied / 100);

            return {
                episode_id: ep.episode_id,
                episode_title: ep.title,
                movie_id: movie.movie_id,
                movie_title: movie.title,
                release_date: movie.release_date,
                category,
                views,
                percentage_applied: percentageApplied,
                revenue_per_view: REVENUE_PER_VIEW,
                revenue: Math.round(revenue * 100) / 100,
                details: {
                    base_formula: `${views} x ${REVENUE_PER_VIEW} x (${percentageApplied}/100)`
                }
            };
        });

        // 5. Agrégation par film
        const filmDetails = movies.map(movie => {
            const eps = episodeDetails.filter(e => e.movie_id === movie.movie_id);
            const total_views = eps.reduce((sum, e) => sum + e.views, 0);
            const total_revenue = eps.reduce((sum, e) => sum + e.revenue, 0);
            return {
                movie_id: movie.movie_id,
                movie_title: movie.title,
                release_date: movie.release_date,
                category: eps.length > 0 ? eps[0].category : '',
                total_views,
                total_revenue: Math.round(total_revenue * 100) / 100,
                episodes: eps
            };
        });

        // 6. Totaux globaux
        const total_views = filmDetails.reduce((sum, f) => sum + f.total_views, 0);
        const total_revenue = filmDetails.reduce((sum, f) => sum + f.total_revenue, 0);

        res.json({
            success: true,
            data: {
                period: `${period} days`,
                revenue_per_view: REVENUE_PER_VIEW,
                total_views,
                total_revenue: Math.round(total_revenue * 100) / 100,
                films: filmDetails
            }
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des stats de revenus:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des statistiques',
            details: error.message
        });
    }
};
