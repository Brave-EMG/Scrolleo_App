export const getShareableLink = async (req, res) => {
  const { episode_id } = req.params;

  try {
    // Vérifier si l'épisode existe (optionnel mais recommandé)
    const result = await pool.query(
      `SELECT * FROM episodes WHERE episode_id = $1`,
      [episode_id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ message: "Épisode non trouvé." });
    }

    // Construire le lien partageable
    const shareableUrl = `https://tonsite.com/episodes/${episode_id}`;

    res.status(200).json({ shareableUrl });
  } catch (error) {
    console.error("Erreur lors de la génération du lien :", error);
    res.status(500).json({ message: "Erreur serveur." });
  }
};
