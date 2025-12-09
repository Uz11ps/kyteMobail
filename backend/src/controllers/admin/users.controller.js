import { User } from '../../models/User.js';

export const getUsers = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;
    const search = req.query.search || '';

    const query = {};
    if (search) {
      query.$or = [
        { email: { $regex: search, $options: 'i' } },
        { name: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
      ];
    }

    const [users, total] = await Promise.all([
      User.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      User.countDocuments(query),
    ]);

    res.json({
      success: true,
      data: users,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    console.error('Ошибка получения пользователей:', error);
    res.status(500).json({ 
      error: 'Ошибка получения пользователей',
      code: 'SERVER_ERROR'
    });
  }
};

export const getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).lean();
    
    if (!user) {
      return res.status(404).json({ 
        error: 'Пользователь не найден',
        code: 'USER_NOT_FOUND'
      });
    }

    res.json({
      success: true,
      data: user,
    });
  } catch (error) {
    console.error('Ошибка получения пользователя:', error);
    res.status(500).json({ 
      error: 'Ошибка получения пользователя',
      code: 'SERVER_ERROR'
    });
  }
};

export const updateUser = async (req, res) => {
  try {
    const { name, email, phone, avatarUrl } = req.body;
    
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { 
        ...(name && { name }),
        ...(email && { email }),
        ...(phone && { phone }),
        ...(avatarUrl && { avatarUrl }),
        updatedAt: Date.now(),
      },
      { new: true, runValidators: true }
    ).lean();

    if (!user) {
      return res.status(404).json({ 
        error: 'Пользователь не найден',
        code: 'USER_NOT_FOUND'
      });
    }

    res.json({
      success: true,
      data: user,
    });
  } catch (error) {
    console.error('Ошибка обновления пользователя:', error);
    res.status(500).json({ 
      error: 'Ошибка обновления пользователя',
      code: 'SERVER_ERROR'
    });
  }
};

export const deleteUser = async (req, res) => {
  try {
    const user = await User.findByIdAndDelete(req.params.id);
    
    if (!user) {
      return res.status(404).json({ 
        error: 'Пользователь не найден',
        code: 'USER_NOT_FOUND'
      });
    }

    res.json({
      success: true,
      message: 'Пользователь удален',
    });
  } catch (error) {
    console.error('Ошибка удаления пользователя:', error);
    res.status(500).json({ 
      error: 'Ошибка удаления пользователя',
      code: 'SERVER_ERROR'
    });
  }
};

