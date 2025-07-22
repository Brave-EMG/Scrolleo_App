const {pool} = db; // Connexion à la base via pg

// Ajouter une transaction de coin (gain ou dépense)
const addTransaction = async (userId, amount, reason) => {
  const query = `
    INSERT INTO coin_transactions (user_id, amount, reason)
    VALUES ($1, $2, $3)
    RETURNING *;
  `;
  const values = [userId, amount, reason];
  const result = await pool.query(query, values);
  return result.rows[0];
};

// Récupérer toutes les transactions d’un utilisateur
const getTransactionsByUser = async (userId) => {
  const query = `
    SELECT * FROM coin_transactions
    WHERE user_id = $1
    ORDER BY created_at DESC;
  `;
  const result = await pool.query(query, [userId]);
  return result.rows;
};

// Obtenir le solde calculé à partir des transactions (optionnel si tu ne stockes pas dans une table coins)
const getBalance = async (userId) => {
  const query = `
    SELECT COALESCE(SUM(amount), 0) as balance
    FROM coin_transactions
    WHERE user_id = $1;
  `;
  const result = await pool.query(query, [userId]);
  return parseInt(result.rows[0].balance, 10);
};

module.exports = {
  addTransaction,
  getTransactionsByUser,
  getBalance,
};
