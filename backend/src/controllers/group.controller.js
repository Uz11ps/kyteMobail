import { Chat } from '../models/Chat.js';
import { User } from '../models/User.js';

export const createGroup = async (req, res) => {
  try {
    const { name, participantIds } = req.body;
    const userId = req.user._id;

    if (!name || !name.trim()) {
      return res.status(400).json({ message: 'Название группы обязательно' });
    }

    // Проверка существования участников
    const participants = [userId.toString(), ...(participantIds || [])];
    const uniqueParticipants = [...new Set(participants)];

    const users = await User.find({
      _id: { $in: uniqueParticipants },
    });

    if (users.length !== uniqueParticipants.length) {
      return res.status(400).json({ message: 'Один или несколько участников не найдены' });
    }

    // Создание группы
    const group = new Chat({
      name: name.trim(),
      type: 'group',
      participants: uniqueParticipants,
      createdBy: userId,
    });

    await group.save();

    const populatedGroup = await Chat.findById(group._id)
      .populate('participants', 'email name avatarUrl')
      .lean();

    res.status(201).json({
      group: {
        id: populatedGroup._id.toString(),
        name: populatedGroup.name,
        type: populatedGroup.type,
        participantIds: populatedGroup.participants.map(p => p._id.toString()),
        inviteCode: populatedGroup.inviteCode,
        createdAt: populatedGroup.createdAt,
      },
    });
  } catch (error) {
    console.error('Ошибка создания группы:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

export const joinGroup = async (req, res) => {
  try {
    const { inviteCode } = req.body;
    const userId = req.user._id;

    if (!inviteCode) {
      return res.status(400).json({ message: 'Код приглашения обязателен' });
    }

    const group = await Chat.findOne({ inviteCode });

    if (!group) {
      return res.status(404).json({ message: 'Группа не найдена' });
    }

    // Проверка, не является ли пользователь уже участником
    if (group.participants.includes(userId)) {
      return res.status(400).json({ message: 'Вы уже являетесь участником этой группы' });
    }

    // Добавление пользователя в группу
    group.participants.push(userId);
    await group.save();

    const populatedGroup = await Chat.findById(group._id)
      .populate('participants', 'email name avatarUrl')
      .lean();

    res.json({
      group: {
        id: populatedGroup._id.toString(),
        name: populatedGroup.name,
        type: populatedGroup.type,
        participantIds: populatedGroup.participants.map(p => p._id.toString()),
        inviteCode: populatedGroup.inviteCode,
        createdAt: populatedGroup.createdAt,
      },
    });
  } catch (error) {
    console.error('Ошибка присоединения к группе:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
};

