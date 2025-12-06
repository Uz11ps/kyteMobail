import { User } from '../models/User.js';

export const updateFCMToken = async (req, res) => {
  try {
    const { fcmToken } = req.body;
    const userId = req.user._id;

    if (!fcmToken) {
      return res.status(400).json({ message: 'FCM токен обязателен' });
    }

    await User.findByIdAndUpdate(userId, {
      fcmToken,
    });

    res.json({ success: true, message: 'FCM токен обновлен' });
  } catch (error) {
    console.error('Ошибка обновления FCM токена:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

