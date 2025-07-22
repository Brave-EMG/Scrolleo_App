import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import pool from '../../config/database.js';
import crypto from 'crypto';
import nodemailer from 'nodemailer';


// Inscription
export const register = async (req, res) => {
    const { email, password, username } = req.body;
    let { role } = req.body;

    if (!role) {
        role = 'user';
    }
    try {
        const hash = await bcrypt.hash(password, 10); 

        const result = await pool.query(
            `INSERT INTO users (email, password, username, role) 
             VALUES ($1, $2, $3, $4) 
             RETURNING user_id, email, username, role`,
            [email, hash, username, role]
        );

        const user = result.rows[0];

        const token = jwt.sign(
            { userId: user.user_id, email: user.email },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN }
        );

        res.status(201).json({ token, user });
    } catch (error) {
        console.error(error);
        if (error.code === '23505' && error.constraint === 'users_email_key') {
            return res.status(400).json({ message: 'Un utilisateur existe déjà avec cet email' });
        }
        res.status(500).json({ message: 'Erreur du serveur' });
    }
};


// Connexion
export const login = async (req, res) => {
    const { email, password } = req.body;

    try {
        const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);

        if (result.rows.length === 0) {
            return res.status(400).json({ message: 'Email ou mot de passe incorrect' });
        }

        const user = result.rows[0];

        // Vérifier le mot de passe
        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
            return res.status(400).json({ message: 'Email ou mot de passe incorrect' });
        }

        // Générer le token
        const token = jwt.sign(
            { userId: user.id, email: user.email },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN }
        );

        res.json({ token, user });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur du serveur' });
    }
};


// Déconnexion (en théorie, pas besoin côté serveur avec JWT)
export const logout = (req, res) => {
    res.status(200).json({ message: 'Déconnexion réussie' });
};



// Modifier un utilisateur
export const updateUser = async (req, res) => {
    const { id } = req.params;
    const {
        email,
        password,
        username,
        role,
        coins,
        subscription_type,
        subscription_expiry
    } = req.body;

    try {
        // Affichage du corps pour débogage
        //   console.log("ID reçu :", id);
        //   console.log("Données reçues :", req.body);

        let query = 'UPDATE users SET ';
        const fields = [];
        const values = [];
        let index = 1;

        if (email) {
            fields.push(`email = $${index++}`);
            values.push(email);
        }
        if (password) {
            const hashedPassword = await bcrypt.hash(password, 10);
            fields.push(`password = $${index++}`);
            values.push(hashedPassword);
        }
        if (username) {
            fields.push(`username = $${index++}`);
            values.push(username);
        }
        if (role) {
            fields.push(`role = $${index++}`);
            values.push(role);
        }
        if (coins !== undefined) {
            fields.push(`coins = $${index++}`);
            values.push(coins);
        }
        if (subscription_type) {
            fields.push(`subscription_type = $${index++}`);
            values.push(subscription_type);
        }
        if (subscription_expiry) {
            fields.push(`subscription_expiry = $${index++}`);
            values.push(subscription_expiry);
        }

        if (fields.length === 0) {
            return res.status(400).json({ message: "Aucune donnée à mettre à jour" });
        }

        query += fields.join(', ') + ` WHERE user_id = $${index} RETURNING *`;
        values.push(id);

        const result = await pool.query(query, values);

        if (result.rows.length === 0) {
            console.warn(`Aucun utilisateur trouvé avec l'ID ${id}`);
            return res.status(404).json({ message: "Utilisateur non trouvé" });
        }

        res.json({ message: "Utilisateur mis à jour avec succès", user: result.rows[0] });
    } catch (error) {
        console.error("Erreur lors de la mise à jour de l'utilisateur :", error.message);

        // En développement, on peut exposer plus de détails
        res.status(500).json({
            message: 'Erreur du serveur lors de la mise à jour de l\'utilisateur',
            error: error.message,
        });
    }
};


