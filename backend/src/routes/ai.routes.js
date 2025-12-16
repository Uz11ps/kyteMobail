import express from 'express';
import { askAI, getAISuggestions, aiChat, getAIChatHistory } from '../controllers/ai.controller.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

router.post('/ask', authenticateToken, askAI);
router.get('/suggestions', authenticateToken, getAISuggestions);
router.post('/chat', authenticateToken, aiChat);
router.get('/chat/history', authenticateToken, getAIChatHistory);

export default router;

