
import pool from '../../config/database.js';


//ajouter un episode est favoris 

export const addOrUpdateFavorite = async (req, res) => {
  const { user_id, movie_id, episode_id } = req.body;

  try {
    // Récupérer les favoris existants pour ce film et cet utilisateur
    const { rows } = await pool.query(
      `SELECT episode_id FROM user_favorites
       WHERE user_id = $1 AND movie_id = $2
       ORDER BY added_at ASC`,
      [user_id, movie_id]
    );

    let replacedEpisode = null;

    if (rows.length >= 3) {
      replacedEpisode = rows[0].episode_id;

      // Supprimer l'épisode le plus ancien
      await pool.query(
        `DELETE FROM user_favorites
         WHERE user_id = $1 AND movie_id = $2 AND episode_id = $3`,
        [user_id, movie_id, replacedEpisode]
      );
    }

    // Ajouter le nouvel épisode en favori
    await pool.query(
      `INSERT INTO user_favorites (user_id, movie_id, episode_id, added_at)
       VALUES ($1, $2, $3, CURRENT_TIMESTAMP)`,
      [user_id, movie_id, episode_id]
    );

    res.status(200).json({
      message: replacedEpisode
        ? `Favori mis à jour. L’épisode ${replacedEpisode} a été remplacé.`
        : "Favori ajouté.",
      replaced: replacedEpisode !== null,
      replaced_episode_id: replacedEpisode
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Erreur serveur." });
  }
};




//supprimer un episode des favoris 
export const removeFavorite = async (req, res) => {
    const { user_id, episode_id } = req.params;

    try {
        await pool.query(
            `DELETE FROM user_favorites WHERE user_id = $1 AND episode_id = $2`,
            [user_id, episode_id]
        );
        res.json({ message: "Favori supprimé." });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: "Erreur serveur." });
    }
};


//recuperer tout les favoris
export const getUserFavorites = async (req, res) => {
    const { user_id } = req.params;

    try {
        const result = await pool.query(
            `SELECT 
  user_favorites.user_id,
  user_favorites.episode_id,
  movies.movie_id,
  movies.title,
  movies.description,
  movies.likes,
  movies.release_date,
  episodes.episode_number,
  episodes.season_number
FROM user_favorites
JOIN movies ON user_favorites.movie_id = movies.movie_id
JOIN episodes ON user_favorites.episode_id = episodes.episode_id
WHERE user_favorites.user_id = $1;
`,
            [user_id]
        );
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: "Erreur serveur." });
    }
};


// export const getLastWatchedEpisodePerFavoriteMovie = async (req, res) => {
//   const { user_id } = req.params;

//   try {
//     const query = `
//       SELECT user_favorites.movie_id,
//              movies.title,
//              movies.description,
//              movies.release_date,
//              episodes.episode_id,
//              episodes.episode_number,
//              episodes.season_number,
//              user_history.watched_at
//       FROM user_favorites
//       JOIN movies ON user_favorites.movie_id = movies.movie_id
//       JOIN episodes ON user_favorites.episode_id = episodes.episode_id
//       JOIN user_history ON user_history.user_id = user_favorites.user_id
//                         AND user_history.episode_id = user_favorites.episode_id
//       WHERE user_favorites.user_id = $1
//         AND user_history.watched_at = (
//           SELECT MAX(watched_at)
//           FROM user_history uh
//           JOIN user_favorites uf ON uh.episode_id = uf.episode_id
//           WHERE uh.user_id = user_favorites.user_id
//             AND uf.movie_id = user_favorites.movie_id
//         )
//       GROUP BY user_favorites.movie_id, movies.title, movies.description, movies.release_date, episodes.episode_id, episodes.episode_number, episodes.season_number, user_history.watched_at
//       ORDER BY user_favorites.movie_id;
//     `;

//     const result = await pool.query(query, [user_id]);

//     res.json(result.rows);
//   } catch (error) {
//     console.error(error);
//     res.status(500).json({ message: "Erreur serveur." });
//   }
// };
