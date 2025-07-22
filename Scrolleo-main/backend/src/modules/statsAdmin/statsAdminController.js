import pool from '../../config/database.js';

// Statistiques des utilisateurs
export const getUserStats = async (req, res) => {
    try {
        console.log('Email from token:', req.user.email); // Log pour voir l'email

        // Vérifier si l'utilisateur est admin
        const userResult = await pool.query(
            'SELECT role FROM users WHERE email = $1',
            [req.user.email]
        );

        console.log('User role from database:', userResult.rows[0]?.role); // Log pour voir le rôle

        if (userResult.rows[0]?.role !== 'admin') {
            return res.status(403).json({ 
                message: 'Accès refusé. Rôle d\'administrateur requis.',
                debug: {
                    email: req.user.email,
                    userRole: userResult.rows[0]?.role
                }
            });
        }

        const stats = await pool.query(`
            SELECT 
                COUNT(*) as total_users,
                COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_count,
                COUNT(CASE WHEN role = 'realisateur' THEN 1 END) as director_count,
                COUNT(CASE WHEN role = 'user' THEN 1 END) as user_count,
                COUNT(CASE WHEN created_at >= NOW() - INTERVAL '30 days' THEN 1 END) as new_users_30d,
                COUNT(CASE WHEN subscription_type IS NOT NULL THEN 1 END) as subscribed_users,
                COUNT(CASE WHEN subscription_expiry > NOW() THEN 1 END) as active_subscriptions,
                SUM(coins) as total_coins
            FROM users
        `);

        const subscriptionStats = await pool.query(`
            SELECT 
                subscription_type,
                COUNT(*) as count,
                COUNT(CASE WHEN subscription_expiry > NOW() THEN 1 END) as active_count
            FROM users
            WHERE subscription_type IS NOT NULL
            GROUP BY subscription_type
        `);

        res.json({
            success: true,
            data: {
                users: stats.rows[0],
                subscriptions: subscriptionStats.rows
            }
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des stats utilisateurs:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des statistiques',
            error: error.message
        });
    }
};

// Statistiques des revenus
export const getRevenueStats = async (req, res) => {
    try {
        const { period = '30' } = req.query; // période en jours

        const revenueStats = await pool.query(`
            SELECT 
                SUM(amount) as total_revenue,
                COUNT(*) as total_transactions,
                AVG(amount) as average_transaction,
                COUNT(CASE WHEN status = 'success' THEN 1 END) as successful_transactions
            FROM payments
            WHERE created_at >= NOW() - INTERVAL '${period} days'
        `);

        const revenueByType = await pool.query(`
            SELECT 
                type,
                COUNT(*) as count,
                SUM(amount) as total_amount
            FROM payments
            WHERE created_at >= NOW() - INTERVAL '${period} days'
            GROUP BY type
        `);

        res.json({
            success: true,
            data: {
                overview: revenueStats.rows[0],
                byType: revenueByType.rows
            }
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des stats de revenus:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des statistiques'
        });
    }
};

// Statistiques du contenu
export const getContentStats = async (req, res) => {
    try {
        const contentStats = await pool.query(`
            SELECT 
                (SELECT COUNT(*) FROM episodes) as total_episodes,
                (SELECT COUNT(*) FROM movies) as total_movies,
                (SELECT COUNT(*) FROM episodes WHERE created_at >= NOW() - INTERVAL '30 days') as new_episodes_30d,
                (SELECT COUNT(*) FROM movies WHERE created_at >= NOW() - INTERVAL '30 days') as new_movies_30d
        `);

        const popularContent = await pool.query(`
            SELECT 
                'episode' as type,
                e.episode_id as id,
                e.title,
                COUNT(*) as view_count
            FROM episodes e
            LEFT JOIN user_history h ON e.episode_id = h.episode_id
            GROUP BY e.episode_id, e.title
            ORDER BY view_count DESC
            LIMIT 5
        `);

        res.json({
            success: true,
            data: {
                overview: contentStats.rows[0],
                popularContent: popularContent.rows
            }
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des stats de contenu:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des statistiques'
        });
    }
};

