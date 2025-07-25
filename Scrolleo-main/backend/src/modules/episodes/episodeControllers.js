import { Episode } from './episodeModels.js';
import db from '../../config/database.js';
import fetch from 'node-fetch';

const { pool } = db;

export class EpisodeController {
    constructor() {
        // Bind des méthodes
        this.createEpisode = this.createEpisode.bind(this);
        this.getEpisode = this.getEpisode.bind(this);
        this.updateEpisode = this.updateEpisode.bind(this);
        this.deleteEpisode = this.deleteEpisode.bind(this);
        this.getEpisodesByMovie = this.getEpisodesByMovie.bind(this);
        // this.createMultipleEpisodes = this.createMultipleEpisodes.bind(this);
        this.getFirstEpisode = this.getFirstEpisode.bind(this);
        this.getNextEpisode = this.getNextEpisode.bind(this);
    }

    // Crée un seul épisode
    // async createEpisode(req, res) {
    //     try {
    //         const { movie_id, title, description, episode_number, season_number } = req.body;


    //         if (!movie_id || !title || !episode_number) {
    //             return res.status(400).json({
    //                 error: 'Les champs movie_id, title et episode_number sont requis'
    //             });
    //         }

    //         // Vérifier si le film existe
    //         const movieResult = await pool.query('SELECT * FROM movies WHERE movie_id = $1', [movie_id]);
    //         if (movieResult.rows.length === 0) {
    //             return res.status(404).json({ error: 'Film non trouvé' });
    //         }


    //         // Insérer l'épisode dans la base de données
    //         const insertQuery = `
    //             INSERT INTO episodes (movie_id, title, description, episode_number, season_number)
    //             VALUES ($1, $2, $3, $4, $5)
    //             RETURNING *;
    //         `;

    //         const values = [
    //             movie_id,
    //             title,
    //             description || '',
    //             episode_number,
    //             season_number || 1
    //         ];

    //         const result = await pool.query(insertQuery, values);

    //         res.status(201).json({
    //             success: true,
    //             episode: result.rows[0]
    //         });

    //     } catch (error) {
    //         console.error('Erreur lors de la création de l\'épisode:', error);
    //         res.status(500).json({
    //             error: 'Erreur serveur',

    //             details: error.message
    //         });
    //     }
    // }

    // // export default createEpisode;


    // // Crée plusieurs épisodes pour un film
    // async createMultipleEpisodes(req, res) {
    //     try {
    //         const { movie_id, episodes } = req.body;

    //         if (!movie_id || !episodes || !Array.isArray(episodes) || episodes.length === 0) {
    //             return res.status(400).json({ 
    //                 error: 'Le movie_id et un tableau d\'épisodes sont requis' 
    //             });
    //         }

    //         // Vérifier si le film existe
    //         const movieResult = await pool.query('SELECT * FROM movies WHERE movie_id = $1', [movie_id]);
    //         if (movieResult.rows.length === 0) {
    //             return res.status(404).json({ error: 'Film non trouvé' });
    //         }

    //         const results = [];

    //         // Utiliser une transaction pour garantir l'atomicité
    //         const client = await pool.connect();
    //         try {
    //             await client.query('BEGIN');

    //             for (const episodeData of episodes) {
    //                 const { title, description, episode_number, season_number } = episodeData;

    //                 if (!title || !episode_number) {
    //                     results.push({ 
    //                         success: false, 
    //                         error: 'Les champs title et episode_number sont requis pour chaque épisode' 
    //                     });
    //                     continue;
    //                 }

    //                 // Créer l'épisode
    //                 const episode = new Episode({
    //                     movie_id,
    //                     title,
    //                     description: description || '',
    //                     episode_number,
    //                     season_number: season_number || 1
    //                 });

    //                 const query = `
    //                     INSERT INTO episodes (movie_id, title, description, episode_number, season_number)
    //                     VALUES ($1, $2, $3, $4, $5)
    //                     RETURNING *
    //                 `;
    //                 const values = [
    //                     movie_id,
    //                     title,
    //                     description || '',
    //                     episode_number,
    //                     season_number || 1
    //                 ];

