import pool from '../../config/database.js';

export const addEpisodeView = async (req, res) => {
  const { user_id, episode_id, movie_id } = req.body;

  try {
    // Vérifier d'abord si l'utilisateur existe
    const userCheck = await pool.query(
      'SELECT 1 FROM users WHERE user_id = $1',
      [user_id]
    );

    if (userCheck.rowCount === 0) {
      return res.status(404).json({ message: "Utilisateur non trouvé" });
    }

    // Vérifier si l'utilisateur a déjà vu l'épisode
    const check = await pool.query(
      `SELECT 1 FROM episode_views WHERE user_id = $1 AND episode_id = $2`,
      [user_id, episode_id]
    );

    if (check.rowCount === 0) {
      // Ajouter une nouvelle vue avec movie_id
      await pool.query(
        `INSERT INTO episode_views (user_id, episode_id, movie_id) VALUES ($1, $2, $3)`,
        [user_id, episode_id, movie_id]
      );

      // Incrémenter le compteur global dans episodes
      await pool.query(
        `UPDATE episodes SET views = views + 1 WHERE episode_id = $1`,
        [episode_id]
      );
    }

    res.status(200).json({ message: "Vue comptabilisée (si nouvelle)" });
  } catch (error) {
    console.error(error);
    if (error.code === '23503') {
      return res.status(400).json({ message: "Données invalides : utilisateur ou épisode non trouvé" });
    }
    res.status(500).json({ message: "Erreur serveur" });
  }
};

  

  export const addMovieView = async (req, res) => {
    const { user_id, movie_id } = req.body;
  
    try {
      // Vérifie si la vue a déjà été comptabilisée
      const alreadyViewed = await pool.query(
        `SELECT 1 FROM movie_views WHERE user_id = $1 AND movie_id = $2`,
        [user_id, movie_id]
      );
  
      if (alreadyViewed.rowCount > 0) {
        return res.status(200).json({ message: "Vue déjà comptabilisée pour ce film." });
      }
  
      // Total d'épisodes
      const totalResult = await pool.query(
        `SELECT COUNT(*) FROM episodes WHERE movie_id = $1`,
        [movie_id]
      );
      const totalEpisodes = parseInt(totalResult.rows[0].count);
  
      if (totalEpisodes === 0) {
        return res.status(400).json({ message: "Ce film n'a pas d'épisodes." });
      }
  
      // Épisodes vus
      const watchedResult = await pool.query(
        `SELECT COUNT(DISTINCT episode_id) FROM episode_views WHERE movie_id = $1 AND user_id = $2`,
        [movie_id, user_id]
      );
      const watchedCount = parseInt(watchedResult.rows[0].count);
  
      // 75 % ?
      if (watchedCount >= 0.75 * totalEpisodes) {
        await pool.query(
          `UPDATE movies SET views = views + 1 WHERE movie_id = $1`,
          [movie_id]
        );
  
        // Marque la vue comme comptée
        await pool.query(
          `INSERT INTO movie_views (user_id, movie_id) VALUES ($1, $2)`,
          [user_id, movie_id]
        );
  
        return res.status(200).json({ message: "Vue du film ajoutée." });
      } else {
        return res.status(200).json({
          message: "L'utilisateur n'a pas encore regardé suffisamment d'épisodes.",
        });
      }
    } catch (err) {
      console.error(err);
      res.status(500).json({ message: "Erreur serveur." });
    }
  };
  

  export const getAllEpisodeViews = async (req, res) => {
  try {
    const { rows } = await pool.query(`
      SELECT 
        episode_views.user_id,
        episode_views.episode_id,
        episode_views.movie_id
      FROM episode_views
    `);

    res.status(200).json(rows);
  } catch (error) {
    console.error("Erreur lors de la récupération des vues :", error);
    res.status(500).json({ message: "Erreur serveur" });
  }
};



export const getAllMovieViews = async (req, res) => {
  try {
    const { rows } = await pool.query(`
      SELECT *
      FROM movie_views
    `);

    res.status(200).json(rows);
  } catch (error) {
    console.error("Erreur lors de la récupération des vues :", error);
    res.status(500).json({ message: "Erreur serveur" });
  }
};

export const updateEpisodeView = async (req, res) => {
  const { user_id, episode_id, new_movie_id } = req.body;

  try {
    const result = await pool.query(
      `UPDATE episode_views
       SET movie_id = $1
       WHERE user_id = $2 AND episode_id = $3`,
      [new_movie_id, user_id, episode_id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ message: "Aucune vue trouvée à mettre à jour" });
    }

    res.status(200).json({ message: "Mise à jour réussie" });
  } catch (error) {
    console.error("Erreur lors de la mise à jour :", error);
    res.status(500).json({ message: "Erreur serveur" });
  }
};