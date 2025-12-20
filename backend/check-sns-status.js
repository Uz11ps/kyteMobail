// Скрипт для проверки статуса AWS SNS Sandbox режима
import dotenv from 'dotenv';
dotenv.config();

import AWS from 'aws-sdk';

const sns = new AWS.SNS({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION || 'us-east-1',
});

console.log('🔍 Проверка статуса AWS SNS...\n');

// Проверка атрибутов аккаунта
sns.getSMSAttributes({}, (err, data) => {
  if (err) {
    console.error('❌ Ошибка получения атрибутов:', err);
    return;
  }
  
  console.log('📋 Атрибуты SMS:');
  console.log(JSON.stringify(data, null, 2));
  
  // Проверка Sandbox режима
  const sandboxMode = data.attributes?.DefaultSMSType === 'Promotional';
  if (sandboxMode) {
    console.log('\n⚠️  ВНИМАНИЕ: Возможно, аккаунт находится в Sandbox режиме!');
    console.log('   SMS будут отправляться только на верифицированные номера.');
    console.log('   Для production доступа нужно запросить его в AWS Console.');
  }
});

// Попытка получить список верифицированных номеров
sns.listPhoneNumbersOptedOut({}, (err, data) => {
  if (err) {
    console.log('\n⚠️  Не удалось получить список отписанных номеров:', err.message);
  } else {
    console.log('\n📱 Отписанные номера:', data.phoneNumbers?.length || 0);
  }
});

