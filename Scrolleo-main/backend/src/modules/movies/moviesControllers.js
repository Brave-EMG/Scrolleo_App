import multer from 'multer';
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import pool from '../../config/database.js';
import { uploadFileToS3 } from './moviesMiddleware.js';


const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Configuration de Multer pour gérer les téléchargements de fichiers
// const storage = multer.diskStorage({
//     destination: (req, file, cb) => {
//         cb(null, path.join(__dirname, '../../../uploads/'));
//     },
//     filename: (req, file, cb) => {
//         cb(null, Date.now() + '-' + file.originalname);
//     }
// });

// export const upload = multer({ storage });


// Controller : Créer un film
export async function createMovie(req, res) {
  try {
    // Upload de l'image si présente
    const fileUrl = req.file ? await uploadFileToS3(req.file) : null;

    // Données du film depuis le formulaire
    const {
      title,
      genre,
      description,
      release_date,
      director_id,
      episodes_count,
      season,
      status,
    } = req.body;

    const query = `
      INSERT INTO movies (
        title, genre, description, release_date, cover_image,
        director_id, episodes_count, season, status
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *;
    `;

    const values = [
      title,
      genre,
      description,
      release_date,
      fileUrl,
      director_id,
      episodes_count || 0,
      season || 1,
      status || 'NoExclusive'
    ];

    const { rows } = await pool.query(query, values);

    res.status(201).json({ message: 'Film créé avec succès', movie: rows[0] });
  } catch (error) {
    console.error('Erreur lors de la création du film :', error);
    res.status(500).json({ message: 'Erreur serveur lors de la création du film' });
  }
};



// Récupérer tous les films
export const getAllMovies = async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM movies ');

        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur du serveur' });
    }
};



// Mettre à jour un film

export const updateMovie = async (req, res) => {
    const { id } = req.params;
    const { title, genre, description, release_date, season, episodes_count } = req.body;

    // Vérifier si le fichier a été téléchargé
    const cover_image = req.file ? `/uploads/${req.file.filename}` : null;

    try {
        const result = await pool.query('SELECT * FROM movies WHERE movie_id = $1', [id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Film non trouvé' });
        }

        const updateQuery = `
          UPDATE movies 
          SET title = $1, genre = $2, description = $3, release_date = $4, cover_image = COALESCE($5, cover_image), season = $6, episodes_count = $7, updated_at = CURRENT_TIMESTAMP
          WHERE movie_id = $8
          RETURNING *;
        `;
        const updateResult = await pool.query(updateQuery, [
            title,
            genre,
            description,
            release_date,
            cover_image,
            season,
            episodes_count,
            id
        ]);

        res.json({ message: 'Film mis à jour', movie: updateResult.rows[0] });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur du serveur' });
    }
};


// Supprimer un film

export const deleteMovie = async (req, res) => {
    const { id } = req.params;
    try {
        const result = await pool.query('SELECT * FROM movies WHERE movie_id = $1', [id]);
        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Film non trouvé' });
        }
        const deleteResult = await pool.query('DELETE FROM movies WHERE movie_id = $1 RETURNING *', [id]);

        res.json({ message: 'Film supprimé', movie: deleteResult.rows[0] });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur du serveur' });
    }
};




// Récupérer un film par ID
export const getMovieById = async (req, res) => {
    const { id } = req.params;

    try {
        const result = await pool.query('SELECT * FROM movies WHERE movie_id = $1', [id]);

        if (result.rows.length === 0) {
            return res.status(200).json({
                message: 'Aucun film trouvé',
                data: []
            });
        }

        return res.status(200).json({
            message: 'Film trouvé',
            data: result.rows[0]
        });
    } catch (error) {
        console.error(error);
        return res.status(500).json({
            message: 'Erreur du serveur',
            data: null
        });
    }
};



