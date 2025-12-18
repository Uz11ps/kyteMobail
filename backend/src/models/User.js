import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
  },
  phone: {
    type: String,
    sparse: true,
    unique: true,
  },
  password: {
    type: String,
    required: function() {
      return !this.phone; // Пароль не обязателен если есть телефон
    },
  },
  name: {
    type: String,
    trim: true,
  },
  nickname: {
    type: String,
    trim: true,
  },
  about: {
    type: String,
    trim: true,
  },
  birthday: {
    type: Date,
  },
  avatarUrl: {
    type: String,
  },
  gmailOAuthToken: {
    type: String,
    encrypted: true,
  },
  googleId: {
    type: String,
    sparse: true,
    unique: true,
  },
  fcmToken: {
    type: String,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
});

// Хеширование пароля перед сохранением
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

// Метод для проверки пароля
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Метод для преобразования в JSON (без пароля)
userSchema.methods.toJSON = function() {
  const obj = this.toObject();
  delete obj.password;
  delete obj.gmailOAuthToken;
  return obj;
};

export const User = mongoose.model('User', userSchema);

