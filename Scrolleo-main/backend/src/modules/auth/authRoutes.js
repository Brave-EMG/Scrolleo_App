import express from 'express';
// import authMiddlewares from './authMiddleware.js'


import {
    register,
    login,
    logout,
    updateUser,
    deleteUser,
    getAllUsers,
    getRealisateurs,
    getUserById,
    getUsers,
    resetPassword,
    forgotPassword
  } from './authController.js';
  
const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.post('/logout', logout);
router.put('/users/:id', updateUser);
router.delete('/users/:id', deleteUser);
router.get('/users/detailuser/:id', getUserById);
router.get('/users', getAllUsers);
router.get('/users/realisateurs',getRealisateurs);
router.get('/users/getuser',getUsers);
router.post('/reset-password/:token', resetPassword);
router.post('/forgot-password', forgotPassword);

// Exportation du router avec ES Modules
export default router;
