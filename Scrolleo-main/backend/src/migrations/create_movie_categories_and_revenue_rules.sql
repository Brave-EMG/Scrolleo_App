-- Création de la table des catégories de films
CREATE TABLE IF NOT EXISTS movie_categories (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    min_years INT,
    max_years INT,
    is_exclusive BOOLEAN DEFAULT false
);

-- Création de la table des règles de rémunération
CREATE TABLE IF NOT EXISTS revenue_rules (
    rule_id SERIAL PRIMARY KEY,
    category_id INT REFERENCES movie_categories(category_id),
    percentage NUMERIC(5,2) NOT NULL,
    percentage_after_2_years NUMERIC(5,2) NOT NULL,
    base_amount NUMERIC(10,3) NOT NULL DEFAULT 0.6, -- 0,6 FCFA par vue
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Remplissage des catégories selon le tableau
-- INSERT INTO movie_categories (name, description, min_years, max_years, is_exclusive) VALUES
--     ('Exclusivités SCROLLEO', 'Contenus disponibles uniquement sur SCROLLEO (licence exclusive ou production originale)', NULL, NULL, true),
--     ('Très récents', 'Films inédits ou sortis récemment, à forte valeur d''appel', 0, 2, false),
--     ('Récents', 'Œuvres encore actuelles et attractives pour un large public', 2, 5, false),
--     ('Anciens', 'Films bien diffusés, à valeur de catalogue ou nostalgique', 5, 20, false);

-- Remplissage des règles de rémunération
INSERT INTO revenue_rules (category_id, percentage, percentage_after_2_years, base_amount)
SELECT category_id, perc, perc2, 0.6
FROM (
    SELECT name, 
        CASE WHEN name = 'Exclusivités' THEN 50
             WHEN name = 'Très récents' THEN 35
             WHEN name = 'Récents' THEN 30
             WHEN name = 'Anciens' THEN 20 END AS perc,
        20 AS perc2
    FROM movie_categories
) AS t
JOIN movie_categories mc ON mc.name = t.name; 

