import db from '../../config/database.js';
const { pool } = db;

export class Upload {
    constructor(data) {
        this.upload_id = data.upload_id;
        this.episode_id = data.episode_id;
        this.filename = data.filename;
        this.original_name = data.original_name || data.originalname;
        this.mime_type = data.mime_type || data.mimetype;
        this.size = data.size;
        this.path = data.path || data.location; // URL S3
        this.type = data.type;
        this.status = data.status || 'pending'; // Statut par défaut "pending"
        this.metadata = data.metadata || {}; // Contient les informations S3
        this.created_at = data.created_at;
        this.updated_at = data.updated_at;
    }

    
    async save() {
        try {
            console.log('Sauvegarde de l\'upload dans la base de données:', {
                episode_id: this.episode_id,
                filename: this.filename,
                original_name: this.original_name,
                mime_type: this.mime_type,
                size: this.size,
                path: this.path,
                type: this.type
            });

            const query = `
                INSERT INTO uploads (
                    episode_id, filename, original_name, mime_type, size, path, type, status, metadata
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
                RETURNING *
            `;
            const values = [
                this.episode_id,
                this.filename,
                this.original_name,
                this.mime_type,
                this.size,
                this.path,
                this.type,
                this.status,
                this.metadata
            ];

            const result = await pool.query(query, values);
            
            // Vérifier si l'insertion a réussi
            if (result.rows && result.rows.length > 0) {
                console.log('Upload enregistré avec succès, ID:', result.rows[0].upload_id);
                return new Upload(result.rows[0]);
            } else {
                throw new Error('Aucune ligne n\'a été insérée dans la table uploads');
            }
        } catch (error) {
            console.error('Erreur lors de l\'enregistrement de l\'upload:', error);
            throw error;
        }
    }

    async update() {
        try {
            console.log('Mise à jour de l\'upload dans la base de données:', {
                upload_id: this.upload_id,
                filename: this.filename,
                original_name: this.original_name,
                mime_type: this.mime_type,
                size: this.size,
                path: this.path,
                status: this.status
            });
    
            const query = `
                UPDATE uploads
                SET filename = $1, 
                    original_name = $2, 
                    mime_type = $3, 
                    size = $4, 
                    path = $5, 
                    type = $6, 
                    status = $7, 
                    metadata = $8, 
                    updated_at = CURRENT_TIMESTAMP
                WHERE upload_id = $9
                RETURNING *
            `;
            const values = [
                this.filename,
                this.original_name,
                this.mime_type,
                this.size,
                this.path,
                this.type,
                this.status,
                this.metadata,
                this.upload_id
            ];
    
            const result = await pool.query(query, values);
            
            // Vérifier si la mise à jour a réussi
            if (result.rows && result.rows.length > 0) {
                console.log('Upload mis à jour avec succès, ID:', result.rows[0].upload_id);
                return new Upload(result.rows[0]);
            } else {
                throw new Error('Aucune ligne n\'a été mise à jour dans la table uploads');
            }
        } catch (error) {
            console.error('Erreur lors de la mise à jour de l\'upload:', error);
            throw error;
        }
    }

    static async findById(id) {
        const query = 'SELECT * FROM uploads WHERE upload_id = $1';
        const result = await pool.query(query, [id]);
        return result.rows[0] ? new Upload(result.rows[0]) : null;
    }

    static async findByEpisode(episodeId) {
        const query = 'SELECT * FROM uploads WHERE episode_id = $1';
        const result = await pool.query(query, [episodeId]);
        return result.rows.map(row => new Upload(row));
    }

    static async findByEpisodeAndType(episodeId, type) {
        const query = 'SELECT * FROM uploads WHERE episode_id = $1 AND type = $2';
        const result = await pool.query(query, [episodeId, type]);
        return result.rows.map(row => new Upload(row));
    }

    static async findVideoByEpisode(episodeId) {
        const query = 'SELECT * FROM uploads WHERE episode_id = $1 AND type = \'video\'';
        const result = await pool.query(query, [episodeId]);
        return result.rows[0] ? new Upload(result.rows[0]) : null;
    }

    static async findThumbnailByEpisode(episodeId) {
        const query = 'SELECT * FROM uploads WHERE episode_id = $1 AND type = \'thumbnail\'';
        const result = await pool.query(query, [episodeId]);
        return result.rows[0] ? new Upload(result.rows[0]) : null;
    }

    static async findCoverImageByEpisode(episodeId) {
        const query = 'SELECT * FROM uploads WHERE episode_id = $1 AND type = \'coverimage\'';
        const result = await pool.query(query, [episodeId]);
        return result.rows[0] ? new Upload(result.rows[0]) : null;
    }

    static async findSubtitleByEpisode(episodeId) {
        const query = 'SELECT * FROM uploads WHERE episode_id = $1 AND type = \'subtitle\'';
        const result = await pool.query(query, [episodeId]);
        return result.rows[0] ? new Upload(result.rows[0]) : null;
    }

    static async updateStatus(id, status) {
        const query = `
            UPDATE uploads
            SET status = $1, updated_at = CURRENT_TIMESTAMP
            WHERE upload_id = $2
            RETURNING *
        `;
        const result = await pool.query(query, [status, id]);
        return result.rows[0] ? new Upload(result.rows[0]) : null;
    }

    static async delete(id) {
        const query = 'DELETE FROM uploads WHERE upload_id = $1 RETURNING *';
        const result = await pool.query(query, [id]);
        return result.rows[0];
    }
    
    // Méthode pour obtenir l'URL de visualisation du fichier
    getViewUrl() {
        if (this.type === 'video' && this.path.includes('public/hls/')) {
            // Pour les fichiers HLS, retourner l'URL du master manifest via CloudFront
            const s3Path = this.path.split('/').slice(3).join('/'); // Enlever 'public/hls/'
            const baseUrl = `${process.env.CLOUDFRONT_URL}/public/hls/${s3Path}`;
            return `${baseUrl}/master.m3u8`;
        }
        // Pour les autres fichiers, remplacer l'URL S3 par CloudFront
        if (this.path.includes('.s3.amazonaws.com')) {
            return this.path.replace(
                `https://${process.env.S3_BUCKET}.s3.amazonaws.com`,
                process.env.CLOUDFRONT_URL
            );
        }
        return this.path;
    }
    
    // Méthode utilitaire pour vérifier si le fichier est sur S3
    isS3File() {
        return Boolean(this.metadata && this.metadata.s3Key);
    }
}