    //                 const result = await client.query(query, values);
    //                 results.push({ 
    //                     success: true, 
    //                     episode: result.rows[0] 
    //                 });
    //             }

    //             await client.query('COMMIT');
    //         } catch (error) {
    //             await client.query('ROLLBACK');
    //             throw error;
    //         } finally {
    //             client.release();
    //         }

    //         res.status(201).json({
    //             success: true,
    //             results
    //         });
    //     } catch (error) {
    //         console.error('Erreur lors de la création multiple d\'épisodes:', error);
    //         res.status(500).json({
    //             error: 'Erreur lors de la création multiple d\'épisodes',
    //             details: error.message
    //         });
    //     }
    // }

    async updateFreeEpisodes(movie_id) {
        try {
            // 1. Récupérer le nombre total d'épisodes depuis la table movies
            const movieResult = await pool.query(
                `SELECT episodes_count FROM movies WHERE movie_id = $1`,
                [movie_id]
            );

            if (movieResult.rows.length === 0) {
                console.error("Film non trouvé");
                return;
            }

            const episodesCount = movieResult.rows[0].episodes_count;

            // 2. Calculer le nombre d'épisodes à rendre gratuits (1/4)
            const freeCount = Math.floor(episodesCount / 4);

            if (freeCount === 0) {
                console.log("Pas assez d'épisodes pour en rendre gratuits.");
                return;
            }

            // 3. Rendre gratuits les N premiers épisodes
            await pool.query(
                `
            UPDATE episodes
            SET is_free = TRUE
            WHERE episode_id IN (
                SELECT episode_id
                FROM episodes
                WHERE movie_id = $1
                ORDER BY episode_number ASC
                LIMIT $2
            )
        `,
                [movie_id, freeCount]
            );

            console.log(`${freeCount} épisode(s) rendus gratuits pour le film ${movie_id}`);
        } catch (error) {
            console.error("Erreur lors de la mise à jour des épisodes gratuits :", error);
        }
    }

    // Nouvelle fonction pour configurer automatiquement les épisodes
    async configureEpisodesForMovie(movie_id) {
        try {
            console.log(`Configuration automatique des épisodes pour le film ${movie_id}`);
            
            // 1. Récupérer tous les épisodes du film
            const episodesResult = await pool.query(
                'SELECT episode_id, episode_number FROM episodes WHERE movie_id = $1 ORDER BY episode_number ASC',
                [movie_id]
            );

            if (episodesResult.rows.length === 0) {
                console.log("Aucun épisode trouvé pour ce film");
                return;
            }

            const episodes = episodesResult.rows;
            console.log(`Trouvé ${episodes.length} épisodes pour le film ${movie_id}`);

            // 2. Configurer le premier épisode comme gratuit
            if (episodes.length > 0) {
                await pool.query(
                    'UPDATE episodes SET is_free = TRUE, coin_cost = 0 WHERE episode_id = $1',
                    [episodes[0].episode_id]
                );
                console.log(`Épisode 1 (ID: ${episodes[0].episode_id}) configuré comme gratuit`);
            }

            // 3. Configurer les autres épisodes comme payants (1 pièce)
            if (episodes.length > 1) {
                const otherEpisodeIds = episodes.slice(1).map(ep => ep.episode_id);
                await pool.query(
                    'UPDATE episodes SET is_free = FALSE, coin_cost = 1 WHERE episode_id = ANY($1)',
                    [otherEpisodeIds]
                );
                console.log(`${episodes.length - 1} épisodes configurés comme payants (1 pièce chacun)`);
            }

            console.log(`Configuration terminée pour le film ${movie_id}`);
        } catch (error) {
            console.error("Erreur lors de la configuration des épisodes :", error);
        }
    }

