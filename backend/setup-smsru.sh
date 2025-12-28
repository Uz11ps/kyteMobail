#!/bin/bash
# Скрипт для настройки SMS.ru на сервере

echo "🔧 Настройка SMS.ru..."

cd /var/www/kyte-backend/backend || exit 1

# Добавить настройки SMS.ru в .env
echo "" >> .env
echo "SMS_PROVIDER=smsru" >> .env
echo "SMSRU_API_ID=2BD84383-DDFD-B4E3-A588-5908F91C3927" >> .env

echo "✅ Настройки добавлены в .env"

# Проверить что добавилось
echo ""
echo "📋 Проверка настроек:"
cat .env | grep -E "SMS|SMSRU"

# Установить axios если его нет
echo ""
echo "📦 Проверка зависимостей..."
if ! npm list axios > /dev/null 2>&1; then
    echo "Установка axios..."
    npm install axios
else
    echo "✅ axios уже установлен"
fi

# Остановить все процессы Node.js
echo ""
echo "🛑 Остановка процессов Node.js..."
sudo killall node || true
sleep 2

# Перезапустить через PM2
echo ""
echo "🚀 Перезапуск PM2..."
pm2 delete kyte-backend || true
pm2 start src/server.js --name kyte-backend --update-env
pm2 save

# Подождать запуска
sleep 3

# Проверить логи
echo ""
echo "📋 Последние логи SMS сервиса:"
pm2 logs kyte-backend --lines 20 --nostream | grep -E "SMS|📱|📤|❌|✅" | tail -10

echo ""
echo "✅ Настройка завершена!"
echo ""
echo "Для проверки отправьте тестовый запрос:"
echo "curl -X POST http://94.131.88.135/api/auth/phone/send-code \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"phone\": \"+79686288842\"}'"

