// Конфигурация
const API_BASE = '/api/admin';
let authToken = localStorage.getItem('adminToken');
let currentPage = 'dashboard';
let currentData = {
    users: { page: 1, search: '' },
    chats: { page: 1, type: '' },
    messages: { page: 1, chatId: '' },
};

// Инициализация
document.addEventListener('DOMContentLoaded', () => {
    if (authToken) {
        showAdminScreen();
    } else {
        showLoginScreen();
    }
    setupEventListeners();
});

// Обработчики событий
function setupEventListeners() {
    // Логин
    document.getElementById('loginForm').addEventListener('submit', handleLogin);
    document.getElementById('logoutBtn').addEventListener('click', handleLogout);

    // Навигация
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', (e) => {
            e.preventDefault();
            const page = item.dataset.page;
            switchPage(page);
        });
    });

    // Поиск и фильтры
    document.getElementById('userSearch').addEventListener('input', debounce(() => {
        currentData.users.search = document.getElementById('userSearch').value;
        currentData.users.page = 1;
        loadUsers();
    }, 500));

    document.getElementById('chatTypeFilter').addEventListener('change', () => {
        currentData.chats.type = document.getElementById('chatTypeFilter').value;
        currentData.chats.page = 1;
        loadChats();
    });

    document.getElementById('messageChatFilter').addEventListener('input', debounce(() => {
        currentData.messages.chatId = document.getElementById('messageChatFilter').value;
        currentData.messages.page = 1;
        loadMessages();
    }, 500));

    // Модальное окно
    const closeBtn = document.querySelector('.close');
    if (closeBtn) {
        closeBtn.addEventListener('click', () => {
            document.getElementById('modal').classList.remove('active');
        });
    }
    
    // Форма настроек AI
    const aiConfigForm = document.getElementById('aiConfigFormElement');
    if (aiConfigForm) {
        aiConfigForm.addEventListener('submit', saveAIConfig);
    }
}