    async createEpisode(req, res) {
        const { movie_id, episodes } = req.body;

        // Vérification des champs
        if (!movie_id || !Array.isArray(episodes) || episodes.length === 0) {
            return res.status(400).json({ message: "movie_id et episodes sont requis" });
        }

        try {
            // Vérifie si le film existe
            const movieCheck = await pool.query(
                `SELECT 1 FROM movies WHERE movie_id = $1`,
                [movie_id]
            );

            if (movieCheck.rowCount === 0) {
                return res.status(404).json({ message: "Le film n'existe pas" });
            }

            // Préparer la requête SQL pour l'insertion multiple
            const values = [];
            const placeholders = episodes.map((ep, index) => {
                const i = index * 6;
                values.push(
                    movie_id,
                    ep.title,
                    ep.description || null,
                    ep.episode_number,
                    ep.season_number,
                    ep.is_free || false
                );
                return `($${i + 1}, $${i + 2}, $${i + 3}, $${i + 4}, $${i + 5}, $${i + 6})`;
            });

            await pool.query(
                `INSERT INTO episodes (movie_id, title, description, episode_number, season_number,is_free)
             VALUES ${placeholders.join(", ")}`,
                values
            );

            // Configurer automatiquement les épisodes (premier gratuit, autres payants)
            await this.configureEpisodesForMovie(movie_id);

            res.status(201).json({ message: "Épisodes créés avec succès" });

        } catch (err) {
            console.error("Erreur lors de la création des épisodes :", err);
            res.status(500).json({ message: "Erreur serveur" });
        }
    };


    // Récupère un épisode par son ID
    async getEpisode(req, res) {
        try {
            const { id } = req.params;
            const episode = await Episode.findById(id);

            if (!episode) {
                return res.status(404).json({ error: 'Épisode non trouvé' });
            }

            // Récupérer les fichiers associés
            const uploads = await episode.getUploads();

            res.json({
                episode,
                uploads
            });
        } catch (error) {
            console.error('Erreur lors de la récupération de l\'épisode:', error);
            res.status(500).json({
                error: 'Erreur lors de la récupération de l\'épisode',
                details: error.message
            });
        }
    }

    // Récupère tous les épisodes d'un film
    async getEpisodesByMovie(req, res) {
        try {
            const { movieId } = req.params;
            const { season } = req.query;

            let episodes;
            if (season) {
                episodes = await Episode.findByMovieAndSeason(movieId, season);
            } else {
                episodes = await Episode.findByMovie(movieId);
            }

            // Pour chaque épisode, récupère le vrai nombre de vues et la miniature
            for (const ep of episodes) {
                // Récupérer le nombre de vues
                const viewsResult = await pool.query(
                    'SELECT COUNT(*) FROM episode_views WHERE episode_id = $1',
                    [ep.episode_id]
                );
                ep.views = parseInt(viewsResult.rows[0].count, 10);

                // Récupérer la miniature
                const thumbnailResult = await pool.query(
                    'SELECT path FROM uploads WHERE episode_id = $1 AND type = \'thumbnail\' AND status = \'completed\' ORDER BY created_at DESC LIMIT 1',
                    [ep.episode_id]
                );
                if (thumbnailResult.rows.length > 0) {
                    let thumbnailUrl = thumbnailResult.rows[0].path;
                    
                                    // Convertir l'URL S3 en URL CloudFront si nécessaire
                if (thumbnailUrl && thumbnailUrl.includes('.s3.amazonaws.com')) {
                    thumbnailUrl = thumbnailUrl.replace(
                        `https://${process.env.S3_BUCKET}.s3.amazonaws.com`,
                        process.env.CLOUDFRONT_URL || 'https://dm23yf4cycj8r.cloudfront.net'
                    );
                }
                    
                    ep.thumbnail_url = thumbnailUrl;
                }
            }

            res.json({
                count: episodes.length,
                episodes
            });
        } catch (error) {
            console.error('Erreur lors de la récupération des épisodes:', error);
            res.status(500).json({
                error: 'Erreur lors de la récupération des épisodes',
                details: error.message
            });
        }
    }

    // Met à jour un épisode
    async updateEpisode(req, res) {
        try {
            const { id } = req.params;
            const { title, description, episode_number, season_number } = req.body;

            const episode = await Episode.findById(id);
            if (!episode) {
                return res.status(404).json({ error: 'Épisode non trouvé' });
            }

            // Mettre à jour les champs
            if (title) episode.title = title;
            if (description !== undefined) episode.description = description;
            if (episode_number) episode.episode_number = episode_number;
            if (season_number) episode.season_number = season_number;

            const updatedEpisode = await episode.update();

            res.json({
                success: true,
                episode: updatedEpisode
            });
        } catch (error) {
            console.error('Erreur lors de la mise à jour de l\'épisode:', error);
            res.status(500).json({
                error: 'Erreur lors de la mise à jour de l\'épisode',
                details: error.message
            });
        }
    }

