import express from 'express';
import { updateFCMToken } from '../controllers/user.controller.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

router.put('/fcm-token', authenticateToken, updateFCMToken);

export default router;

