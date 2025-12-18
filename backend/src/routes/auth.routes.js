import express from 'express';
import { login, register, refreshToken, submitGmailToken, googleAuth } from '../controllers/auth.controller.js';
import { authenticateToken } from '../middleware/auth.js';
import { authLimiter } from '../middleware/rateLimiter.js';

const router = express.Router();

router.post('/login', authLimiter, login);
router.post('/register', authLimiter, register);
router.post('/refresh', refreshToken);
router.post('/gmail/token', authenticateToken, submitGmailToken);
router.post('/google', authLimiter, googleAuth);

export default router;

