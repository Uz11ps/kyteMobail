import jwt from 'jsonwebtoken';

// Простая проверка админ-сессии через JWT
export const adminAuth = (req, res, next) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '') || 
                  req.cookies?.adminToken ||
                  req.query?.token;

    if (!token) {
      return res.status(401).json({ 
        error: 'Требуется аутентификация админа',
        code: 'ADMIN_AUTH_REQUIRED'
      });
    }

    // Проверяем токен (используем JWT_SECRET с префиксом admin)
    const decoded = jwt.verify(token, process.env.JWT_SECRET + '_admin');
    
    if (!decoded.isAdmin) {
      return res.status(403).json({ 
        error: 'Доступ запрещен',
        code: 'ADMIN_ACCESS_DENIED'
      });
    }

    req.admin = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ 
      error: 'Недействительный токен админа',
      code: 'INVALID_ADMIN_TOKEN'
    });
  }
};

