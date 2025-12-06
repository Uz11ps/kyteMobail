import mongoose from 'mongoose';

export const connectDatabase = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/kyte_chat');
    console.log(`✅ MongoDB подключена: ${conn.connection.host}`);
    console.log(`📊 База данных: ${conn.connection.name}`);
    return conn;
  } catch (error) {
    console.error('❌ Ошибка подключения к MongoDB:', error.message);
    console.error('Проверьте MONGODB_URI в файле .env');
    process.exit(1);
  }
};

