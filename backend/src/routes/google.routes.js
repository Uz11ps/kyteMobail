import express from 'express';
import { createGoogleMeet, getCalendarEvents, getChatCalendarEvents } from '../controllers/google.controller.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

router.post('/meet/create', authenticateToken, createGoogleMeet);
router.get('/calendar/events', authenticateToken, getCalendarEvents);
router.get('/chats/:chatId/events', authenticateToken, getChatCalendarEvents);

export default router;

