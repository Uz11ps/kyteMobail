class ApiEndpoints {
  // Authentication
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String sendPhoneCode = '/auth/phone/send-code';
  static const String verifyPhoneCode = '/auth/phone/verify-code';
  
  // Chats
  static const String chats = '/chats';
  static const String messages = '/chats/{chatId}/messages';
  static const String sendMessage = '/chats/{chatId}/messages';
  
  // Groups
  static const String groups = '/groups';
  static const String createGroup = '/groups';
  static const String joinGroup = '/groups/join';
  
  // Google OAuth
  static const String submitGmailToken = '/auth/gmail/token';
  static const String googleAuth = '/auth/google';
  
  // AI
  static const String askAI = '/ai/ask';
  static const String aiSuggestions = '/ai/suggestions';
  static const String aiChat = '/ai/chat';
  static const String aiChatHistory = '/ai/chat/history';
  
  // Google
  static const String createGoogleMeet = '/google/meet/create';
  
  // User Profile
  static const String getCurrentUser = '/user/me';
  static const String updateProfile = '/user/profile';
  static const String uploadAvatar = '/user/avatar';
  
  // Files
  static String uploadFile(String chatId) => '/chats/$chatId/files';
  static String getChatFiles(String chatId) => '/chats/$chatId/files';
  
  static String messagesForChat(String chatId) => messages.replaceAll('{chatId}', chatId);
  static String sendMessageToChat(String chatId) => sendMessage.replaceAll('{chatId}', chatId);
}

