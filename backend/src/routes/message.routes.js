import express from 'express';
import { toggleLike, markAsRead } from '../controllers/message.controller.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

router.post('/messages/:messageId/like', authenticateToken, toggleLike);
router.post('/chats/:chatId/read', authenticateToken, markAsRead);

export default router;

