import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';

// Простой админ-логин (можно расширить для использования БД)
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'admin@kyte.com';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'admin123';

export const adminLogin = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ 
        error: 'Email и пароль обязательны',
        code: 'MISSING_CREDENTIALS'
      });
    }

    // Простая проверка (в production лучше использовать БД)
    if (email !== ADMIN_EMAIL) {
      return res.status(401).json({ 
        error: 'Неверный email или пароль',
        code: 'INVALID_CREDENTIALS'
      });
    }

    // Проверка пароля
    // Сначала проверяем прямой пароль (для первого входа)
    // Затем проверяем хешированный (если пароль был изменен)
    let isValidPassword = false;
    
    if (password === ADMIN_PASSWORD) {
      isValidPassword = true;
    } else {
      // Если пароль не совпадает напрямую, проверяем хеш
      // (для случая когда пароль был изменен в .env)
      try {
        const passwordHash = await bcrypt.hash(ADMIN_PASSWORD, 10);
        isValidPassword = await bcrypt.compare(password, passwordHash);
      } catch (err) {
        isValidPassword = false;
      }
    }

    if (!isValidPassword) {
      return res.status(401).json({ 
        error: 'Неверный email или пароль',
        code: 'INVALID_CREDENTIALS'
      });
    }

    // Генерируем JWT токен для админа
    const token = jwt.sign(
      { 
        email: ADMIN_EMAIL, 
        isAdmin: true,
        type: 'admin'
      },
      process.env.JWT_SECRET + '_admin',
      { expiresIn: '24h' }
    );

    res.json({
      success: true,
      token,
      admin: {
        email: ADMIN_EMAIL,
      }
    });
  } catch (error) {
    console.error('Ошибка админ-логина:', error);
    res.status(500).json({ 
      error: 'Ошибка сервера при входе',
      code: 'SERVER_ERROR'
    });
  }
};

export const adminLogout = (req, res) => {
  res.json({ 
    success: true, 
    message: 'Выход выполнен успешно' 
  });
};

