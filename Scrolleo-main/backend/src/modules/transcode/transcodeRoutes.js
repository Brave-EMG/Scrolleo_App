import express from 'express';
import { TranscodeController } from './transcodeController.js';

const router = express.Router();

// Route pour lancer le transcodage HLS
router.post('/hls', TranscodeController.transcodeToHLS);

export default router; 