import express from 'express';
import {
   likeMovie,
   unlikeMovie,
   getAllUserLikes
   
} from './likeController.js';

const router = express.Router();

router.post('/', likeMovie);
router.post('/unlike', unlikeMovie);
router.get('/all', getAllUserLikes);

export default router;