    // Supprime un épisode
    async deleteEpisode(req, res) {
        try {
            const { id } = req.params;

            // Vérifier si l'épisode existe
            const episode = await Episode.findById(id);
            if (!episode) {
                return res.status(404).json({ error: 'Épisode non trouvé' });
            }

            // Supprimer l'épisode (les uploads associés seront supprimés en cascade)
            await Episode.delete(id);

            res.json({
                success: true,
                message: 'Épisode supprimé avec succès',
                episode_id: id
            });
        } catch (error) {
            console.error('Erreur lors de la suppression de l\'épisode:', error);
            res.status(500).json({
                error: 'Erreur lors de la suppression de l\'épisode',
                details: error.message
            });
        }
    }

    // Récupère le premier épisode d'un film
    async getFirstEpisode(req, res) {
        try {
            const { movieId, userId } = req.params;
            const episode = await Episode.getFirstEpisode(movieId, userId);

            if (!episode) {
                return res.status(404).json({ error: 'Aucun épisode trouvé pour ce film' });
            }

            // Récupérer les fichiers associés
            const uploads = await episode.getUploads();

            // Chercher l'upload vidéo
            const videoUpload = uploads.find(u => u.type === 'video' && u.status === 'completed' && u.path);
            let video_url = null;
            if (videoUpload && videoUpload.path) {
                // Encoder l'URL pour gérer les espaces et caractères spéciaux
                const basePath = videoUpload.path.startsWith('http') ? videoUpload.path : `http://localhost:3000${videoUpload.path}`;
                video_url = encodeURI(basePath);
            }

            // Ajouter video_url à l'objet episode
            const episodeObj = { ...episode, video_url };

            res.json({
                episode: episodeObj,
                uploads
            });
        } catch (error) {
            console.error('Erreur lors de la récupération du premier épisode:', error);
            res.status(500).json({
                error: 'Erreur lors de la récupération du premier épisode',
                details: error.message
            });
        }
    }

    // Récupère l'épisode suivant dans l'ordre de lecture

    async getNextEpisode(req, res) {
        try {
            const { movieId, seasonNumber, episodeNumber, userId } = req.params;
            // Conversion des paramètres en nombres entiers
            const movieIdInt = parseInt(movieId, 10);
            const seasonNumberInt = parseInt(seasonNumber, 10);
            const episodeNumberInt = parseInt(episodeNumber, 10);

            if (isNaN(movieIdInt) || isNaN(seasonNumberInt) || isNaN(episodeNumberInt)) {
                return res.status(400).json({
                    error: 'Paramètres invalides',
                    details: 'Les paramètres movieId, seasonNumber et episodeNumber doivent être des nombres'
                });
            }

            const episode = await Episode.getNextEpisode(movieIdInt, seasonNumberInt, episodeNumberInt, userId);
            if (!episode) {
                return res.status(404).json({ error: 'Aucun épisode suivant trouvé' });
            }

            // Récupérer les fichiers associés
            const uploads = await episode.getUploads();
            // Chercher l'upload vidéo
            const videoUpload = uploads.find(u => u.type === 'video' && u.status === 'completed' && u.path);
            let video_url = null;
            if (videoUpload && videoUpload.path) {
                // Encoder l'URL pour gérer les espaces et caractères spéciaux
                const basePath = videoUpload.path.startsWith('http') ? videoUpload.path : `http://localhost:3000${videoUpload.path}`;
                video_url = encodeURI(basePath);
            }
            // Ajouter video_url à l'objet episode
            const episodeObj = { ...episode, video_url };

            res.json({
                episode: episodeObj,
                uploads
            });
        } catch (error) {
            console.error('Erreur lors de la récupération de l\'épisode suivant:', error);
            res.status(500).json({
                error: 'Erreur lors de la récupération de l\'épisode suivant',
                details: error.message
            });
        }
    }