// Логин
async function handleLogin(e) {
    e.preventDefault();
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    const errorDiv = document.getElementById('loginError');

    try {
        const response = await fetch(`${API_BASE}/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password }),
        });

        const data = await response.json();

        if (response.ok && data.success) {
            authToken = data.token;
            localStorage.setItem('adminToken', authToken);
            showAdminScreen();
        } else {
            errorDiv.textContent = data.error || 'Ошибка входа';
            errorDiv.classList.add('show');
        }
    } catch (error) {
        errorDiv.textContent = 'Ошибка подключения к серверу';
        errorDiv.classList.add('show');
    }
}

function handleLogout() {
    authToken = null;
    localStorage.removeItem('adminToken');
    showLoginScreen();
}

// Переключение экранов
function showLoginScreen() {
    document.getElementById('loginScreen').classList.add('active');
    document.getElementById('adminScreen').classList.remove('active');
}

function showAdminScreen() {
    document.getElementById('loginScreen').classList.remove('active');
    document.getElementById('adminScreen').classList.add('active');
    switchPage('dashboard');
}

function switchPage(page) {
    currentPage = page;
    
    // Обновляем навигацию
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.remove('active');
        if (item.dataset.page === page) {
            item.classList.add('active');
        }
    });

    // Показываем нужную страницу
    document.querySelectorAll('.page').forEach(p => {
        p.classList.remove('active');
    });
    document.getElementById(`${page}Page`).classList.add('active');

    // Загружаем данные
    switch (page) {
        case 'dashboard':
            loadStats();
            break;
        case 'users':
            loadUsers();
            break;
        case 'chats':
            loadChats();
            break;
        case 'messages':
            loadMessages();
            break;
        case 'ai':
            loadAIConfig();
            break;
    }
}

// API запросы
async function apiRequest(endpoint, options = {}) {
    const headers = {
        'Content-Type': 'application/json',
        ...options.headers,
    };

    if (authToken) {
        headers['Authorization'] = `Bearer ${authToken}`;
    }

    const response = await fetch(`${API_BASE}${endpoint}`, {
        ...options,
        headers,
    });

    if (response.status === 401) {
        handleLogout();
        throw new Error('Сессия истекла');
    }

    return response.json();
}

// Загрузка статистики
async function loadStats() {
    try {
        const data = await apiRequest('/stats');
        if (data.success) {
            const stats = data.data.overview;
            const today = data.data.today;

            document.getElementById('statUsers').textContent = stats.totalUsers;
            document.getElementById('statChats').textContent = stats.totalChats;
            document.getElementById('statMessages').textContent = stats.totalMessages;
            document.getElementById('statToday').textContent = `${today.users} пользователей, ${today.messages} сообщений`;

            renderRecentUsers(data.data.recentUsers);
            renderActiveChats(data.data.activeChats);
        }
    } catch (error) {
        console.error('Ошибка загрузки статистики:', error);
    }
}

// Загрузка пользователей
async function loadUsers() {
    const container = document.getElementById('usersTable');
    container.innerHTML = '<div class="loading">Загрузка...</div>';

    try {
        const params = new URLSearchParams({
            page: currentData.users.page,
            limit: 20,
            ...(currentData.users.search && { search: currentData.users.search }),
        });

        const data = await apiRequest(`/users?${params}`);
        if (data.success) {
            renderUsersTable(data.data, data.pagination);
        }
    } catch (error) {
        container.innerHTML = `<div class="error-message show">Ошибка: ${error.message}</div>`;
    }
}

// Загрузка чатов
async function loadChats() {
    const container = document.getElementById('chatsTable');
    container.innerHTML = '<div class="loading">Загрузка...</div>';

    try {
        const params = new URLSearchParams({
            page: currentData.chats.page,
            limit: 20,
            ...(currentData.chats.type && { type: currentData.chats.type }),
        });

        const data = await apiRequest(`/chats?${params}`);
        if (data.success) {
            renderChatsTable(data.data, data.pagination);
        }
    } catch (error) {
        container.innerHTML = `<div class="error-message show">Ошибка: ${error.message}</div>`;
    }
}

// Загрузка сообщений
async function loadMessages() {
    const container = document.getElementById('messagesTable');
    container.innerHTML = '<div class="loading">Загрузка...</div>';

    try {
        const params = new URLSearchParams({
            page: currentData.messages.page,
            limit: 50,
            ...(currentData.messages.chatId && { chatId: currentData.messages.chatId }),
        });

        const data = await apiRequest(`/messages?${params}`);
        if (data.success) {
            renderMessagesTable(data.data, data.pagination);
        }
    } catch (error) {
        container.innerHTML = `<div class="error-message show">Ошибка: ${error.message}</div>`;
    }
}

// Рендеринг таблиц
function renderUsersTable(users, pagination) {
    const container = document.getElementById('usersTable');
    
    if (users.length === 0) {
        container.innerHTML = '<div class="empty">Пользователи не найдены</div>';
        return;
    }

    let html = `
        <table class="table">
            <thead>
                <tr>
                    <th>Email</th>
                    <th>Имя</th>
                    <th>Телефон</th>
                    <th>Дата регистрации</th>
                    <th>Действия</th>
                </tr>
            </thead>
            <tbody>
    `;

    users.forEach(user => {
        html += `
            <tr>
                <td>${user.email || '-'}</td>
                <td>${user.name || '-'}</td>
                <td>${user.phone || '-'}</td>
                <td>${new Date(user.createdAt).toLocaleDateString('ru-RU')}</td>
                <td>
                    <button class="btn btn-sm btn-info" onclick="showUserDetails('${user._id}')">Подробнее</button>
                    <button class="btn btn-sm btn-danger" onclick="deleteUser('${user._id}')">Удалить</button>
                </td>
            </tr>
        `;
    });

    html += '</tbody></table>';
    container.innerHTML = html;
    renderPagination('usersPagination', pagination, 'users');
}

function renderChatsTable(chats, pagination) {
    const container = document.getElementById('chatsTable');
    
    if (chats.length === 0) {
        container.innerHTML = '<div class="empty">Чаты не найдены</div>';
        return;
    }

    let html = `
        <table class="table">
            <thead>
                <tr>
                    <th>Название</th>
                    <th>Тип</th>
                    <th>Участников</th>
                    <th>Последнее сообщение</th>
                    <th>Действия</th>
                </tr>
            </thead>
            <tbody>
    `;

    chats.forEach(chat => {
        const typeBadge = chat.type === 'group' ? 
            '<span class="badge badge-primary">Группа</span>' : 
            '<span class="badge badge-success">Личный</span>';
        
        html += `
            <tr>
                <td>${chat.name}</td>
                <td>${typeBadge}</td>
                <td>${chat.participants?.length || 0}</td>
                <td>${chat.lastMessageAt ? new Date(chat.lastMessageAt).toLocaleString('ru-RU') : '-'}</td>
                <td>
                    <button class="btn btn-sm btn-danger" onclick="deleteChat('${chat._id}')">Удалить</button>
                </td>
            </tr>
        `;
    });

    html += '</tbody></table>';
    container.innerHTML = html;
    renderPagination('chatsPagination', pagination, 'chats');
}

function renderMessagesTable(messages, pagination) {
    const container = document.getElementById('messagesTable');
    
    if (messages.length === 0) {
        container.innerHTML = '<div class="empty">Сообщения не найдены</div>';
        return;
    }

    let html = `
        <table class="table">
            <thead>
                <tr>
                    <th>Чат</th>
                    <th>От</th>
                    <th>Сообщение</th>
                    <th>Тип</th>
                    <th>Дата</th>
                    <th>Действия</th>
                </tr>
            </thead>
            <tbody>
    `;

    messages.forEach(msg => {
        html += `
            <tr>
                <td>${msg.chatId?.name || msg.chatId?._id || '-'}</td>
                <td>${msg.userId?.email || msg.userId?._id || '-'}</td>
                <td>${msg.content.substring(0, 50)}${msg.content.length > 50 ? '...' : ''}</td>
                <td><span class="badge badge-primary">${msg.type}</span></td>
                <td>${new Date(msg.createdAt).toLocaleString('ru-RU')}</td>
                <td>
                    <button class="btn btn-sm btn-danger" onclick="deleteMessage('${msg._id}')">Удалить</button>
                </td>
            </tr>
        `;
    });

    html += '</tbody></table>';
    container.innerHTML = html;
    renderPagination('messagesPagination', pagination, 'messages');
}

function renderRecentUsers(users) {
    const container = document.getElementById('recentUsers');
    if (!users || users.length === 0) {
        container.innerHTML = '<div class="empty">Нет пользователей</div>';
        return;
    }

    let html = '<table class="table"><thead><tr><th>Email</th><th>Имя</th><th>Дата регистрации</th></tr></thead><tbody>';
    users.forEach(user => {
        html += `<tr><td>${user.email}</td><td>${user.name || '-'}</td><td>${new Date(user.createdAt).toLocaleString('ru-RU')}</td></tr>`;
    });
    html += '</tbody></table>';
    container.innerHTML = html;
}

function renderActiveChats(chats) {
    const container = document.getElementById('activeChats');
    if (!chats || chats.length === 0) {
        container.innerHTML = '<div class="empty">Нет активных чатов</div>';
        return;
    }

    let html = '<table class="table"><thead><tr><th>Название</th><th>Тип</th><th>Последнее сообщение</th></tr></thead><tbody>';
    chats.forEach(chat => {
        html += `<tr><td>${chat.name}</td><td>${chat.type === 'group' ? 'Группа' : 'Личный'}</td><td>${chat.lastMessageAt ? new Date(chat.lastMessageAt).toLocaleString('ru-RU') : '-'}</td></tr>`;
    });
    html += '</tbody></table>';
    container.innerHTML = html;
}

function renderPagination(containerId, pagination, type) {
    const container = document.getElementById(containerId);
    if (!pagination || pagination.pages <= 1) {
        container.innerHTML = '';
        return;
    }

    let html = '';
    for (let i = 1; i <= pagination.pages; i++) {
        html += `<button class="${i === pagination.page ? 'active' : ''}" onclick="changePage('${type}', ${i})">${i}</button>`;
    }
    container.innerHTML = html;
}

function changePage(type, page) {
    currentData[type].page = page;
    switch (type) {
        case 'users':
            loadUsers();
            break;
        case 'chats':
            loadChats();
            break;
        case 'messages':
            loadMessages();
            break;
    }
}

// Удаление
async function deleteUser(id) {
    if (!confirm('Удалить пользователя?')) return;
    try {
        await apiRequest(`/users/${id}`, { method: 'DELETE' });
        loadUsers();
    } catch (error) {
        alert('Ошибка удаления: ' + error.message);
    }
}

async function deleteChat(id) {
    if (!confirm('Удалить чат и все сообщения?')) return;
    try {
        await apiRequest(`/chats/${id}`, { method: 'DELETE' });
        loadChats();
        loadStats();
    } catch (error) {
        alert('Ошибка удаления: ' + error.message);
    }
}

async function deleteMessage(id) {
    if (!confirm('Удалить сообщение?')) return;
    try {
        await apiRequest(`/messages/${id}`, { method: 'DELETE' });
        loadMessages();
    } catch (error) {
        alert('Ошибка удаления: ' + error.message);
    }
}

// Утилиты
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Настройки AI
async function loadAIConfig() {
    try {
        const data = await apiRequest('/ai/config');
        if (data.success) {
            const config = data.data;
            document.getElementById('openaiApiKey').value = '';
            document.getElementById('openaiModel').value = config.openaiModel || 'gpt-3.5-turbo';
            document.getElementById('openaiMaxTokens').value = config.openaiMaxTokens || 500;
            document.getElementById('openaiTemperature').value = config.openaiTemperature || 0.7;
            document.getElementById('systemPrompt').value = config.systemPrompt || '';
            document.getElementById('maxRequestsPerMinute').value = config.maxRequestsPerMinute || 10;
            document.getElementById('maxRequestsPerHour').value = config.maxRequestsPerHour || 100;
            document.getElementById('aiEnabled').checked = config.enabled !== false;
        }
    } catch (error) {
        console.error('Ошибка загрузки настроек AI:', error);
        alert('Ошибка загрузки настроек AI: ' + error.message);
    }
}

async function saveAIConfig(e) {
    e.preventDefault();
    try {
        const config = {
            openaiApiKey: document.getElementById('openaiApiKey').value || undefined,
            openaiModel: document.getElementById('openaiModel').value,
            openaiMaxTokens: parseInt(document.getElementById('openaiMaxTokens').value),
            openaiTemperature: parseFloat(document.getElementById('openaiTemperature').value),
            systemPrompt: document.getElementById('systemPrompt').value,
            maxRequestsPerMinute: parseInt(document.getElementById('maxRequestsPerMinute').value),
            maxRequestsPerHour: parseInt(document.getElementById('maxRequestsPerHour').value),
            enabled: document.getElementById('aiEnabled').checked,
        };
        
        const data = await apiRequest('/ai/config', {
            method: 'PUT',
            body: JSON.stringify(config),
        });
        
        if (data.success) {
            alert('Настройки AI сохранены');
            loadAIConfig();
        }
    } catch (error) {
        alert('Ошибка сохранения настроек AI: ' + error.message);
    }
}

async function testAIConfig() {
    try {
        const data = await apiRequest('/ai/config/test', { method: 'POST' });
        if (data.success) {
            alert('Настройки AI валидны! Модель: ' + data.data.model);
        }
    } catch (error) {
        alert('Ошибка тестирования AI: ' + (error.error || error.message));
    }
}

// Улучшенное отображение информации о пользователе
async function showUserDetails(userId) {
    try {
        const data = await apiRequest(`/users/${userId}`);
        if (data.success) {
            const user = data.data;
            const modalBody = document.getElementById('modalBody');
            modalBody.innerHTML = `
                <h3>Информация о пользователе</h3>
                <div class="user-details">
                    <p><strong>Email:</strong> ${user.email || '-'}</p>
                    <p><strong>Имя:</strong> ${user.name || '-'}</p>
                    <p><strong>Никнейм:</strong> ${user.nickname || '-'}</p>
                    <p><strong>Телефон:</strong> ${user.phone || '-'}</p>
                    <p><strong>О себе:</strong> ${user.about || '-'}</p>
                    <p><strong>День рождения:</strong> ${user.birthday ? new Date(user.birthday).toLocaleDateString('ru-RU') : '-'}</p>
                    <p><strong>Дата регистрации:</strong> ${new Date(user.createdAt).toLocaleString('ru-RU')}</p>
                    <p><strong>Последнее обновление:</strong> ${new Date(user.updatedAt).toLocaleString('ru-RU')}</p>
                    ${user.avatarUrl ? `<p><strong>Аватар:</strong> <img src="${user.avatarUrl}" style="max-width: 100px; border-radius: 50%;" /></p>` : ''}
                </div>
            `;
            document.getElementById('modal').classList.add('active');
        }
    } catch (error) {
        alert('Ошибка загрузки информации о пользователе: ' + error.message);
    }
}

// Обновляем рендеринг таблицы пользователей для добавления кнопки "Подробнее"
function renderUsersTable(users, pagination) {
    const container = document.getElementById('usersTable');
    
    if (users.length === 0) {
        container.innerHTML = '<div class="empty">Пользователи не найдены</div>';
        return;
    }

    let html = `
        <table class="table">
            <thead>
                <tr>
                    <th>Email</th>
                    <th>Имя</th>
                    <th>Телефон</th>
                    <th>Дата регистрации</th>
                    <th>Действия</th>
                </tr>
            </thead>
            <tbody>
    `;

    users.forEach(user => {
        html += `
            <tr>
                <td>${user.email || '-'}</td>
                <td>${user.name || '-'}</td>
                <td>${user.phone || '-'}</td>
                <td>${new Date(user.createdAt).toLocaleDateString('ru-RU')}</td>
                <td>
                    <button class="btn btn-sm btn-info" onclick="showUserDetails('${user._id}')">Подробнее</button>
                    <button class="btn btn-sm btn-danger" onclick="deleteUser('${user._id}')">Удалить</button>
                </td>
            </tr>
        `;
    });

    html += '</tbody></table>';
    container.innerHTML = html;
    renderPagination('usersPagination', pagination, 'users');
}

// Настройка обработчика формы AI настроек
document.addEventListener('DOMContentLoaded', () => {
    const aiConfigForm = document.getElementById('aiConfigFormElement');
    if (aiConfigForm) {
        aiConfigForm.addEventListener('submit', saveAIConfig);
    }
});

// Экспорт для глобального использования
window.deleteUser = deleteUser;
window.deleteChat = deleteChat;
window.deleteMessage = deleteMessage;
window.changePage = changePage;
window.showUserDetails = showUserDetails;
window.testAIConfig = testAIConfig;

