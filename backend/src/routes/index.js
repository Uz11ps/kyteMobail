import express from 'express';
import authRoutes from './auth.routes.js';
import chatRoutes from './chat.routes.js';
import groupRoutes from './group.routes.js';
import aiRoutes from './ai.routes.js';
import googleRoutes from './google.routes.js';
import userRoutes from './user.routes.js';

const router = express.Router();

router.use('/auth', authRoutes);
router.use('/chats', chatRoutes);
router.use('/groups', groupRoutes);
router.use('/ai', aiRoutes);
router.use('/google', googleRoutes);
router.use('/user', userRoutes);

router.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

export const setupRoutes = (app) => {
  app.use('/api', router);
};

