import { User } from '../models/User.js';
import { generateTokens, verifyToken } from '../utils/jwt.js';
import { encrypt } from '../utils/encryption.js';

export const login = async (req, res) => {
  try {
    const { email, password, phone, code } = req.body;

    let user;
    
    if (email && password) {
      // Вход по email/паролю
      user = await User.findOne({ email: email.toLowerCase() });
      if (!user || !user.password) {
        return res.status(401).json({ message: 'Неверный email или пароль' });
      }

      const isPasswordValid = await user.comparePassword(password);
      if (!isPasswordValid) {
        return res.status(401).json({ message: 'Неверный email или пароль' });
      }
    } else if (phone && code) {
      // Вход по телефону/коду (упрощенная версия для MVP)
      user = await User.findOne({ phone });
      if (!user) {
        return res.status(401).json({ message: 'Пользователь не найден' });
      }
      // В реальном приложении здесь должна быть проверка кода через SMS сервис
    } else {
      return res.status(400).json({ message: 'Необходимо указать email/пароль или телефон/код' });
    }

    const { accessToken, refreshToken } = generateTokens(user._id.toString());

    res.json({
      user: {
        id: user._id.toString(),
        email: user.email,
        phone: user.phone,
        name: user.name,
        avatarUrl: user.avatarUrl,
      },
      accessToken,
      refreshToken,
    });
  } catch (error) {
    console.error('Ошибка входа:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

export const register = async (req, res) => {
  try {
    const { email, password, name } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email и пароль обязательны' });
    }

    // Проверка существования пользователя
    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(400).json({ message: 'Пользователь с таким email уже существует' });
    }

    // Создание нового пользователя
    const user = new User({
      email: email.toLowerCase(),
      password,
      name: name || null,
    });

    await user.save();

    const { accessToken, refreshToken } = generateTokens(user._id.toString());

    res.status(201).json({
      user: {
        id: user._id.toString(),
        email: user.email,
        name: user.name,
      },
      accessToken,
      refreshToken,
    });
  } catch (error) {
    console.error('Ошибка регистрации:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

export const refreshToken = async (req, res) => {
  try {
    const { refreshToken: token } = req.body;

    if (!token) {
      return res.status(400).json({ message: 'Refresh token не предоставлен' });
    }

    const decoded = verifyToken(token, true);
    const user = await User.findById(decoded.userId);

    if (!user) {
      return res.status(401).json({ message: 'Пользователь не найден' });
    }

    const { accessToken, refreshToken: newRefreshToken } = generateTokens(user._id.toString());

    res.json({
      accessToken,
      refreshToken: newRefreshToken,
    });
  } catch (error) {
    console.error('Ошибка обновления токена:', error);
    res.status(401).json({ message: 'Недействительный refresh token' });
  }
};

export const submitGmailToken = async (req, res) => {
  try {
    const { token } = req.body;
    const userId = req.user._id;

    if (!token) {
      return res.status(400).json({ message: 'Токен не предоставлен' });
    }

    // Шифрование и сохранение токена
    const encryptedToken = encrypt(token);
    await User.findByIdAndUpdate(userId, {
      gmailOAuthToken: encryptedToken,
    });

    res.json({ success: true, message: 'Токен успешно сохранен' });
  } catch (error) {
    console.error('Ошибка сохранения Gmail токена:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

