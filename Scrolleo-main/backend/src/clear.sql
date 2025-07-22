BEGIN;

-- Vider toutes les tables
TRUNCATE TABLE
    coin_transactions,
    coins,
    daily_rewards,
    episode_views,
    episodes,
    feexpay_transactions,
    movie_views,
    movies,
    payments,
    subscriptions,
    unlocked_episodes,
    uploads,
    user_favorites,
    user_history,
    user_likes,
    users
CASCADE;

-- Réinitialiser les séquences
ALTER SEQUENCE coin_transactions_id_seq RESTART WITH 1;
ALTER SEQUENCE daily_rewards_id_seq RESTART WITH 1;
ALTER SEQUENCE episodes_episode_id_seq RESTART WITH 1;
ALTER SEQUENCE feexpay_transactions_id_seq RESTART WITH 1;
ALTER SEQUENCE movies_movie_id_seq RESTART WITH 1;
ALTER SEQUENCE payments_id_seq RESTART WITH 1;
ALTER SEQUENCE subscriptions_id_seq RESTART WITH 1;
ALTER SEQUENCE uploads_upload_id_seq RESTART WITH 1;
ALTER SEQUENCE users_user_id_seq RESTART WITH 1;

COMMIT;
