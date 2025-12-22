import express from 'express';
import { getChatFiles, uploadFile, deleteFile } from '../controllers/file.controller.js';
import { authenticateToken } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';

const router = express.Router();

router.get('/chats/:chatId/files', authenticateToken, getChatFiles);
router.post('/chats/:chatId/files', authenticateToken, upload.single('file'), uploadFile);
router.delete('/files/:fileId', authenticateToken, deleteFile);

export default router;



