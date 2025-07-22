import express from 'express';
import {
   
    updateWatchHistory,
    getUserHistory
} from './historyControllers.js';

const router = express.Router();

router.post('/', updateWatchHistory);
router.get('/:user_id', getUserHistory);

export default router;
