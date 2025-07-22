
import pool from '../../config/database.js';


// recuperer les films recommander 

export const getRecommendedMovies = async (req, res) => {
  const { user_id } = req.params;

  try {
    const result = await pool.query(`
      (
        -- 1. Films populaires dans les genres aimés par l'utilisateur
        SELECT DISTINCT movies.*
        FROM user_favorites
        INNER JOIN movies AS fav_movies ON user_favorites.movie_id = fav_movies.movie_id
        INNER JOIN movies ON movies.genre = fav_movies.genre
        WHERE user_favorites.user_id = $1
          AND movies.movie_id NOT IN (
            SELECT movie_id FROM user_history WHERE user_id = $1
          )
          AND movies.movie_id NOT IN (
            SELECT movie_id FROM user_favorites WHERE user_id = $1
          )
          AND movies.release_date <= CURRENT_DATE
        ORDER BY movies.views DESC
        LIMIT 5
      )

      UNION

      (
        -- 2. Collaborative filtering simple
        SELECT DISTINCT movies.*
        FROM user_favorites
        INNER JOIN user_favorites AS others ON user_favorites.movie_id = others.movie_id
        INNER JOIN movies ON movies.movie_id = others.movie_id
        WHERE user_favorites.user_id = $1
          AND others.user_id != $1
          AND movies.movie_id NOT IN (
            SELECT movie_id FROM user_favorites WHERE user_id = $1
          )
          AND movies.movie_id NOT IN (
            SELECT movie_id FROM user_history WHERE user_id = $1
          )
          AND movies.release_date <= CURRENT_DATE
        LIMIT 5
      )

      UNION

      (
        -- 3. Films du même réalisateur que ceux aimés par l'utilisateur
        SELECT DISTINCT movies.*
        FROM user_favorites
        INNER JOIN movies AS fav_movies ON user_favorites.movie_id = fav_movies.movie_id
        INNER JOIN movies ON movies.director_id = fav_movies.director_id
        WHERE user_favorites.user_id = $1
          AND movies.movie_id NOT IN (
            SELECT movie_id FROM user_favorites WHERE user_id = $1
          )
          AND movies.movie_id NOT IN (
            SELECT movie_id FROM user_history WHERE user_id = $1
          )
          AND movies.release_date <= CURRENT_DATE
        LIMIT 5
      )
    `, [user_id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Aucune recommandation trouvée pour cet utilisateur.' });
    }

    res.status(200).json(result.rows);
  } catch (error) {
    console.error('Erreur lors de la récupération des recommandations combinées :', error);
    res.status(500).json({ error: 'Erreur serveur', details: error.message });
  }
};
