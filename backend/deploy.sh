#!/bin/bash

# Скрипт деплоя backend на сервер
# Используется GitHub Actions или локально

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Конфигурация
APP_DIR="/var/www/kyte-backend/backend"
BACKUP_DIR="${APP_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
PM2_APP_NAME="kyte-backend"

echo -e "${GREEN}🚀 Начинаем деплой backend...${NC}"

# Проверка что мы в правильной директории
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ Ошибка: package.json не найден. Запустите скрипт из директории backend${NC}"
    exit 1
fi

# Создаем backup
echo -e "${YELLOW}📦 Создаем backup...${NC}"
if [ -d "$APP_DIR" ]; then
    sudo cp -r "$APP_DIR" "$BACKUP_DIR"
    echo -e "${GREEN}✅ Backup создан: $BACKUP_DIR${NC}"
fi

# Останавливаем приложение
echo -e "${YELLOW}⏸️  Останавливаем приложение...${NC}"
sudo pm2 stop "$PM2_APP_NAME" || echo -e "${YELLOW}⚠️  Приложение не было запущено${NC}"

# Устанавливаем зависимости
echo -e "${YELLOW}📦 Устанавливаем зависимости...${NC}"
npm install --production --no-audit --no-fund

# Копируем файлы
echo -e "${YELLOW}📤 Копируем файлы...${NC}"
sudo mkdir -p "$APP_DIR"
sudo cp -r . "$APP_DIR/"
sudo chown -R $(whoami):$(whoami) "$APP_DIR" || true

# Сохраняем .env если он существует
if [ -f "$APP_DIR/.env" ]; then
    echo -e "${YELLOW}💾 Сохраняем .env файл...${NC}"
    sudo cp "$APP_DIR/.env" "$APP_DIR/.env.backup"
fi

# Переходим в директорию приложения
cd "$APP_DIR"

# Запускаем приложение
echo -e "${YELLOW}🚀 Запускаем приложение...${NC}"
if sudo pm2 list | grep -q "$PM2_APP_NAME"; then
    sudo pm2 restart "$PM2_APP_NAME"
else
    sudo pm2 start src/server.js --name "$PM2_APP_NAME"
fi

# Сохраняем конфигурацию PM2
echo -e "${YELLOW}💾 Сохраняем конфигурацию PM2...${NC}"
sudo pm2 save

# Проверяем статус
echo -e "${GREEN}📊 Статус приложения:${NC}"
sudo pm2 status "$PM2_APP_NAME"

echo -e "${GREEN}✅ Деплой успешно завершен!${NC}"
echo -e "${YELLOW}📝 Backup сохранен в: $BACKUP_DIR${NC}"

