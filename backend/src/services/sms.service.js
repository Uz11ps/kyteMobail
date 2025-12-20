/**
 * SMS Service
 * Поддерживает разные провайдеры: Twilio, AWS SNS, Sms.ru
 * Для разработки можно использовать мок-режим
 */

class SMSService {
  constructor() {
    this.provider = process.env.SMS_PROVIDER || 'mock'; // mock, twilio, aws, smsru
    this.initProvider();
  }

  initProvider() {
    switch (this.provider) {
      case 'twilio':
        this.sendSMS = this.sendViaTwilio;
        break;
      case 'aws':
        this.sendSMS = this.sendViaAWS;
        break;
      case 'smsru':
        this.sendSMS = this.sendViaSmsRu;
        break;
      case 'mock':
      default:
        this.sendSMS = this.sendViaMock;
        console.log('📱 SMS Service: Используется мок-режим. SMS не будут отправляться реально.');
        break;
    }
  }

  /**
   * Отправка SMS кода
   * @param {string} phone - Номер телефона в формате +79991234567
   * @param {string} code - Код подтверждения
   * @returns {Promise<{success: boolean, message?: string}>}
   */
  async sendVerificationCode(phone, code) {
    try {
      const message = `Ваш код подтверждения: ${code}. Не сообщайте его никому.`;
      return await this.sendSMS(phone, message);
    } catch (error) {
      console.error('Ошибка отправки SMS:', error);
      return { success: false, message: 'Ошибка отправки SMS' };
    }
  }

  /**
   * Мок-режим (для разработки)
   */
  async sendViaMock(phone, message) {
    console.log(`📱 [MOCK SMS] Отправка на ${phone}: ${message}`);
    // В мок-режиме всегда успешно
    return { success: true, message: 'SMS отправлено (мок-режим)' };
  }

  /**
   * Отправка через Twilio
   */
  async sendViaTwilio(phone, message) {
    // Динамический импорт для ES modules
    const twilioModule = await import('twilio');
    const twilio = twilioModule.default || twilioModule;
    const accountSid = process.env.TWILIO_ACCOUNT_SID;
    const authToken = process.env.TWILIO_AUTH_TOKEN;
    const fromNumber = process.env.TWILIO_PHONE_NUMBER;

    if (!accountSid || !authToken || !fromNumber) {
      throw new Error('Twilio credentials не настроены');
    }

    const client = twilio(accountSid, authToken);

    const result = await client.messages.create({
      body: message,
      from: fromNumber,
      to: phone,
    });

    return { success: true, sid: result.sid };
  }

  /**
   * Отправка через AWS SNS
   * Поддерживает отправку в Россию и Казахстан
   */
  async sendViaAWS(phone, message) {
    // Динамический импорт для ES modules
    const AWSModule = await import('aws-sdk');
    const AWS = AWSModule.default || AWSModule;
    
    const accessKeyId = process.env.AWS_ACCESS_KEY_ID;
    const secretAccessKey = process.env.AWS_SECRET_ACCESS_KEY;
    const region = process.env.AWS_REGION || 'us-east-1';

    if (!accessKeyId || !secretAccessKey) {
      throw new Error('AWS credentials не настроены');
    }

    const sns = new AWS.SNS({
      accessKeyId,
      secretAccessKey,
      region,
    });

    const params = {
      Message: message,
      PhoneNumber: phone,
      // Для России и Казахстана может потребоваться указать тип сообщения
      MessageAttributes: {
        'AWS.SNS.SMS.SMSType': {
          DataType: 'String',
          StringValue: 'Transactional', // Transactional для важных сообщений (коды подтверждения)
        },
      },
    };

    try {
      const result = await sns.publish(params).promise();
      console.log(`✅ SMS отправлено через AWS SNS. MessageId: ${result.MessageId}, Phone: ${phone}`);
      return { success: true, messageId: result.MessageId };
    } catch (error) {
      console.error('❌ Ошибка отправки SMS через AWS SNS:', error);
      // Более детальная обработка ошибок
      if (error.code === 'InvalidParameter') {
        throw new Error(`Неверный формат номера телефона: ${phone}`);
      } else if (error.code === 'Throttling') {
        throw new Error('Превышен лимит отправки SMS. Попробуйте позже.');
      } else if (error.code === 'OptedOut') {
        throw new Error('Номер телефона отписан от получения SMS.');
      } else {
        throw new Error(`Ошибка AWS SNS: ${error.message || error.code || 'Неизвестная ошибка'}`);
      }
    }
  }

  /**
   * Отправка через Sms.ru
   */
  async sendViaSmsRu(phone, message) {
    // Динамический импорт для ES modules
    const axiosModule = await import('axios');
    const axios = axiosModule.default || axiosModule;
    const apiId = process.env.SMSRU_API_ID;

    if (!apiId) {
      throw new Error('SMS.ru API ID не настроен');
    }

    const response = await axios.post('https://sms.ru/sms/send', null, {
      params: {
        api_id: apiId,
        to: phone,
        msg: message,
        json: 1,
      },
    });

    if (response.data.status === 'OK') {
      return { success: true, smsId: response.data.sms[phone] };
    } else {
      throw new Error(response.data.status_text || 'Ошибка отправки SMS');
    }
  }

  /**
   * Валидация номера телефона
   * Поддерживает Россию (+7) и Казахстан (+7)
   * @param {string} phone - Номер телефона
   * @returns {{valid: boolean, normalized?: string, error?: string}}
   */
  validatePhone(phone) {
    if (!phone) {
      return { valid: false, error: 'Номер телефона не указан' };
    }

    // Удаляем все нецифровые символы кроме +
    let normalized = phone.replace(/[^\d+]/g, '');

    // Если номер начинается с 8, заменяем на +7 (Россия/Казахстан)
    if (normalized.startsWith('8')) {
      normalized = '+7' + normalized.substring(1);
    }

    // Если номер начинается с 7, добавляем +
    if (normalized.startsWith('7') && !normalized.startsWith('+7')) {
      normalized = '+' + normalized;
    }

    // Если номер не начинается с +, добавляем +7 для российских/казахстанских номеров
    if (!normalized.startsWith('+')) {
      normalized = '+7' + normalized;
    }

    // Проверка формата: +7XXXXXXXXXX (11 цифр после +7)
    // Поддерживает как российские, так и казахстанские номера
    const phoneRegex = /^\+7\d{10}$/;
    if (!phoneRegex.test(normalized)) {
      return { valid: false, error: 'Неверный формат номера телефона. Используйте формат: +79991234567 (Россия) или +77001234567 (Казахстан)' };
    }

    return { valid: true, normalized };
  }
}

// Ленивая инициализация для правильной загрузки переменных окружения
let _smsServiceInstance = null;

export const smsService = (() => {
  if (!_smsServiceInstance) {
    _smsServiceInstance = new SMSService();
  }
  return _smsServiceInstance;
})();

