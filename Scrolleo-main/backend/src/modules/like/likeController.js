import pool from '../../config/database.js';


export const likeMovie = async (req, res) => {
    const { user_id, movie_id } = req.body;
  
    if (!user_id || !movie_id) {
      return res.status(400).json({ message: "Champs manquants" });
    }
  
    try {
      // Insérer dans user_likes (évite les doublons avec ON CONFLICT DO NOTHING)
      const result = await pool.query(
        `INSERT INTO user_likes (user_id, movie_id)
         VALUES ($1, $2)
         ON CONFLICT DO NOTHING`,
        [user_id, movie_id]
      );
  
      // Si une ligne a été insérée (donc un vrai nouveau like)
      if (result.rowCount > 0) {
        await pool.query(
          `UPDATE movies 
           SET likes = likes + 1 
           WHERE movie_id = $1`,
          [movie_id]
        );
  
        return res.status(201).json({ message: "Film liké avec succès" });
      } else {
        // Le like existait déjà
        return res.status(200).json({ message: "Le film est déjà liké" });
      }
  
    } catch (error) {
      console.error("Erreur lors du like :", error);
      res.status(500).json({ message: "Erreur serveur" });
    }
  };
  

  export const unlikeMovie = async (req, res) => {
    const { user_id, movie_id } = req.body;
  
    if (!user_id || !movie_id) {
      return res.status(400).json({ message: "Champs manquants" });
    }
  
    try {
      // Supprimer le like de la table user_likes
      const result = await pool.query(
        `DELETE FROM user_likes
         WHERE user_id = $1 AND movie_id = $2`,
        [user_id, movie_id]
      );
  
      // Vérifie si une ligne a été supprimée
      if (result.rowCount === 0) {
        return res.status(404).json({ message: "Le like n'existe pas" });
      }
  
      // Optionnel : décrémenter le compteur de likes dans la table movies
      await pool.query(
        `UPDATE movies
         SET likes = GREATEST(likes - 1, 0) -- éviter les valeurs négatives
         WHERE movie_id = $1`,
        [movie_id]
      );
  
      res.status(200).json({ message: "Like retiré avec succès" });
    } catch (error) {
      console.error("Erreur lors du retrait du like :", error);
      res.status(500).json({ message: "Erreur serveur" });
    }
  };
  
export const getAllUserLikes = async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        user_likes.user_id, 
        users.username, 
        user_likes.movie_id, 
        movies.title
      FROM user_likes
      JOIN users ON user_likes.user_id = users.user_id
      JOIN movies ON user_likes.movie_id = movies.movie_id
    `);

    res.status(200).json({ likes: result.rows });
  } catch (error) {
    console.error("Erreur lors de la récupération des likes :", error);
    res.status(500).json({ message: "Erreur serveur" });
  }
}