    // Vérifier l'accès à un épisode
    async checkEpisodeAccess(req, res) {
        console.log('=== DÉBUT checkEpisodeAccess ===');
        console.log('📥 Episode ID:', req.params.episodeId);
        console.log('👤 User object:', req.user);
        console.log('📧 User email:', req.user?.email);
        
        try {
            const { episodeId } = req.params;
            const userEmail = req.user?.email;

            console.log('🔍 Recherche épisode avec ID:', episodeId);

            // Récupérer l'épisode
            const episode = await Episode.findById(episodeId);
            if (!episode) {
                console.log('❌ Épisode non trouvé');
                return res.status(404).json({ error: 'Épisode non trouvé' });
            }
            console.log('✅ Épisode trouvé:', episode);

                        // Récupérer la miniature de l'épisode
            const thumbnailResult = await pool.query(
                'SELECT path FROM uploads WHERE episode_id = $1 AND type = \'thumbnail\' AND status = \'completed\' ORDER BY created_at DESC LIMIT 1',
                [episodeId]
            );
            if (thumbnailResult.rows.length > 0) {
                let thumbnailUrl = thumbnailResult.rows[0].path;
                
                console.log('🔍 URL originale de la miniature:', thumbnailUrl);
                console.log('🌐 CLOUDFRONT_URL:', process.env.CLOUDFRONT_URL);
                console.log('🪣 S3_BUCKET:', process.env.S3_BUCKET);
                
                // Convertir l'URL S3 en URL CloudFront si nécessaire
                if (thumbnailUrl && thumbnailUrl.includes('.s3.amazonaws.com')) {
                    const cloudfrontUrl = process.env.CLOUDFRONT_URL || 'https://dm23yf4cycj8r.cloudfront.net';
                    thumbnailUrl = thumbnailUrl.replace(
                        `https://${process.env.S3_BUCKET}.s3.amazonaws.com`,
                        cloudfrontUrl
                    );
                    console.log('✅ URL convertie en CloudFront:', thumbnailUrl);
                }
                
                episode.thumbnail_url = thumbnailUrl;
            }

            // Si l'épisode est gratuit, accès autorisé
            if (episode.is_free) {
                console.log('🎁 Épisode gratuit - accès autorisé');
                return res.json({
                    hasAccess: true,
                    reason: 'episode_gratuit',
                    episode: episode
                });
            }

            // Si pas d'utilisateur connecté, pas d'accès
            if (!userEmail) {
                console.log('❌ Pas d\'utilisateur connecté');
                return res.json({
                    hasAccess: false,
                    reason: 'utilisateur_non_connecte',
                    episode: episode
                });
            }

            // Récupérer l'ID utilisateur et le rôle
            const { rows: userRows } = await pool.query(
                'SELECT user_id, role FROM users WHERE email = $1',
                [userEmail]
            );

            if (userRows.length === 0) {
                return res.status(404).json({ error: 'Utilisateur non trouvé' });
            }

            const userId = userRows[0].user_id;
            const userRole = userRows[0].role;

            // Si l'utilisateur est admin, accès autorisé
            if (userRole === 'admin') {
                return res.json({
                    hasAccess: true,
                    reason: 'admin_access',
                    episode: episode
                });
            }

            // Vérifier si l'utilisateur a un abonnement actif
            const subscriptionResult = await pool.query(
                `SELECT * FROM subscriptions 
                 WHERE user_id = $1 
                 AND status = 'active' 
                 AND end_date > CURRENT_TIMESTAMP`,
                [userId]
            );

            if (subscriptionResult.rows.length > 0) {
                return res.json({
                    hasAccess: true,
                    reason: 'abonnement_actif',
                    episode: episode
                });
            }

            // Vérifier si l'épisode est déjà débloqué
            const unlockedResult = await pool.query(
                'SELECT * FROM unlocked_episodes WHERE user_id = $1 AND episode_id = $2',
                [userId, episodeId]
            );

            if (unlockedResult.rows.length > 0) {
                return res.json({
                    hasAccess: true,
                    reason: 'episode_debloque',
                    episode: episode
                });
            }

            // Vérifier le solde de coins
            const coinsResult = await pool.query(
                'SELECT balance FROM coins WHERE user_id = $1',
                [userId]
            );

            const userBalance = coinsResult.rows.length > 0 ? coinsResult.rows[0].balance : 0;
            const requiredCoins = episode.coin_cost || 1;

            return res.json({
                hasAccess: false,
                reason: 'episode_payant',
                episode: episode,
                userBalance: userBalance,
                requiredCoins: requiredCoins,
                canUnlock: userBalance >= requiredCoins
            });

        } catch (error) {
            console.error('Erreur lors de la vérification d\'accès:', error);
            res.status(500).json({
                error: 'Erreur lors de la vérification d\'accès',
                details: error.message
            });
        }
    }

