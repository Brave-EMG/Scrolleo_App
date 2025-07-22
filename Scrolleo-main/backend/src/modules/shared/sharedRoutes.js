import express from "express";
import { getShareableLink } from "./episodeController.js";

const router = express.Router();

router.get("/share/:episode_id", getShareableLink);

export default router;
