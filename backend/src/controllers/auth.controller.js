import { User } from '../models/User.js';
import { PhoneVerification } from '../models/PhoneVerification.js';
import { generateTokens, verifyToken } from '../utils/jwt.js';
import { encrypt } from '../utils/encryption.js';
import { smsService } from '../services/sms.service.js';

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

// Google OAuth авторизация
export const googleAuth = async (req, res) => {
  try {
    const { idToken, accessToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ message: 'ID токен не предоставлен' });
    }

    // В реальном приложении здесь нужно проверить токен через Google API
    // Для MVP используем упрощенную версию - декодируем токен (без проверки подписи)
    // В продакшене используйте библиотеку google-auth-library или проверяйте через Google API
    
    // Упрощенная версия: ожидаем что клиент отправляет email и name из Google аккаунта
    const { email, name, picture, googleId } = req.body;

    if (!email) {
      return res.status(400).json({ message: 'Email не предоставлен' });
    }

    // Ищем пользователя по email или googleId
    let user = await User.findOne({
      $or: [
        { email: email.toLowerCase() },
        { googleId: googleId || idToken.substring(0, 20) }, // Временное решение для MVP
      ],
    });

    if (!user) {
      // Создаем нового пользователя
      user = new User({
        email: email.toLowerCase(),
        name: name || null,
        avatarUrl: picture || null,
        googleId: googleId || idToken.substring(0, 20),
        // Пароль не требуется для Google OAuth пользователей
      });
      await user.save();
    } else {
      // Обновляем данные пользователя если нужно
      if (!user.googleId && googleId) {
        user.googleId = googleId;
      }
      if (!user.avatarUrl && picture) {
        user.avatarUrl = picture;
      }
      if (!user.name && name) {
        user.name = name;
      }
      await user.save();
    }

    const { accessToken: jwtAccessToken, refreshToken } = generateTokens(user._id.toString());

    res.json({
      user: {
        id: user._id.toString(),
        email: user.email,
        phone: user.phone,
        name: user.name,
        avatarUrl: user.avatarUrl,
      },
      accessToken: jwtAccessToken,
      refreshToken,
    });
  } catch (error) {
    console.error('Ошибка Google авторизации:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

/**
 * Отправка SMS кода для регистрации/входа по телефону
 * POST /api/auth/phone/send-code
 */
export const sendPhoneCode = async (req, res) => {
  try {
    const { phone } = req.body;

    if (!phone) {
      return res.status(400).json({ message: 'Номер телефона не указан' });
    }

    // Валидация и нормализация номера
    const validation = smsService.validatePhone(phone);
    if (!validation.valid) {
      return res.status(400).json({ message: validation.error });
    }

    const normalizedPhone = validation.normalized;

    // Проверка лимита отправки (не более 3 кодов в час)
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const recentCodes = await PhoneVerification.countDocuments({
      phone: normalizedPhone,
      createdAt: { $gte: oneHourAgo },
    });

    if (recentCodes >= 3) {
      return res.status(429).json({ 
        message: 'Превышен лимит запросов. Попробуйте позже.' 
      });
    }

    // Генерируем код
    const code = PhoneVerification.generateCode();

    // Удаляем старые неиспользованные коды для этого номера
    await PhoneVerification.deleteMany({
      phone: normalizedPhone,
      verified: false,
    });

    // Создаем новую запись верификации (код действителен 10 минут)
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);
    const verification = new PhoneVerification({
      phone: normalizedPhone,
      code,
      expiresAt,
    });

    await verification.save();

    // Отправляем SMS
    const smsResult = await smsService.sendVerificationCode(normalizedPhone, code);

    if (!smsResult.success) {
      return res.status(500).json({ message: smsResult.message || 'Ошибка отправки SMS' });
    }

    // В мок-режиме возвращаем код для тестирования
    const response = {
      success: true,
      message: 'Код отправлен',
      expiresIn: 600, // секунды
    };

    // В мок-режиме или для разработки возвращаем код
    if (process.env.SMS_PROVIDER === 'mock' || process.env.NODE_ENV === 'development') {
      response.code = code; // Только для разработки!
    }

    res.json(response);
  } catch (error) {
    console.error('Ошибка отправки SMS кода:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

/**
 * Проверка SMS кода и регистрация/вход по телефону
 * POST /api/auth/phone/verify-code
 */
export const verifyPhoneCode = async (req, res) => {
  try {
    const { phone, code, name } = req.body;

    if (!phone || !code) {
      return res.status(400).json({ message: 'Номер телефона и код обязательны' });
    }

    // Валидация и нормализация номера
    const validation = smsService.validatePhone(phone);
    if (!validation.valid) {
      return res.status(400).json({ message: validation.error });
    }

    const normalizedPhone = validation.normalized;

    // Находим актуальную верификацию
    const verification = await PhoneVerification.findOne({
      phone: normalizedPhone,
      verified: false,
    }).sort({ createdAt: -1 });

    if (!verification) {
      return res.status(400).json({ message: 'Код не найден. Запросите новый код.' });
    }

    // Проверяем код
    const verifyResult = verification.verifyCode(code);
    await verification.save();

    if (!verifyResult.success) {
      return res.status(400).json({ 
        message: verifyResult.message,
        attemptsLeft: verifyResult.attemptsLeft,
      });
    }

    // Ищем существующего пользователя
    let user = await User.findOne({ phone: normalizedPhone });

    if (!user) {
      // Регистрация нового пользователя
      user = new User({
        phone: normalizedPhone,
        name: name || null,
        // Email не обязателен для регистрации по телефону
        email: `phone_${normalizedPhone.replace(/[^\d]/g, '')}@temp.kyte.me`, // Временный email
      });
      await user.save();
    }

    // Генерируем токены
    const { accessToken, refreshToken } = generateTokens(user._id.toString());

    // Удаляем использованный код
    await PhoneVerification.deleteOne({ _id: verification._id });

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
    console.error('Ошибка верификации кода:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

