import express from 'express';
import { createGoogleMeet } from '../controllers/google.controller.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

router.post('/meet/create', authenticateToken, createGoogleMeet);

export default router;