// Récupérer les films par ID du réalisateur
export const getMoviesByDirector = async (req, res) => {
    const { director_id } = req.params;
    try {
        const result = await pool.query(
            'SELECT * FROM movies WHERE director_id = $1',
            [director_id]
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur du serveur' });
    }
};



// Récupérer les films par genre
export const getMoviesByGenre = async (req, res) => {
  const { genre } = req.params;
  const { user_id } = req.query; // ID de l'utilisateur connecté

  try {
    const result = await pool.query(
      `SELECT 
         movies.*, 
         users.username AS realisateur, 
         CASE 
           WHEN user_favorites.movie_id IS NOT NULL THEN true 
           ELSE false 
         END AS liked
       FROM movies
       JOIN users ON movies.director_id = users.user_id
       LEFT JOIN user_favorites 
         ON movies.movie_id = user_favorites.movie_id AND user_favorites.user_id = $2
       WHERE movies.release_date <= CURRENT_DATE 
         AND movies.genre ILIKE $1`,
      [`%${genre}%`, user_id]
    );

    if (result.rows.length === 0) {
      return res.status(200).json({
        message: 'Aucun film trouvé',
        data: []
      });
    }

    return res.status(200).json({
      message: 'Films trouvés',
      data: result.rows
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des films par genre:', error);
    return res.status(500).json({
      message: 'Erreur du serveur',
      data: null
    });
  }
};


  
//recuperer les films qui sortent dans 2semaine
export const getUpcomingMovies = async (req, res) => {
  const user_id = req.query.user_id;

  try {
    const result = await pool.query(
      `SELECT movies.*, users.username AS realisateur,
          CASE WHEN user_favorites.movie_id IS NOT NULL THEN true ELSE false END AS liked
       FROM movies
       JOIN users ON movies.director_id = users.user_id
       LEFT JOIN user_favorites 
         ON movies.movie_id = user_favorites.movie_id AND user_favorites.user_id = $1
       WHERE movies.release_date BETWEEN CURRENT_DATE + INTERVAL '1 day' AND CURRENT_DATE + INTERVAL '14 days'
       ORDER BY movies.release_date ASC;`,
      [user_id]
    );

    if (result.rows.length === 0) {
      return res.status(200).json({
        message: 'Aucun film à venir trouvé',
        data: []
      });
    }

    return res.status(200).json({
      message: 'Films à venir trouvés',
      data: result.rows
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des films à venir:', error);
    return res.status(500).json({
      message: 'Erreur du serveur',
      data: null
    });
  }
};



//recupere les films qui sont sortit il y a deux jours
export const getNewMovies = async (req, res) => {
  const user_id = req.query.user_id;

  try {
    const result = await pool.query(
      `SELECT movies.*, users.username AS realisateur,
          CASE WHEN user_favorites.movie_id IS NOT NULL THEN true ELSE false END AS liked
       FROM movies
       JOIN users ON movies.director_id = users.user_id
       LEFT JOIN user_favorites 
         ON movies.movie_id = user_favorites.movie_id AND user_favorites.user_id = $1
       WHERE release_date BETWEEN CURRENT_DATE - INTERVAL '30 days' AND CURRENT_DATE - INTERVAL '1 day'
       ORDER BY release_date DESC 
       LIMIT 10;`,
      [user_id]
    );

    if (result.rows.length === 0) {
      return res.status(200).json({
        message: 'Aucun nouveau film trouvé',
        data: []
      });
    }

    return res.status(200).json({
      message: 'Nouveaux films récupérés avec succès',
      data: result.rows
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des nouveaux films:', error);
    return res.status(500).json({
      message: 'Erreur du serveur',
      data: null
    });
  }
};



//recupere les films les plus liker
export const getMostLikedMovies = async (req, res) => {
  const user_id = req.query.user_id;

  try {
    const result = await pool.query(
      `SELECT movies.*, users.username AS realisateur,
              CASE WHEN user_favorites.movie_id IS NOT NULL THEN true ELSE false END AS liked
       FROM movies
       JOIN users ON movies.director_id = users.user_id
       LEFT JOIN user_favorites 
         ON movies.movie_id = user_favorites.movie_id AND user_favorites.user_id = $1
       WHERE movies.release_date <= CURRENT_DATE
       ORDER BY movies.likes DESC
       LIMIT 10`,
      [user_id]
    );

    if (result.rows.length === 0) {
      return res.status(200).json({
        message: 'Aucun film trouvé',
        data: []
      });
    }

    return res.status(200).json({
      message: 'Films les plus aimés récupérés avec succès',
      data: result.rows
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des films les plus aimés:', error);
    return res.status(500).json({
      message: 'Erreur serveur',
      data: null
    });
  }
};




// recuper les film les plus vue 
export const getMostViewedMovies = async (req, res) => {
  const user_id = req.query.user_id;

  try {
    const result = await pool.query(
      `SELECT movies.*, users.username AS realisateur,
              CASE WHEN user_favorites.movie_id IS NOT NULL THEN true ELSE false END AS liked
       FROM movies
       JOIN users ON movies.director_id = users.user_id
       LEFT JOIN user_favorites 
         ON movies.movie_id = user_favorites.movie_id AND user_favorites.user_id = $1
       WHERE movies.release_date <= CURRENT_DATE
       ORDER BY movies.views DESC
       LIMIT 10`,
      [user_id]
    );

    if (result.rows.length === 0) {
      return res.status(200).json({
        message: 'Aucun film trouvé',
        data: []
      });
    }

    return res.status(200).json({
      message: 'Films les plus vus récupérés avec succès',
      data: result.rows
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des films les plus vus:', error);
    return res.status(500).json({
      message: 'Erreur serveur',
      data: null
    });
  }
};




// recuperer les films tendances
export const getTrendingAndTopMovies = async (req, res) => {
  const user_id = req.query.user_id;

  try {
    const trendingQuery = `
      SELECT 
        movies.*,
        users.username,
        COUNT(DISTINCT all_favs.user_id) AS likes_count,
        CASE WHEN user_likes.user_id IS NOT NULL THEN true ELSE false END AS liked,
        (
          (COUNT(DISTINCT all_favs.user_id)::float / NULLIF(MAX(COUNT(DISTINCT all_favs.user_id)) OVER (), 0)) * 50 +
          (movies.views::float / NULLIF(MAX(movies.views) OVER (), 0)) * 30 +
          (movies.likes::float / NULLIF(MAX(movies.likes) OVER (), 0)) * 20
        ) AS rating
      FROM movies
      JOIN users ON movies.director_id = users.user_id
      LEFT JOIN user_favorites AS all_favs ON movies.movie_id = all_favs.movie_id
      LEFT JOIN user_favorites AS user_likes ON movies.movie_id = user_likes.movie_id AND user_likes.user_id = $1
      WHERE movies.release_date <= CURRENT_DATE
      GROUP BY movies.movie_id, users.username, user_likes.user_id
      ORDER BY rating DESC
      LIMIT 4;
    `;

    const mostViewedQuery = `
      SELECT 
        movies.*, 
        users.username,
        COUNT(DISTINCT all_favs.user_id) AS likes_count,
        CASE WHEN user_likes.user_id IS NOT NULL THEN true ELSE false END AS liked
      FROM movies
      JOIN users ON movies.director_id = users.user_id
      LEFT JOIN user_favorites AS all_favs ON movies.movie_id = all_favs.movie_id
      LEFT JOIN user_favorites AS user_likes ON movies.movie_id = user_likes.movie_id AND user_likes.user_id = $1
      WHERE movies.release_date <= CURRENT_DATE
      GROUP BY movies.movie_id, users.username, user_likes.user_id
      ORDER BY views DESC
      LIMIT 4;
    `;

    const mostLikedQuery = `
      SELECT 
        movies.*, 
        users.username,
        COUNT(DISTINCT all_favs.user_id) AS likes_count,
        CASE WHEN user_likes.user_id IS NOT NULL THEN true ELSE false END AS liked
      FROM movies
      JOIN users ON movies.director_id = users.user_id
      LEFT JOIN user_favorites AS all_favs ON movies.movie_id = all_favs.movie_id
      LEFT JOIN user_favorites AS user_likes ON movies.movie_id = user_likes.movie_id AND user_likes.user_id = $1
      WHERE movies.release_date <= CURRENT_DATE
      GROUP BY movies.movie_id, users.username, user_likes.user_id
      ORDER BY likes_count DESC
      LIMIT 4;
    `;

    const [trendingResult, mostViewedResult, mostLikedResult] = await Promise.all([
      pool.query(trendingQuery, [user_id]),
      pool.query(mostViewedQuery, [user_id]),
      pool.query(mostLikedQuery, [user_id]),
    ]);

    res.status(200).json({
      trending: trendingResult.rows,
      mostViewed: mostViewedResult.rows,
      mostLiked: mostLikedResult.rows,
    });

  } catch (error) {
    console.error('Erreur lors de la récupération des films :', error);
    res.status(500).json({
      message: 'Erreur du serveur',
      details: error.message
    });
  }
};

  
  
  //recuperer les films decouvertes
  export const getDiscoveryMovies = async (req, res) => {
    const user_id = req.query.user_id;
  
    try {
      const [randomMovies, hiddenGems, recentLowViews] = await Promise.all([
        pool.query(`
          SELECT 
            movies.*, 
            users.username AS realisateur,
            COUNT(DISTINCT favs.user_id) AS likes_count,
            CASE WHEN user_likes.user_id IS NOT NULL THEN true ELSE false END AS liked
          FROM movies
          JOIN users ON movies.director_id = users.user_id
          LEFT JOIN user_favorites favs ON movies.movie_id = favs.movie_id
          LEFT JOIN user_favorites user_likes ON movies.movie_id = user_likes.movie_id AND user_likes.user_id = $1
          WHERE movies.release_date <= CURRENT_DATE
          GROUP BY movies.movie_id, users.username, user_likes.user_id
          ORDER BY RANDOM()
          LIMIT 3
        `, [user_id]),
  
        pool.query(`
          SELECT 
            movies.*, 
            users.username AS realisateur,
            COUNT(DISTINCT favs.user_id) AS likes_count,
            CASE WHEN user_likes.user_id IS NOT NULL THEN true ELSE false END AS liked
          FROM movies
          JOIN users ON movies.director_id = users.user_id
          LEFT JOIN user_favorites favs ON movies.movie_id = favs.movie_id
          LEFT JOIN user_favorites user_likes ON movies.movie_id = user_likes.movie_id AND user_likes.user_id = $1
          WHERE movies.release_date <= CURRENT_DATE AND movies.views < 1000
          GROUP BY movies.movie_id, users.username, user_likes.user_id
          ORDER BY likes_count DESC
          LIMIT 3
        `, [user_id]),
  
        pool.query(`
          SELECT 
            movies.*, 
            users.username AS realisateur,
            COUNT(DISTINCT favs.user_id) AS likes_count,
            CASE WHEN user_likes.user_id IS NOT NULL THEN true ELSE false END AS liked
          FROM movies
          JOIN users ON movies.director_id = users.user_id
          LEFT JOIN user_favorites favs ON movies.movie_id = favs.movie_id
          LEFT JOIN user_favorites user_likes ON movies.movie_id = user_likes.movie_id AND user_likes.user_id = $1
          WHERE movies.release_date <= CURRENT_DATE AND movies.views < 500
          GROUP BY movies.movie_id, users.username, user_likes.user_id
          ORDER BY movies.created_at DESC
          LIMIT 3
        `, [user_id]),
      ]);
  
      const discovery = [
        ...randomMovies.rows,
        ...hiddenGems.rows,
        ...recentLowViews.rows,
      ];
  
      res.status(200).json({
        success: true,
        total: discovery.length,
        discovery
      });
  
    } catch (error) {
      console.error('Erreur lors de la récupération des films en découverte:', error);
      res.status(500).json({ message: 'Erreur du serveur', details: error.message });
    }
  };
  

//films recommander 
export const getRecommendedMovies = async (req, res) => {
  const user_id = req.query.user_id;

  try {
    let recommendedMap = new Map();

    const addUnique = (movies) => {
      for (const movie of movies) {
        if (!recommendedMap.has(movie.movie_id)) {
          recommendedMap.set(movie.movie_id, movie);
        }
      }
    };

    // a. Par GENRE aimé
    const likedGenresRes = await pool.query(`
      SELECT DISTINCT genre
      FROM movies
      JOIN user_favorites ON movies.movie_id = user_favorites.movie_id
      WHERE user_favorites.user_id = $1
    `, [user_id]);

    if (likedGenresRes.rows.length > 0) {
      const genres = likedGenresRes.rows.map(row => row.genre);
      const placeholders = genres.map((_, i) => `$${i + 2}`).join(',');

      const genreMovies = await pool.query(`
        SELECT movies.movie_id, movies.title, movies.genre, movies.description, movies.release_date,
               movies.cover_image, movies.director_id, movies.episodes_count, movies.created_at,
               movies.updated_at, movies.views, movies.likes, movies.status, movies.season,
               users.username AS realisateur,
               CASE WHEN user_favorites.movie_id IS NOT NULL THEN true ELSE false END AS liked
        FROM movies
        JOIN users ON movies.director_id = users.user_id
        LEFT JOIN user_favorites 
          ON movies.movie_id = user_favorites.movie_id AND user_favorites.user_id = $1
        WHERE movies.genre IN (${placeholders})
          AND movies.movie_id NOT IN (
            SELECT movie_id FROM user_favorites WHERE user_id = $1
          )
        GROUP BY movies.movie_id, users.username, user_favorites.movie_id,
                 movies.title, movies.genre, movies.description, movies.release_date,
                 movies.cover_image, movies.director_id, movies.episodes_count, movies.created_at,
                 movies.updated_at, movies.views, movies.likes, movies.status, movies.season
        LIMIT 10
      `, [user_id, ...genres]);

      addUnique(genreMovies.rows);
    }

    // b. Par réalisateur aimé
    if (recommendedMap.size < 15) {
      const likedDirectorsRes = await pool.query(`
        SELECT DISTINCT director_id
        FROM movies
        JOIN user_favorites ON movies.movie_id = user_favorites.movie_id
        WHERE user_favorites.user_id = $1
      `, [user_id]);

      const directors = likedDirectorsRes.rows.map(row => row.director_id);
      if (directors.length > 0) {
        const placeholders = directors.map((_, i) => `$${i + 2}`).join(',');

        const directorMovies = await pool.query(`
          SELECT movies.movie_id, movies.title, movies.genre, movies.description, movies.release_date,
                 movies.cover_image, movies.director_id, movies.episodes_count, movies.created_at,
                 movies.updated_at, movies.views, movies.likes, movies.status, movies.season,
                 users.username AS realisateur,
                 CASE WHEN user_favorites.movie_id IS NOT NULL THEN true ELSE false END AS liked
          FROM movies
          JOIN users ON movies.director_id = users.user_id
          LEFT JOIN user_favorites 
            ON movies.movie_id = user_favorites.movie_id AND user_favorites.user_id = $1
          WHERE movies.director_id IN (${placeholders})
            AND movies.movie_id NOT IN (
              SELECT movie_id FROM user_favorites WHERE user_id = $1
            )
          GROUP BY movies.movie_id, users.username, user_favorites.movie_id,
                   movies.title, movies.genre, movies.description, movies.release_date,
                   movies.cover_image, movies.director_id, movies.episodes_count, movies.created_at,
                   movies.updated_at, movies.views, movies.likes, movies.status, movies.season
          LIMIT 10
        `, [user_id, ...directors]);

        addUnique(directorMovies.rows);
      }
    }

    // c. Utilisateurs similaires
    if (recommendedMap.size < 15) {
      const similarUsersMovies = await pool.query(`
        SELECT m.movie_id, m.title, m.genre, m.description, m.release_date,
               m.cover_image, m.director_id, m.episodes_count, m.created_at,
               m.updated_at, m.views, m.likes, m.status, m.season,
               u.username AS realisateur,
               CASE WHEN uf2.movie_id IS NOT NULL THEN true ELSE false END AS liked
        FROM user_favorites uf1
        JOIN user_favorites uf2 ON uf1.movie_id = uf2.movie_id AND uf1.user_id != uf2.user_id
        JOIN movies m ON uf2.movie_id = m.movie_id
        JOIN users u ON m.director_id = u.user_id
        LEFT JOIN user_favorites uf ON uf.movie_id = m.movie_id AND uf.user_id = $1
        WHERE uf1.user_id = $1
          AND m.movie_id NOT IN (
            SELECT movie_id FROM user_favorites WHERE user_id = $1
          )
        GROUP BY m.movie_id, u.username, uf2.movie_id,
                 m.title, m.genre, m.description, m.release_date,
                 m.cover_image, m.director_id, m.episodes_count, m.created_at,
                 m.updated_at, m.views, m.likes, m.status, m.season
        ORDER BY m.likes DESC
        LIMIT 10
      `, [user_id]);

      addUnique(similarUsersMovies.rows);
    }

    // d. Historique de visionnage corrigé
    if (recommendedMap.size < 15) {
      const recentGenresRes = await pool.query(`
        SELECT m.genre, MAX(h.watched_at) AS last_watched_at
        FROM user_history h
        JOIN movies m ON h.movie_id = m.movie_id
        WHERE h.user_id = $1
        GROUP BY m.genre
        ORDER BY last_watched_at DESC
        LIMIT 20
      `, [user_id]);

      const genres = recentGenresRes.rows.map(row => row.genre);
      if (genres.length > 0) {
        const placeholders = genres.map((_, i) => `$${i + 2}`).join(',');

        const recentGenreMovies = await pool.query(`
          SELECT movies.movie_id, movies.title, movies.genre, movies.description, movies.release_date,
                 movies.cover_image, movies.director_id, movies.episodes_count, movies.created_at,
                 movies.updated_at, movies.views, movies.likes, movies.status, movies.season,
                 users.username AS realisateur,
                 CASE WHEN user_favorites.movie_id IS NOT NULL THEN true ELSE false END AS liked
          FROM movies
          JOIN users ON movies.director_id = users.user_id
          LEFT JOIN user_favorites 
            ON movies.movie_id = user_favorites.movie_id AND user_favorites.user_id = $1
          WHERE movies.genre IN (${placeholders})
            AND movies.movie_id NOT IN (
              SELECT movie_id FROM user_favorites WHERE user_id = $1
            )
          GROUP BY movies.movie_id, users.username, user_favorites.movie_id,
                   movies.title, movies.genre, movies.description, movies.release_date,
                   movies.cover_image, movies.director_id, movies.episodes_count, movies.created_at,
                   movies.updated_at, movies.views, movies.likes, movies.status, movies.season
          LIMIT 10
        `, [user_id, ...genres]);

        addUnique(recentGenreMovies.rows);
      }
    }

    // e. Fallback : compléter avec des films populaires (sans vérification du statut)
if (recommendedMap.size < 15) {
  const needed = 15 - recommendedMap.size;

  const fallbackResult = await pool.query(`
    SELECT movies.movie_id, movies.title, movies.genre, movies.description, movies.release_date,
           movies.cover_image, movies.director_id, movies.episodes_count, movies.created_at,
           movies.updated_at, movies.views, movies.likes, movies.status, movies.season,
           users.username AS realisateur,
           CASE WHEN user_favorites.movie_id IS NOT NULL THEN true ELSE false END AS liked
    FROM movies
    JOIN users ON movies.director_id = users.user_id
    LEFT JOIN user_favorites ON movies.movie_id = user_favorites.movie_id AND user_favorites.user_id = $1
    WHERE movies.movie_id NOT IN (
      SELECT movie_id FROM user_favorites WHERE user_id = $1
    )
    GROUP BY movies.movie_id, users.username, user_favorites.movie_id,
             movies.title, movies.genre, movies.description, movies.release_date,
             movies.cover_image, movies.director_id, movies.episodes_count, movies.created_at,
             movies.updated_at, movies.views, movies.likes, movies.status, movies.season
    ORDER BY movies.likes DESC, movies.views DESC
    LIMIT $2
  `, [user_id, needed]);

  addUnique(fallbackResult.rows);
}


    const recommended = Array.from(recommendedMap.values()).slice(0, 15);
    res.status(200).json(recommended);
  } catch (error) {
    console.error("Erreur lors des recommandations :", error);
    res.status(500).json({ message: "Erreur serveur" });
  }
};



//recupere les films qui sont sortit il y a moins de deux ans

export const getMoviesYoungerThan2Years = async (req, res) => {
  const user_id = req.query.user_id;

  try {
    const result = await pool.query(
      `SELECT movies.*, users.username AS realisateur,
          CASE WHEN user_favorites.movie_id IS NOT NULL THEN true ELSE false END AS liked
       FROM movies
       JOIN users ON movies.director_id = users.user_id
       LEFT JOIN user_favorites 
         ON movies.movie_id = user_favorites.movie_id AND user_favorites.user_id = $1
       WHERE release_date >= CURRENT_DATE - INTERVAL '2 years'
       ORDER BY release_date DESC
       LIMIT 40;`,
      [user_id]
    );

    return res.status(200).json({
      message: 'Films de moins de 2 ans récupérés avec succès',
      data: result.rows
    });
  } catch (error) {
    console.error('Erreur récupération films < 2 ans:', error);
    return res.status(500).json({ message: 'Erreur serveur', data: null });
  }
};



//recupere les films qui sont sortit il y a de 2ans a 5ans

export const getMoviesBetween2And5Years = async (req, res) => {
  const user_id = req.query.user_id;

  try {
    const result = await pool.query(
      `SELECT movies.*, users.username AS realisateur,
          CASE WHEN user_favorites.movie_id IS NOT NULL THEN true ELSE false END AS liked
       FROM movies
       JOIN users ON movies.director_id = users.user_id
       LEFT JOIN user_favorites 
         ON movies.movie_id = user_favorites.movie_id AND user_favorites.user_id = $1
       WHERE release_date BETWEEN CURRENT_DATE - INTERVAL '5 years' AND CURRENT_DATE - INTERVAL '2 years'
       ORDER BY release_date DESC
       LIMIT 40;`,
      [user_id]
    );

    return res.status(200).json({
      message: 'Films entre 2 et 5 ans récupérés avec succès',
      data: result.rows
    });
  } catch (error) {
    console.error('Erreur récupération films 2-5 ans:', error);
    return res.status(500).json({ message: 'Erreur serveur', data: null });
  }
};



//recupere les films qui sont sortit il y a de 5ans a 20ans

export const getMoviesBetween5And20Years = async (req, res) => {
  const user_id = req.query.user_id;

  try {
    const result = await pool.query(
      `SELECT movies.*, users.username AS realisateur,
          CASE WHEN user_favorites.movie_id IS NOT NULL THEN true ELSE false END AS liked
       FROM movies
       JOIN users ON movies.director_id = users.user_id
       LEFT JOIN user_favorites 
         ON movies.movie_id = user_favorites.movie_id AND user_favorites.user_id = $1
       WHERE release_date BETWEEN CURRENT_DATE - INTERVAL '20 years' AND CURRENT_DATE - INTERVAL '5 years'
       ORDER BY release_date DESC
       LIMIT 40;`,
      [user_id]
    );

    return res.status(200).json({
      message: 'Films entre 5 et 20 ans récupérés avec succès',
      data: result.rows
    });
  } catch (error) {
    console.error('Erreur récupération films 5-20 ans:', error);
    return res.status(500).json({ message: 'Erreur serveur', data: null });
  }
};



// Cette fonction récupère les films réalisés par un (director_id) et sortis il y a moins de 2 ans .

export const getDirectorMoviesYoungerThan2Years = async (req, res) => {
  const { director_id } = req.query;

  try {
    const result = await pool.query(
      `SELECT movies.*, users.username AS realisateur
       FROM movies
       JOIN users ON movies.director_id = users.user_id
       WHERE movies.director_id = $1
         AND release_date >= CURRENT_DATE - INTERVAL '2 years'
       ORDER BY release_date DESC
       LIMIT 20;`,
      [director_id]
    );

    return res.status(200).json({
      message: 'Films récents du réalisateur récupérés avec succès',
      data: result.rows
    });
  } catch (error) {
    console.error('Erreur récupération films < 2 ans:', error);
    return res.status(500).json({ message: 'Erreur serveur', data: null });
  }
};



// Cette fonction récupère les films réalisés par un réalisateur (director_id) et sortis entre 2 et 5 ans en arrière.

export const getDirectorMoviesBetween2And5Years = async (req, res) => {
  const { director_id } = req.query;

  try {
    const result = await pool.query(
      `SELECT movies.*, users.username AS realisateur
       FROM movies
       JOIN users ON movies.director_id = users.user_id
       WHERE movies.director_id = $1
         AND release_date BETWEEN CURRENT_DATE - INTERVAL '5 years' AND CURRENT_DATE - INTERVAL '2 years'
       ORDER BY release_date DESC
       LIMIT 20;`,
      [director_id]
    );

    return res.status(200).json({
      message: 'Films du réalisateur (2 à 5 ans) récupérés avec succès',
      data: result.rows
    });
  } catch (error) {
    console.error('Erreur récupération films 2-5 ans:', error);
    return res.status(500).json({ message: 'Erreur serveur', data: null });
  }
};



// Cette fonction récupère les films réalisés par un réalisateur (director_id) et sortis entre 5 et 20 ans en arrière.
export const getDirectorMoviesBetween5And20Years = async (req, res) => {
  const { director_id } = req.query;

  try {
    const result = await pool.query(
      `SELECT movies.*, users.username AS realisateur
       FROM movies
       JOIN users ON movies.director_id = users.user_id
       WHERE movies.director_id = $1
         AND release_date BETWEEN CURRENT_DATE - INTERVAL '20 years' AND CURRENT_DATE - INTERVAL '5 years'
       ORDER BY release_date DESC
       LIMIT 20;`,
      [director_id]
    );

    return res.status(200).json({
      message: 'Films du réalisateur (5 à 20 ans) récupérés avec succès',
      data: result.rows
    });
  } catch (error) {
    console.error('Erreur récupération films 5-20 ans:', error);
    return res.status(500).json({ message: 'Erreur serveur', data: null });
  }
};


 
// Récupérer les films rejeter 
export const getExclusiveMovies = async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT 
              movies.*, 
              users.username AS director_username
            FROM movies
            JOIN users ON movies.director_id = users.user_id
            WHERE movies.status = 'Exclusive'
          `);
        if (result.rows.length > 0) {
            res.json(result.rows);
        } else {
            res.status(404).json({ message: 'Aucun film trouvé' });
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur du serveur' });
    }
  };



//reuperer tout les films valider
// export const getapprovedMovies = async (req, res) => {
//   try {
//       const result = await pool.query(`
//           SELECT 
//             movies.*, 
//             users.username AS director_username
//           FROM movies
//           JOIN users ON movies.director_id = users.user_id
//           WHERE movies.status = 'approved'
//         `);
//       if (result.rows.length > 0) {
//           res.json(result.rows);
//       } else {
//           res.status(404).json({ message: 'Aucun film trouvé' });
//       }
//   } catch (error) {
//       console.error(error);
//       res.status(500).json({ message: 'Erreur du serveur' });
//   }
// };


//  Amélioration : Recherche multi-mots

// export const searchMovies = async (req, res) => {
//   const { q } = req.query;

//   if (!q) {
//       return res.status(400).json({ message: 'Aucun mot-clé fourni' });
//   }

//   const keywords = q.trim().split(/\s+/);

//   let conditions = [];
//   let values = [];

//   keywords.forEach((word, index) => {
//       const likeValue = `%${word}%`;
//       values.push(likeValue, likeValue, likeValue);

//       const baseIndex = index * 3;
//       conditions.push(`(title ILIKE $${baseIndex + 1} OR genre ILIKE $${baseIndex + 2} OR description ILIKE $${baseIndex + 3})`);
//   });

//   const query = `SELECT * FROM movies WHERE ${conditions.join(' OR ')}`;

//   try {
//       const result = await pool.query(query, values);
//       res.json(result.rows);
//   } catch (error) {
//       console.error('Erreur dans la recherche :', error);
//       res.status(500).json({ message: 'Erreur du serveur pendant la recherche' });
//   }
// };

// Récupérer les films en attente de validation
// export const getPendingMovies = async (req, res) => {
//     try {
//         const result = await pool.query(`
//             SELECT 
//               movies.*, 
//               users.username AS director_username
//             FROM movies
//             JOIN users ON movies.director_id = users.user_id
//             WHERE movies.status = 'pending' 
//           `);
//         if (result.rows.length > 0) {
//             res.json(result.rows);
//         } else {
//             res.status(404).json({ message: 'Aucun film trouvé' });
//         }
//     } catch (error) {
//         console.error(error);
//         res.status(500).json({ message: 'Erreur du serveur' });
//     }
//   };
  
  
  // Approuver un film
// export const approveMovie = async (req, res) => {
//     const movieId = req.params.id;
  
//     try {
//       const result = await pool.query(
//         `UPDATE movies SET status = 'approved' WHERE movie_id = $1 RETURNING *`,
//         [movieId]
//       );
  
//       if (result.rows.length > 0) {
//         res.status(200).json({ message: 'Film validé avec succès' });
//       } else {
//         res.status(404).json({ message: 'Film non trouvé' });
//       }
//     } catch (error) {
//       console.error(error);
//       res.status(500).json({ message: 'Erreur lors de la validation du film' });
//     }
//   };
  

  // Rejeter un film
  // export const rejectMovie = async (req, res) => {
  //   const movieId = req.params.id;
  
  //   try {
  //     const result = await pool.query(
  //       `UPDATE movies SET status = 'rejected' WHERE movie_id = $1 RETURNING *`,
  //       [movieId]
  //     );
  
  //     if (result.rows.length > 0) {
  //       res.status(200).json({ message: 'Film rejeté avec succès' });
  //     } else {
  //       res.status(404).json({ message: 'Film non trouvé' });
  //     }
  //   } catch (error) {
  //     console.error(error);
  //     res.status(500).json({ message: 'Erreur lors du rejet du film' });
  //   }
  // };
  


// incrementer le nombre de vue
// export const incrementMovieViews = async (req, res) => {
//     const { id } = req.params;
//     try {
//         const result = await pool.query('SELECT * FROM movies WHERE movie_id = $1', [id]);

//         if (result.rows.length === 0) {
//             return res.status(404).json({ message: 'Film non trouvé' });
//         }

//         await pool.query(
//             `UPDATE movies SET views = views + 1 WHERE movie_id = $1`,
//             [id]
//         );
//         res.status(200).json({ message: 'Vue ajoutée' });
//     } catch (error) {
//         console.error(error);
//         res.status(500).json({ message: 'Erreur serveur' });
//     }
// };

