import express from 'express';
import { createGroup, joinGroup } from '../controllers/group.controller.js';
import { authenticateToken } from '../middleware/auth.js';

const router = express.Router();

router.post('/', authenticateToken, createGroup);
router.post('/join', authenticateToken, joinGroup);

export default router;