    // Débloquer un épisode
    async unlockEpisode(req, res) {
        try {
            const { episodeId } = req.params;
            const userEmail = req.user?.email;

            if (!userEmail) {
                return res.status(401).json({ error: 'Utilisateur non connecté' });
            }

            // Récupérer l'ID utilisateur et le rôle
            const { rows: userRows } = await pool.query(
                'SELECT user_id, role FROM users WHERE email = $1',
                [userEmail]
            );

            if (userRows.length === 0) {
                return res.status(404).json({ error: 'Utilisateur non trouvé' });
            }

            const userId = userRows[0].user_id;
            const userRole = userRows[0].role;

            // Récupérer l'épisode
            const episode = await Episode.findById(episodeId);
            if (!episode) {
                return res.status(404).json({ error: 'Épisode non trouvé' });
            }

            // Si l'épisode est gratuit, pas besoin de débloquer
            if (episode.is_free) {
                return res.json({
                    success: true,
                    message: 'Épisode gratuit - accès autorisé',
                    episode: episode
                });
            }

            // Vérifier si l'épisode est déjà débloqué
            const unlockedResult = await pool.query(
                'SELECT * FROM unlocked_episodes WHERE user_id = $1 AND episode_id = $2',
                [userId, episodeId]
            );

            if (unlockedResult.rows.length > 0) {
                return res.json({
                    success: true,
                    message: 'Épisode déjà débloqué',
                    episode: episode
                });
            }

            // Si l'utilisateur est admin, débloquer sans dépenser de coins
            if (userRole === 'admin') {
                // Débloquer l'épisode pour l'admin
                await pool.query(
                    'INSERT INTO unlocked_episodes (user_id, episode_id) VALUES ($1, $2)',
                    [userId, episodeId]
                );

                return res.json({
                    success: true,
                    message: 'Épisode débloqué avec succès (accès admin)',
                    episode: episode,
                    coinsSpent: 0,
                    newBalance: null
                });
            }

            // Vérifier le solde de coins
            const coinsResult = await pool.query(
                'SELECT balance FROM coins WHERE user_id = $1',
                [userId]
            );

            const userBalance = coinsResult.rows.length > 0 ? coinsResult.rows[0].balance : 0;
            const requiredCoins = episode.coin_cost || 1;

            if (userBalance < requiredCoins) {
                return res.status(400).json({
                    error: 'Solde insuffisant',
                    userBalance: userBalance,
                    requiredCoins: requiredCoins
                });
            }

            // Démarrer une transaction
            console.log(`[DEBUG] Début transaction pour déblocage épisode ${episodeId}`);
            const client = await pool.connect();
            try {
                await client.query('BEGIN');
                console.log(`[DEBUG] Transaction commencée`);

                // Déduire les coins
                console.log(`[DEBUG] Déduction de ${requiredCoins} coins pour utilisateur ${userId}`);
                await client.query(
                    'UPDATE coins SET balance = balance - $1 WHERE user_id = $2',
                    [requiredCoins, userId]
                );

                // Enregistrer la transaction
                console.log(`[DEBUG] Enregistrement transaction coins`);
                await client.query(
                    'INSERT INTO coin_transactions (user_id, amount, reason, episode_id) VALUES ($1, $2, $3, $4)',
                    [userId, -requiredCoins, 'Déblocage d\'épisode', episodeId]
                );

                // Débloquer l'épisode
                console.log(`[DEBUG] Déblocage épisode ${episodeId} pour utilisateur ${userId}`);
                await client.query(
                    'INSERT INTO unlocked_episodes (user_id, episode_id) VALUES ($1, $2)',
                    [userId, episodeId]
                );

                await client.query('COMMIT');
                console.log(`[DEBUG] Transaction commitée avec succès`);

                // Récupérer le nouveau solde
                const newBalanceResult = await client.query(
                    'SELECT balance FROM coins WHERE user_id = $1',
                    [userId]
                );

                console.log(`[DEBUG] Nouveau solde: ${newBalanceResult.rows[0].balance}`);

                res.json({
                    success: true,
                    message: 'Épisode débloqué avec succès',
                    episode: episode,
                    coinsSpent: requiredCoins,
                    newBalance: newBalanceResult.rows[0].balance
                });

            } catch (error) {
                console.error(`[DEBUG] Erreur dans transaction: ${error.message}`);
                try {
                    await client.query('ROLLBACK');
                    console.log(`[DEBUG] Rollback effectué`);
                } catch (rollbackError) {
                    console.error(`[DEBUG] Erreur lors du rollback: ${rollbackError.message}`);
                }
                throw error;
            } finally {
                try {
                    client.release();
                    console.log(`[DEBUG] Client libéré`);
                } catch (releaseError) {
                    console.error(`[DEBUG] Erreur lors de la libération du client: ${releaseError.message}`);
                }
            }

        } catch (error) {
            console.error('Erreur lors du déblocage de l\'épisode:', error);
            
            // S'assurer que la réponse n'a pas déjà été envoyée
            if (!res.headersSent) {
                res.status(500).json({
                    error: 'Erreur lors du déblocage de l\'épisode',
                    details: error.message
                });
            }
        }
    }

