import mongoose from 'mongoose';

const phoneVerificationSchema = new mongoose.Schema({
  phone: {
    type: String,
    required: true,
    index: true,
  },
  code: {
    type: String,
    required: true,
  },
  attempts: {
    type: Number,
    default: 0,
  },
  maxAttempts: {
    type: Number,
    default: 5,
  },
  expiresAt: {
    type: Date,
    required: true,
    index: { expireAfterSeconds: 0 }, // Автоматическое удаление после истечения
  },
  verified: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

// Метод для проверки кода
phoneVerificationSchema.methods.verifyCode = function(inputCode) {
  if (this.verified) {
    return { success: false, message: 'Код уже использован' };
  }
  
  if (this.expiresAt < new Date()) {
    return { success: false, message: 'Код истек' };
  }
  
  if (this.attempts >= this.maxAttempts) {
    return { success: false, message: 'Превышено количество попыток' };
  }
  
  this.attempts += 1;
  
  if (this.code !== inputCode) {
    return { success: false, message: 'Неверный код', attemptsLeft: this.maxAttempts - this.attempts };
  }
  
  this.verified = true;
  return { success: true };
};

// Статический метод для генерации кода
phoneVerificationSchema.statics.generateCode = function() {
  // Генерируем 6-значный код
  return Math.floor(100000 + Math.random() * 900000).toString();
};

export const PhoneVerification = mongoose.model('PhoneVerification', phoneVerificationSchema);








