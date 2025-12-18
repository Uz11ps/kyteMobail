import express from 'express';
import { adminLogin, adminLogout } from '../controllers/admin.controller.js';
import { getUsers, getUserById, deleteUser, updateUser } from '../controllers/admin/users.controller.js';
import { getChats, getChatById, deleteChat } from '../controllers/admin/chats.controller.js';
import { getMessages, getMessageById, deleteMessage } from '../controllers/admin/messages.controller.js';
import { getStats } from '../controllers/admin/stats.controller.js';
import { getAIConfig, updateAIConfig, testAIConfig } from '../controllers/admin/ai.controller.js';
import { adminAuth } from '../middleware/adminAuth.js';

const router = express.Router();

// Аутентификация админа
router.post('/login', adminLogin);
router.post('/logout', adminLogout);

// Защищенные роуты (требуют админ-аутентификации)
router.use(adminAuth);

// Статистика
router.get('/stats', getStats);

// Пользователи
router.get('/users', getUsers);
router.get('/users/:id', getUserById);
router.put('/users/:id', updateUser);
router.delete('/users/:id', deleteUser);

// Чаты
router.get('/chats', getChats);
router.get('/chats/:id', getChatById);
router.delete('/chats/:id', deleteChat);

// Сообщения
router.get('/messages', getMessages);
router.get('/messages/:id', getMessageById);
router.delete('/messages/:id', deleteMessage);

// Настройки AI
router.get('/ai/config', getAIConfig);
router.put('/ai/config', updateAIConfig);
router.post('/ai/config/test', testAIConfig);

export default router;

