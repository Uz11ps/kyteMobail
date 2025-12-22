/**
 * SMS Service
 * Поддерживает разные провайдеры: Twilio, AWS SNS, Sms.ru
 * Для разработки можно использовать мок-режим
 */

class SMSService {
  constructor() {
    // Логируем переменные окружения для отладки
    console.log('🔍 SMSService constructor: SMS_PROVIDER =', process.env.SMS_PROVIDER);
    console.log('🔍 SMSService constructor: AWS_ACCESS_KEY_ID =', process.env.AWS_ACCESS_KEY_ID ? 'SET' : 'NOT SET');
    console.log('🔍 SMSService constructor: AWS_SECRET_ACCESS_KEY =', process.env.AWS_SECRET_ACCESS_KEY ? 'SET' : 'NOT SET');
    console.log('🔍 SMSService constructor: AWS_REGION =', process.env.AWS_REGION);
    console.log('🔍 SMSService constructor: SMSRU_API_ID =', process.env.SMSRU_API_ID ? 'SET' : 'NOT SET');
    
    this.provider = process.env.SMS_PROVIDER || 'mock'; // mock, twilio, aws, smsru
    this.initProvider();
  }

  initProvider() {
    switch (this.provider) {
      case 'twilio':
        this.sendSMS = this.sendViaTwilio;
        console.log('📱 SMS Service: Используется Twilio для отправки SMS.');
        break;
      case 'aws':
        this.sendSMS = this.sendViaAWS;
        console.log('📱 SMS Service: Используется AWS SNS для отправки SMS.');
        break;
      case 'smsru':
        this.sendSMS = this.sendViaSmsRu;
        console.log('📱 SMS Service: Используется Sms.ru для отправки SMS.');
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
      console.log('📱 sendVerificationCode вызван для номера:', phone);
      console.log('📱 Текущий провайдер:', this.provider);
      console.log('📱 SMS_PROVIDER из env:', process.env.SMS_PROVIDER);
      const message = `Ваш код подтверждения: ${code}. Не сообщайте его никому.`;
      console.log('📱 Вызов sendSMS...');
      const result = await this.sendSMS(phone, message);
      console.log('📱 Результат sendSMS:', result);
      return result;
    } catch (error) {
      console.error('❌ Ошибка отправки SMS:', error);
      console.error('❌ Stack:', error.stack);
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
    console.log('📤 Отправка SMS через AWS SNS на номер:', phone);
    // Динамический импорт для ES modules
    const AWSModule = await import('aws-sdk');
    const AWS = AWSModule.default || AWSModule;
    
    const accessKeyId = process.env.AWS_ACCESS_KEY_ID;
    const secretAccessKey = process.env.AWS_SECRET_ACCESS_KEY;
    const region = process.env.AWS_REGION || 'us-east-1';

    console.log('🔍 AWS Config: region =', region, 'accessKeyId =', accessKeyId ? 'SET' : 'NOT SET');

    if (!accessKeyId || !secretAccessKey) {
      console.error('❌ AWS credentials не настроены');
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
      console.log(`📋 Полный ответ AWS SNS:`, JSON.stringify(result, null, 2));
      return { success: true, messageId: result.MessageId };
    } catch (error) {
      console.error('❌ Ошибка отправки SMS через AWS SNS:');
      console.error('   Код ошибки:', error.code);
      console.error('   Сообщение:', error.message);
      console.error('   Статус код:', error.statusCode);
      console.error('   Полная ошибка:', JSON.stringify(error, null, 2));
      
      // Более детальная обработка ошибок
      if (error.code === 'InvalidParameter') {
        throw new Error(`Неверный формат номера телефона: ${phone}. Детали: ${error.message}`);
      } else if (error.code === 'Throttling') {
        throw new Error('Превышен лимит отправки SMS. Попробуйте позже.');
      } else if (error.code === 'OptedOut') {
        throw new Error('Номер телефона отписан от получения SMS.');
      } else if (error.code === 'AuthorizationError') {
        throw new Error('Ошибка авторизации AWS. Проверьте credentials и права доступа.');
      } else if (error.message && error.message.includes('Sandbox')) {
        throw new Error('AWS SNS находится в Sandbox режиме. Нужно запросить production доступ или добавить номер в список верифицированных.');
      } else {
        throw new Error(`Ошибка AWS SNS: ${error.message || error.code || 'Неизвестная ошибка'}`);
      }
    }
  }

  /**
   * Отправка через Sms.ru
   * SMS.ru требует номер телефона без знака +, только цифры (формат: 79991234567)
   */
  async sendViaSmsRu(phone, message) {
    console.log('📤 Отправка SMS через SMS.ru на номер:', phone);
    
    // Динамический импорт для ES modules
    const axiosModule = await import('axios');
    const axios = axiosModule.default || axiosModule;
    const apiId = process.env.SMSRU_API_ID;

    if (!apiId) {
      console.error('❌ SMS.ru API ID не настроен');
      throw new Error('SMS.ru API ID не настроен');
    }

    // SMS.ru требует номер без знака +, только цифры
    // Преобразуем +79991234567 в 79991234567
    const phoneWithoutPlus = phone.replace(/^\+/, '');
    
    console.log('🔍 SMS.ru: Номер для отправки:', phoneWithoutPlus);
    console.log('🔍 SMS.ru: Сообщение:', message);

    try {
      const response = await axios.post('https://sms.ru/sms/send', null, {
        params: {
          api_id: apiId,
          to: phoneWithoutPlus,
          msg: message,
          json: 1,
        },
      });

      console.log('📋 SMS.ru ответ:', JSON.stringify(response.data, null, 2));

      if (response.data.status === 'OK') {
        // Проверяем статус конкретного SMS
        const smsData = response.data.sms && response.data.sms[phoneWithoutPlus];
        if (smsData) {
          if (smsData.status === 'OK' || smsData.status_code === 100) {
            const smsId = smsData.sms_id || null;
            console.log(`✅ SMS отправлено через SMS.ru. SMS ID: ${smsId}, Phone: ${phone}`);
            return { success: true, smsId };
          } else {
            // Ошибка для конкретного номера
            const errorText = smsData.status_text || `Ошибка отправки SMS (код: ${smsData.status_code})`;
            console.error('❌ SMS.ru ошибка для номера:', errorText);
            throw new Error(errorText);
          }
        } else {
          // Если нет данных о конкретном SMS, но общий статус OK
          console.log(`✅ SMS отправлено через SMS.ru. Phone: ${phone}`);
          return { success: true };
        }
      } else {
        const errorText = response.data.status_text || 'Ошибка отправки SMS';
        console.error('❌ SMS.ru ошибка:', errorText);
        throw new Error(errorText);
      }
    } catch (error) {
      console.error('❌ Ошибка отправки SMS через SMS.ru:');
      console.error('   Сообщение:', error.message);
      if (error.response) {
        console.error('   Статус:', error.response.status);
        console.error('   Данные:', JSON.stringify(error.response.data, null, 2));
      }
      
      if (error.response && error.response.data) {
        const errorText = error.response.data.status_text || error.message;
        throw new Error(`Ошибка SMS.ru: ${errorText}`);
      }
      throw new Error(`Ошибка SMS.ru: ${error.message || 'Неизвестная ошибка'}`);
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

// Используем геттер вместо IIFE для ленивой инициализации
export const smsService = {
  get instance() {
    if (!_smsServiceInstance) {
      _smsServiceInstance = new SMSService();
    }
    return _smsServiceInstance;
  },
  // Проксируем методы для удобства использования
  sendVerificationCode(phone, code) {
    // Логируем при первом использовании
    if (!_smsServiceInstance) {
      console.log('🔍 Первое использование SMS сервиса');
      console.log('🔍 SMS_PROVIDER:', process.env.SMS_PROVIDER);
      console.log('🔍 SMSRU_API_ID:', process.env.SMSRU_API_ID ? 'SET' : 'NOT SET');
    }
    return this.instance.sendVerificationCode(phone, code);
  },
  validatePhone(phone) {
    return this.instance.validatePhone(phone);
  },
};

