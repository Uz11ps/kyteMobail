// Тестовый скрипт для отправки SMS через AWS SNS
import dotenv from 'dotenv';
dotenv.config();

import AWS from 'aws-sdk';

const sns = new AWS.SNS({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION || 'us-east-1',
});

const phoneNumber = process.argv[2] || '+79686288842';
const message = process.argv[3] || 'Тестовое сообщение от AWS SNS';

const params = {
  Message: message,
  PhoneNumber: phoneNumber,
  MessageAttributes: {
    'AWS.SNS.SMS.SMSType': {
      DataType: 'String',
      StringValue: 'Transactional',
    },
  },
};

console.log('📤 Отправка SMS на номер:', phoneNumber);
console.log('📝 Сообщение:', message);

sns.publish(params, (err, data) => {
  if (err) {
    console.error('❌ Ошибка отправки SMS:', err);
  } else {
    console.log('✅ SMS отправлено успешно!');
    console.log('📋 MessageId:', data.MessageId);
  }
});