// Supprimer un utilisateur
export const deleteUser = async (req, res) => {
    const { id } = req.params;

    try {
        await pool.query('DELETE FROM users WHERE user_id = $1', [id]);
        res.json({ message: "Utilisateur supprimé avec succès" });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur du serveur' });
    }
};

// Récupérer tous les utilisateurs
export const getAllUsers = async (req, res) => {
    try {
        const result = await pool.query('SELECT user_id, email, username, role, coins FROM users');
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur du serveur' });
    }
};


// Récupérer les utilisateurs avec le rôle "realisateur"
export const getRealisateurs = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT user_id, email, username, role FROM users WHERE role = 'realisateur'`
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur du serveur' });
    }
};

// Récupérer les utilisateurs avec le rôle "user"
export const getUsers = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT user_id, email, username, role FROM users WHERE role = 'user'`
        );
        res.json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur du serveur' });
    }
};


// Récupérer un utilisateur par ID
export const getUserById = async (req, res) => {
    const { id } = req.params;

    try {
        const result = await pool.query('SELECT * FROM users WHERE user_id = $1', [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ message: "Utilisateur non trouvé" });
        }

        res.json({ user: result.rows[0] });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur du serveur' });
    }
};




export const forgotPassword = async (req, res) => {
  const { email } = req.body;

  if (!email) return res.status(400).json({ message: "Email requis" });

  try {
    // Vérifier si l'utilisateur existe
    const { rows } = await pool.query('SELECT * FROM users WHERE email = $1', [email]);

    if (rows.length === 0) {
      return res.status(404).json({ message: "Utilisateur introuvable" });
    }

    // Générer un token sécurisé
    const resetToken = crypto.randomBytes(32).toString('hex');
    const expiration = new Date(Date.now() + 60 * 60 * 1000); // 1 heure

    // Stocker le token dans la base
    await pool.query(
      `UPDATE users SET reset_token = $1, reset_token_expiration = $2 WHERE email = $3`,
      [resetToken, expiration, email]
    );

    // Envoyer le mail
      const transporter = nodemailer.createTransport({
        host: 'mail.brave-emg.com',
        port: 465,
        secure: true,
        auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS,
        },
        logger: true,
        debug: true,
      });
      console.log(resetToken);

    const resetLink = `http://localhost:43041/#/reset-password/${resetToken}`; // à adapter selon ton frontend

    await transporter.sendMail({
      from: '"Scrolleo" <scrolleo@brave-emg.com>',
      to: email,
      subject: 'Réinitialisation de mot de passe',
      html: `<p>Bonjour,</p>
             <p>Voici le lien pour réinitialiser votre mot de passe :</p>
             <a href="${resetLink}">${resetLink}</a>`,
    });

    res.status(200).json({ message: "Email de réinitialisation envoyé" });
  } catch (error) {
    console.error("Erreur forgotPassword:", error);
    res.status(500).json({ message: "Erreur serveur" });
  }
};


export const resetPassword = async (req, res) => {
  const { token } = req.params;
  const { newPassword } = req.body;

  if (!token || !newPassword) {
    return res.status(400).json({ message: "Token et nouveau mot de passe requis" });
  }

  try {
    // Rechercher l'utilisateur avec ce token (et vérifier expiration)
    const { rows } = await pool.query(
      `SELECT * FROM users 
       WHERE reset_token = $1 AND reset_token_expiration > NOW()`,
      [token]
    );

    if (rows.length === 0) {
      return res.status(400).json({ message: "Lien invalide ou expiré" });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Mise à jour du mot de passe et suppression du token
    await pool.query(
      `UPDATE users 
       SET password = $1, reset_token = NULL, reset_token_expiration = NULL 
       WHERE reset_token = $2`,
      [hashedPassword, token]
    );

    res.status(200).json({ message: "Mot de passe réinitialisé avec succès" });
  } catch (error) {
    console.error("Erreur resetPassword:", error);
    res.status(500).json({ message: "Erreur serveur" });
  }
};
