import express from 'express';
import { askAI, getAISuggestions } from '../controllers/ai.controller.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

router.post('/ask', authenticateToken, askAI);
router.get('/suggestions', authenticateToken, getAISuggestions);

export default router;