// Statistiques d'engagement
export const getEngagementStats = async (req, res) => {
    try {
        const engagementStats = await pool.query(`
            SELECT 



            
                (SELECT COUNT(*) FROM user_favorites) as total_favorites,
                (SELECT COUNT(*) FROM user_history) as total_views,
                (SELECT COUNT(*) FROM user_likes) as total_likes,
                (SELECT COUNT(DISTINCT user_id) FROM user_history) as unique_viewers
            FROM users
            LIMIT 1
        `);

        const dailyEngagement = await pool.query(`
            SELECT 
                DATE(watched_at) as date,
                COUNT(*) as view_count
            FROM user_history
            WHERE watched_at >= NOW() - INTERVAL '30 days'
            GROUP BY DATE(watched_at)
            ORDER BY date DESC
        `);

        res.json({
            success: true,
            data: {
                overview: engagementStats.rows[0],
                dailyEngagement: dailyEngagement.rows
            }
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des stats d\'engagement:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des statistiques'
        });
    }
};

// Statistiques des réalisateurs et leurs revenus
export const getDirectorStats = async (req, res) => {
    try {
        const { period = '30' } = req.query; // période en jours
        const REVENUE_PER_VIEW = 0.6 ; // 1 FCFA par vue

        // Statistiques globales des réalisateurs
        const directorStats = await pool.query(`
            SELECT 
                u.user_id as director_id,
                u.username as director_name,
                COUNT(DISTINCT e.episode_id) as total_episodes,
                SUM(h.view_count) as total_views,
                COUNT(DISTINCT h.user_id) as unique_viewers
            FROM users u
            LEFT JOIN episodes e ON u.user_id = e.movie_id
            LEFT JOIN (
                SELECT episode_id, user_id, COUNT(*) as view_count
                FROM user_history
                WHERE watched_at >= NOW() - INTERVAL '${period} days'
                GROUP BY episode_id, user_id
            ) h ON e.episode_id = h.episode_id
            WHERE u.role = 'realisateur'
            GROUP BY u.user_id, u.username
            ORDER BY total_views DESC
        `);

        // Calcul des revenus des réalisateurs (1 FCFA par vue)
        const directorRevenue = await pool.query(`
            WITH view_stats AS (
                SELECT 
                    e.movie_id as director_id,
                    COUNT(*) as view_count
                FROM episodes e
                LEFT JOIN user_history h ON e.episode_id = h.episode_id
                WHERE h.watched_at >= NOW() - INTERVAL '${period} days'
                GROUP BY e.movie_id
            )
            SELECT 
                u.user_id as director_id,
                u.username as director_name,
                COALESCE(vs.view_count, 0) as total_views,
                COALESCE(vs.view_count * ${REVENUE_PER_VIEW}, 0) as estimated_revenue
            FROM users u
            LEFT JOIN view_stats vs ON u.user_id = vs.director_id
            WHERE u.role = 'realisateur'
            ORDER BY estimated_revenue DESC
        `);

        // Top épisodes par réalisateur
        const topEpisodes = await pool.query(`
            SELECT 
                u.username as director_name,
                e.title as episode_title,
                COUNT(*) as view_count,
                COUNT(*) * ${REVENUE_PER_VIEW} as estimated_revenue
            FROM episodes e
            JOIN users u ON e.movie_id = u.user_id
            LEFT JOIN user_history h ON e.episode_id = h.episode_id
            WHERE h.watched_at >= NOW() - INTERVAL '${period} days'
            GROUP BY u.username, e.title
            ORDER BY view_count DESC
            LIMIT 10
        `);

        res.json({
            success: true,
            data: {
                directorOverview: directorStats.rows,
                directorRevenue: directorRevenue.rows,
                topEpisodes: topEpisodes.rows,
                period: `${period} days`,
                revenuePerView: REVENUE_PER_VIEW,
                currency: 'FCFA'
            }
        });
    } catch (error) {
        console.error('Erreur lors de la récupération des stats des réalisateurs:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la récupération des statistiques'
        });
    }
}; 