import express from 'express';
import { login, register, refreshToken, submitGmailToken, googleAuth, sendPhoneCode, verifyPhoneCode, guestLogin, sendTestEmail } from '../controllers/auth.controller.js';
import { authenticateToken } from '../middleware/auth.js';
import { authLimiter } from '../middleware/rateLimiter.js';

const router = express.Router();

router.post('/login', authLimiter, login);
router.post('/register', authLimiter, register);
router.post('/refresh', refreshToken);
router.post('/gmail/token', authenticateToken, submitGmailToken);
router.post('/google', authLimiter, googleAuth);
router.post('/phone/send-code', authLimiter, sendPhoneCode);
router.post('/phone/verify-code', authLimiter, verifyPhoneCode);
router.post('/guest', authLimiter, guestLogin);
router.post('/email/test', sendTestEmail); // No auth limiter for test, or add if needed

export default router;

