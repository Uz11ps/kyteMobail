import express from 'express';
import { getChats, getMessages, sendMessage } from '../controllers/chat.controller.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

router.get('/', authenticateToken, getChats);
router.get('/:chatId/messages', authenticateToken, getMessages);
router.post('/:chatId/messages', authenticateToken, sendMessage);

export default router;

