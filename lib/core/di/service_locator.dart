import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../data/repositories/google_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/repositories/google_repository.dart';
import '../network/api_client.dart';
import '../network/websocket_client.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Network
  late final ApiClient apiClient = ApiClient();
  late final WebSocketClient webSocketClient = WebSocketClient();

  // Repositories
  late final AuthRepository authRepository = AuthRepositoryImpl(apiClient.dio);
  late final ChatRepository chatRepository = ChatRepositoryImpl(apiClient.dio);
  late final AIRepository aiRepository = AIRepositoryImpl(apiClient.dio);
  late final GoogleRepository googleRepository = GoogleRepositoryImpl(apiClient.dio);
}

