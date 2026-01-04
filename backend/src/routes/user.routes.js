import express from 'express';
import { updateFCMToken, getCurrentUser, updateProfile, uploadAvatar, getUserById } from '../controllers/user.controller.js';
import { authenticateToken } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';

const router = express.Router();

router.put('/fcm-token', authenticateToken, updateFCMToken);
router.get('/me', authenticateToken, getCurrentUser);
router.get('/:id', authenticateToken, getUserById);
router.put('/profile', authenticateToken, updateProfile);
router.post('/avatar', authenticateToken, upload.single('avatar'), uploadAvatar);

export default router;

