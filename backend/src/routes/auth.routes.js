import express from 'express';
import { login, register, refreshToken, submitGmailToken } from '../controllers/auth.controller.js';
import { authenticateToken } from '../middleware/auth.js';
import { authLimiter } from '../middleware/rateLimiter.js';

const router = express.Router();

router.post('/login', authLimiter, login);
router.post('/register', authLimiter, register);
router.post('/refresh', refreshToken);
router.post('/gmail/token', authenticateToken, submitGmailToken);

export default router;

