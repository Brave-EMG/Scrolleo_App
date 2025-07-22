-- Supprimer les triggers (évite erreurs si on DROP ensuite)
DROP TRIGGER IF EXISTS update_uploads_updated_at ON uploads;

-- Supprimer la fonction
DROP FUNCTION IF EXISTS update_updated_at_column;

-- Supprimer les tables dans le bon ordre (fils → parents)
DROP TABLE IF EXISTS uploads CASCADE;


-- Table pour les uploads
CREATE TABLE uploads (
    upload_id SERIAL PRIMARY KEY,
    episode_id INTEGER NOT NULL REFERENCES episodes(episode_id) ON DELETE CASCADE,
    filename VARCHAR(255) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    size BIGINT NOT NULL,
    path TEXT NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('video', 'thumbnail', 'subtitle')),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
