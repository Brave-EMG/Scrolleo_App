import express from 'express';
import {
   
    addOrUpdateFavorite,
    removeFavorite,
    getUserFavorites,
    
} from './favoriteControllers.js';

const router = express.Router();


router.post("/", addOrUpdateFavorite);
router.delete("/:user_id/:episode_id", removeFavorite);
router.get("/:user_id", getUserFavorites);



export default router;
