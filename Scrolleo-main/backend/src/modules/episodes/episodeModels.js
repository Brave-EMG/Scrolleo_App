import db from '../../config/database.js';
const { pool } = db;

export class Episode {
    constructor(data) {
        this.episode_id = data.episode_id;
        this.movie_id = data.movie_id;
        this.title = data.title;
        this.description = data.description || '';
        this.episode_number = data.episode_number;
        this.season_number = data.season_number || 1; // Par défaut saison 1
        this.created_at = data.created_at;
        this.updated_at = data.updated_at;
        this.views = data.views || 0;
        this.is_favorite = data.is_favorite || false;
        this.is_free = data.is_free || false;
        this.coin_cost = data.coin_cost || 1; // Coût en pièces pour débloquer l'épisode

    }

    async save() {
        const query = `
            INSERT INTO episodes (
                movie_id, title, description, episode_number, season_number
            ) VALUES ($1, $2, $3, $4, $5)
            RETURNING *
        `;
        const values = [
            this.movie_id,
            this.title,
            this.description,
            this.episode_number,
            this.season_number
        ];

        const result = await pool.query(query, values);
        return new Episode(result.rows[0]);
    }

    static async findById(id) {
        const query = 'SELECT * FROM episodes WHERE episode_id = $1';
        const result = await pool.query(query, [id]);
        return result.rows[0] ? new Episode(result.rows[0]) : null;
    }

    static async findByMovie(movieId) {
        const query = 'SELECT * FROM episodes WHERE movie_id = $1 ORDER BY season_number, episode_number';
        const result = await pool.query(query, [movieId]);
        return result.rows.map(row => new Episode(row));
    }

    static async findByMovieAndSeason(movieId, seasonNumber) {
        const query = 'SELECT * FROM episodes WHERE movie_id = $1 AND season_number = $2 ORDER BY episode_number';
        const result = await pool.query(query, [movieId, seasonNumber]);
        return result.rows.map(row => new Episode(row));
    }

    static async findByMovieAndEpisodeNumber(movieId, seasonNumber, episodeNumber) {
        const query = 'SELECT * FROM episodes WHERE movie_id = $1 AND season_number = $2 AND episode_number = $3';
        const result = await pool.query(query, [movieId, seasonNumber, episodeNumber]);
        return result.rows[0] ? new Episode(result.rows[0]) : null;
    }

    async update() {
        const query = `
            UPDATE episodes
            SET title = $1, description = $2, episode_number = $3, season_number = $4, updated_at = CURRENT_TIMESTAMP
            WHERE episode_id = $5
            RETURNING *
        `;
        const values = [
            this.title,
            this.description,
            this.episode_number,
            this.season_number,
            this.episode_id
        ];

        const result = await pool.query(query, values);
        return result.rows[0] ? new Episode(result.rows[0]) : null;
    }

    static async delete(id) {
        const query = 'DELETE FROM episodes WHERE episode_id = $1 RETURNING *';
        const result = await pool.query(query, [id]);
        return result.rows[0];
    }

    // Récupère tous les uploads associés à cet épisode
    async getUploads() {
        const query = 'SELECT * FROM uploads WHERE episode_id = $1';
        const result = await pool.query(query, [this.episode_id]);
        return result.rows;
    }

    // Récupère la vidéo associée à cet épisode
    async getVideo() {
        const query = 'SELECT * FROM uploads WHERE episode_id = $1 AND type = \'video\'';
        const result = await pool.query(query, [this.episode_id]);
        return result.rows[0];
    }

    // Récupère la miniature associée à cet épisode
    async getThumbnail() {
        const query = 'SELECT * FROM uploads WHERE episode_id = $1 AND type = \'thumbnail\'';
        const result = await pool.query(query, [this.episode_id]);
        return result.rows[0];
    }

    // Récupère le sous-titre associé à cet épisode
    async getSubtitle() {
        const query = 'SELECT * FROM uploads WHERE episode_id = $1 AND type = \'subtitle\'';
        const result = await pool.query(query, [this.episode_id]);
        return result.rows[0];
    }

    // Récupère le premier épisode d'un film
    static async getFirstEpisode(movieId, userId) {
        const query = `
            SELECT episodes.*,
                   CASE WHEN user_favorites.user_id IS NOT NULL THEN true ELSE false END AS is_favorite
            FROM episodes
            LEFT JOIN user_favorites ON user_favorites.movie_id = episodes.movie_id AND user_favorites.user_id = $2
            WHERE episodes.movie_id = $1
            ORDER BY episodes.season_number ASC, episodes.episode_number ASC
            LIMIT 1        
        `;
        const result = await pool.query(query, [movieId, userId]);
        return result.rows[0] ? new Episode(result.rows[0]) : null;
    }
    

    // Récupère l'épisode suivant dans l'ordre de lecture
    static async getNextEpisode(movieId, currentSeasonNumber, currentEpisodeNumber, userId) {
        const query = `
            SELECT episodes.*,
                   CASE 
                       WHEN user_favorites.user_id IS NOT NULL THEN true 
                       ELSE false 
                   END AS is_favorite
            FROM episodes
            LEFT JOIN user_favorites 
                ON user_favorites.movie_id = episodes.movie_id 
                AND user_favorites.user_id = $4
            WHERE episodes.movie_id = $1 
            AND (
                (episodes.season_number = $2 AND episodes.episode_number > $3) 
                OR episodes.season_number > $2
            )
            ORDER BY episodes.season_number ASC, episodes.episode_number ASC 
            LIMIT 1
        `;
    
        const result = await pool.query(query, [movieId, currentSeasonNumber, currentEpisodeNumber, userId]);
        return result.rows[0] ? new Episode(result.rows[0]) : null;
    }
    
}