    // Endpoint proxy pour servir les miniatures
    async getThumbnailProxy(req, res) {
        try {
            const { episodeId } = req.params;
            
            // Récupérer l'épisode pour obtenir l'URL de la miniature
            const episodeResult = await pool.query(
                'SELECT thumbnail_url FROM episodes WHERE episode_id = $1',
                [episodeId]
            );
            
            let thumbnailUrl = null;
            if (episodeResult.rows.length > 0) {
                thumbnailUrl = episodeResult.rows[0].thumbnail_url;
            }
            
            // Si pas d'URL ou colonne n'existe pas, utiliser une image par défaut
            if (!thumbnailUrl) {
                // Créer une image par défaut simple (1x1 pixel transparent)
                const defaultImageBuffer = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==', 'base64');
                
                res.set({
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'GET, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Cache-Control': 'public, max-age=3600',
                    'Content-Type': 'image/png',
                    'Content-Length': defaultImageBuffer.length
                });
                
                return res.send(defaultImageBuffer);
            }
            
            // Télécharger l'image depuis l'URL et la servir directement
            try {
                const response = await fetch(thumbnailUrl);
                
                if (!response.ok) {
                    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                }
                
                const buffer = await response.arrayBuffer();
                const contentType = response.headers.get('content-type') || 'image/jpeg';
                
                // Définir les headers CORS
                res.set({
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'GET, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Cache-Control': 'public, max-age=3600',
                    'Content-Type': contentType,
                    'Content-Length': buffer.byteLength
                });
                
                // Envoyer l'image
                res.send(Buffer.from(buffer));
                
            } catch (fetchError) {
                console.error('Erreur lors du téléchargement de l\'image:', fetchError);
                
                // En cas d'erreur, retourner une image par défaut
                const defaultImageBuffer = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==', 'base64');
                
                res.set({
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'GET, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type',
                    'Cache-Control': 'public, max-age=3600',
                    'Content-Type': 'image/png',
                    'Content-Length': defaultImageBuffer.length
                });
                
                return res.send(defaultImageBuffer);
            }
            
        } catch (error) {
            console.error('Erreur lors de la récupération de la miniature:', error);
            
            // En cas d'erreur, retourner une image par défaut
            const defaultImageBuffer = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==', 'base64');
            
            res.set({
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Cache-Control': 'public, max-age=3600',
                'Content-Type': 'image/png',
                'Content-Length': defaultImageBuffer.length
            });
            
            return res.send(defaultImageBuffer);
        }
    }
}