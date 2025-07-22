import pool from '../../config/database.js';


//mettre a jour l'historique
export const updateWatchHistory = async (req, res) => {
    const { user_id, episode_id, movie_id, last_position } = req.body;

    try {
        const result = await pool.query(
            `INSERT INTO user_history (user_id, episode_id, movie_id, last_position)
             VALUES ($1, $2, $3, $4)
             ON CONFLICT (user_id, episode_id)
             DO UPDATE SET 
                watched_at = CURRENT_TIMESTAMP,
                last_position = EXCLUDED.last_position`,
            [user_id, episode_id, movie_id, last_position]
        );

        res.status(200).json({ message: 'Historique mis à jour' });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Erreur lors de la mise à jour de l’historique' });
    }
};


// Récupérer l'historique d'un utilisateur avec les infos des films

export const getUserHistory = async (req, res) => {
  const { user_id } = req.params;

  try {
    const result = await pool.query(`
      SELECT
        user_history.movie_id,
        user_history.episode_id,
        user_history.watched_at,
        episodes.episode_number,
        episodes.season_number,
        episodes.title,
        movies.cover_image
      FROM user_history
      JOIN episodes ON user_history.episode_id = episodes.episode_id
      JOIN movies ON user_history.movie_id = movies.movie_id
      WHERE user_history.user_id = $1
        AND user_history.watched_at IS NOT NULL
        AND user_history.watched_at = (
          SELECT MAX(sub_history.watched_at)
          FROM user_history AS sub_history
          WHERE sub_history.user_id = user_history.user_id
            AND sub_history.movie_id = user_history.movie_id
        )
      ORDER BY user_history.watched_at DESC
    `, [user_id]);

    res.status(200).json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Erreur lors de la récupération de l'historique" });
  }
};