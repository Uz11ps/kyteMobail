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

// Получение текущего пользователя
export const getCurrentUser = async (req, res) => {
  try {
    const userId = req.user._id;
    const user = await User.findById(userId).lean();

    if (!user) {
      return res.status(404).json({ message: 'Пользователь не найден' });
    }

    res.json({ user });
  } catch (error) {
    console.error('Ошибка получения пользователя:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

// Обновление профиля пользователя
export const updateProfile = async (req, res) => {
  try {
    const userId = req.user._id;
    const { name, nickname, phone, about, birthday } = req.body;

    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (nickname !== undefined) updateData.nickname = nickname;
    if (phone !== undefined) updateData.phone = phone;
    if (about !== undefined) updateData.about = about;
    if (birthday !== undefined) {
      updateData.birthday = birthday ? new Date(birthday) : null;
    }
    updateData.updatedAt = Date.now();

    const user = await User.findByIdAndUpdate(userId, updateData, {
      new: true,
      runValidators: true,
    }).lean();

    if (!user) {
      return res.status(404).json({ message: 'Пользователь не найден' });
    }

    res.json({ user });
  } catch (error) {
    console.error('Ошибка обновления профиля:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

// Загрузка аватара пользователя
export const uploadAvatar = async (req, res) => {
  try {
    const userId = req.user._id;
    const file = req.file;

    if (!file) {
      return res.status(400).json({ message: 'Файл не загружен' });
    }

    // Проверяем тип файла (только изображения)
    if (!file.mimetype.startsWith('image/')) {
      const fs = await import('fs-extra');
      await fs.remove(file.path);
      return res.status(400).json({ message: 'Разрешены только изображения' });
    }

    // Формируем URL аватара
    const avatarUrl = `/uploads/${file.filename}`;

    // Обновляем пользователя
    const user = await User.findByIdAndUpdate(
      userId,
      { avatarUrl, updatedAt: Date.now() },
      { new: true }
    ).lean();

    if (!user) {
      return res.status(404).json({ message: 'Пользователь не найден' });
    }

    res.json({ user, avatarUrl });
  } catch (error) {
    console.error('Ошибка загрузки аватара:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

