import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import '../../bloc/chat/chat_bloc.dart';
import '../../bloc/ai/ai_bloc.dart';
import '../../bloc/google/google_bloc.dart';
import '../../../data/models/message_model.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/network/websocket_client.dart';
import '../../../core/utils/storage_keys.dart';
import '../../../core/storage/storage_service.dart';
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final WebSocketClient _wsClient = ServiceLocator().webSocketClient;
  late final ChatBloc _chatBloc;
  List<MessageModel> _messages = [];
  final int _memberCount = 4; // Демо значение, можно получать из ChatModel
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    _chatBloc.add(MessagesLoadRequested(chatId: widget.chatId));
    _connectWebSocket();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final storage = StorageService.instance;
    final userId = await storage.read(StorageKeys.userId);
    setState(() {
      _currentUserId = userId;
    });
  }

  void _connectWebSocket() {
    _wsClient.connect(widget.chatId).then((_) {
      _wsClient.messageStream.listen((message) {
        try {
          if (!mounted) return;

          Map<String, dynamic> data;
          if (message is String) {
            data = jsonDecode(message) as Map<String, dynamic>;
          } else if (message is Map) {
            data = message as Map<String, dynamic>;
          } else {
            return;
          }
          
          final messageModel = MessageModel.fromJson(data);
          context.read<ChatBloc>().add(MessageReceived(message: messageModel));
        } catch (e) {
          debugPrint('Ошибка парсинга WebSocket сообщения: $e');
        }
      });
    }).catchError((error) {
      debugPrint('Ошибка подключения WebSocket: $error');
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _wsClient.disconnect();
    _chatBloc.add(ChatsLoadRequested());
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    context.read<ChatBloc>().add(
          MessageSent(
            chatId: widget.chatId,
            content: content,
          ),
        );

    _messageController.clear();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showPopupChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.05, // Отступ сверху 5%
        ),
        child: _PopupChatWidget(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GoogleBloc, GoogleState>(
      listener: (context, state) {
        if (state is GoogleMeetCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Встреча создана'),
              action: SnackBarAction(
                label: 'Открыть',
                onPressed: () {},
              ),
            ),
          );
        } else if (state is GoogleError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка Google: ${state.message}')),
          );
        }
      },
      child: BlocListener<AIBloc, AIState>(
        listener: (context, state) {
          if (state is AIResponseReceived) {
            context.read<ChatBloc>().add(MessageReceived(message: state.message));
            
            final metadata = state.message.metadata;
            if (metadata != null && metadata.containsKey('suggestMeet') && metadata['suggestMeet'] == true) {
              context.read<GoogleBloc>().add(GoogleMeetCreateRequested());
            }
          } else if (state is AIError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка AI: ${state.message}')),
            );
          }
        },
        child: BlocListener<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state is MessagesLoaded) {
              setState(() {
                _messages = state.messages;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF1D2631),
            body: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1D2631),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    // ListView с сообщениями (занимает весь экран)
                    BlocBuilder<ChatBloc, ChatState>(
                      builder: (context, state) {
                        if (state is MessagesLoading && _messages.isEmpty) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (_messages.isEmpty) {
                          return Center(
                            child: Text(
                              'Нет сообщений',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), // Отступ сверху для стеклянного контейнера
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return _MessageItem(
                              message: message,
                              currentUserId: _currentUserId,
                            );
                          },
                        );
                      },
                    ),
                    // Стеклянный контейнер для заголовка и навигационной панели
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0.06),
                                  Colors.black.withOpacity(0.6),
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ChatHeader(
                                  chatName: widget.chatName,
                                  memberCount: _memberCount,
                                ),
                                _NavigationBar(
                                  chatCount: _messages.length,
                                  fileCount: 12,
                                ),
                                // Отступ 20px ниже навигационной панели
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Строка ввода внизу
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _InputBar(
                        controller: _messageController,
                        onSend: _sendMessage,
                        onHeartPressed: () => _showPopupChat(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final String chatName;
  final int memberCount;

  const _ChatHeader({
    required this.chatName,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Stack(
        children: [
          // Кнопка назад слева
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Backdrop blur
                        Positioned.fill(
                          child: ClipOval(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                        // Base fill
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.06),
                                  Colors.black.withOpacity(0.6),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Glass effect
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.2),
                            ),
                          ),
                        ),
                        // Border
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        // SVG иконка стрелки назад
                        Center(
                          child: SvgPicture.string(
                            '''
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                              <path d="M15 19L8 12L15 5" stroke="#D6DBE2" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                            </svg>
                            ''',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Текст по центру
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chatName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '$memberCount members',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Аватар справа
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1,
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                  ),
                ),
                child: Center(
                  child: Text(
                    chatName.split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').take(2).join(),
                    style: const TextStyle(
                      color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagonalStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF0072FF),
        const Color(0xFF7F00FF),
      ],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect);

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.6, 0)
      ..lineTo(size.width * 0.4, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NavigationBar extends StatelessWidget {
  final int chatCount;
  final int fileCount;

  const _NavigationBar({
    required this.chatCount,
    required this.fileCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: 370,
      height: 52, // Увеличена для иконок 44px + padding
      padding: const EdgeInsets.all(4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Backdrop blur
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          // Base fill
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),
          // Glass effect
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: Colors.black.withOpacity(0.2),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
          ),
          // Content
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Чат с текстом и бейджем 118 (слева)
              Padding(
                padding: const EdgeInsets.all(6), // Отступы вокруг кнопки Chat
                child: _ChatTabItem(
                  svg: _navIconChat,
                  badgeValue: '118',
                ),
              ),
              // Остальные три иконки справа
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Календарь с бейджем 12
                  _ChatTabIcon(
                    svg: _navIconCalendar,
                    badgeValue: '12',
                  ),
                  // Документ
                  _ChatTabIcon(
                    svg: _navIconDocument,
                  ),
                  // Поиск
                  _ChatTabIcon(
                    svg: _navIconSearch,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatTabItem extends StatelessWidget {
  final String svg;
  final String badgeValue;

  const _ChatTabItem({
    required this.svg,
    required this.badgeValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF3E4752),
        borderRadius: BorderRadius.circular(1000),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Иконка, текст и бейдж в Row
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: SvgPicture.string(
                  svg,
                  width: 20,
                  height: 20,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Chat',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              // Бейдж справа от текста "Chat"
              Container(
                padding: EdgeInsets.only(
                  left: 4,
                  right: badgeValue.length == 1 ? 4 : badgeValue.length == 2 ? 6 : 8,
                  top: 0,
                  bottom: 0,
                ),
                height: 18,
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF232B36),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeValue,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 0.78,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatTabIcon extends StatelessWidget {
  final String svg;
  final String? badgeValue;

  const _ChatTabIcon({
    required this.svg,
    this.badgeValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1000),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: SvgPicture.string(
                svg,
                width: 20,
                height: 20,
              ),
            ),
          ),
          // Бейдж правее от иконки, внутри бордера, на одном уровне
          if (badgeValue != null)
            Positioned(
              left: 16, // Правый край иконки (20px) минус 4px, бейдж идет правее
              top: -9, // Выровнено на одном уровне для всех бейджей (внутри бордера)
              child: Container(
                padding: EdgeInsets.only(
                  left: 4,
                  right: badgeValue!.length == 1 ? 4 : badgeValue!.length == 2 ? 6 : 8,
                  top: 0,
                  bottom: 0,
                ),
                height: 18,
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF232B36),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeValue!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 0.78,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IconWithBadge extends StatelessWidget {
  final String svg;
  final String badgeValue;

  const _IconWithBadge({
    required this.svg,
    required this.badgeValue,
  });

  @override
  Widget build(BuildContext context) {
    return _ChatTabIcon(
      svg: svg,
      badgeValue: badgeValue,
    );
  }
}

class _NavIcon extends StatelessWidget {
  final String svg;

  const _NavIcon({
    required this.svg,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      svg,
      width: 20,
      height: 20,
    );
  }
}

// SVG иконки для навигационной панели
const String _navIconChat = '''
<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M7.63407 13.6585C10.4399 13.5027 12.667 11.1782 12.667 8.33349C12.667 5.38788 10.2791 2.99999 7.33349 2.99999C4.38789 2.99999 2 5.38788 2 8.33349C2 9.38303 2.30306 10.3617 2.82659 11.1869L2.44967 12.3176L2.44907 12.3193C2.3047 12.7524 2.23248 12.9691 2.28391 13.1133C2.32871 13.2389 2.42818 13.338 2.55384 13.3828C2.69755 13.434 2.91269 13.3623 3.34288 13.2189L3.349 13.2171L4.48011 12.8401C5.30526 13.3637 6.284 13.6668 7.33355 13.6668C7.4344 13.6668 7.5346 13.664 7.63407 13.6585ZM7.63407 13.6585C7.63415 13.6587 7.634 13.6583 7.63407 13.6585ZM7.63407 13.6585C8.36381 15.7345 10.3417 17.2228 12.6671 17.2228C13.7167 17.2228 14.6952 16.9194 15.5203 16.3958L16.6511 16.7727L16.6533 16.7732C17.0864 16.9175 17.3034 16.9899 17.4476 16.9384C17.5733 16.8936 17.6715 16.7946 17.7163 16.6689C17.7678 16.5245 17.6958 16.3076 17.551 15.8733L17.1741 14.7425L17.3003 14.5333C17.7461 13.754 18 12.8512 18 11.8891C18 8.94355 15.6126 6.55565 12.667 6.55565L12.4673 6.55933L12.3666 6.56425" stroke="white" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const String _navIconCalendar = '''
<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M3.33333 6.66667H16.6667M3.33333 6.66667V14.0002C3.33333 15.1203 3.33333 15.6801 3.55132 16.1079C3.74306 16.4842 4.0488 16.7905 4.42513 16.9822C4.85253 17.2 5.41232 17.2 6.53024 17.2H13.4698C14.5877 17.2 15.1467 17.2 15.5741 16.9822C15.9504 16.7905 16.2572 16.4842 16.4489 16.1079C16.6667 15.6805 16.6667 15.1215 16.6667 14.0036V6.66667M3.33333 6.66667V5.86687C3.33333 4.74676 3.33333 4.18629 3.55132 3.75847C3.74306 3.38214 4.0488 3.0764 4.42513 2.88466C4.85295 2.66667 5.41342 2.66667 6.53353 2.66667H6.66667M16.6667 6.66667V5.86358C16.6667 4.74566 16.6667 4.18587 16.4489 3.75847C16.2572 3.38214 15.9504 3.0764 15.5741 2.88466C15.1463 2.66667 14.587 2.66667 13.4669 2.66667H13.3333M13.3333 2.66667V1.33333M13.3333 2.66667H6.66667M6.66667 2.66667V1.33333" stroke="#D6DBE2" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const String _navIconDocument = '''
<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M7.33333 4.66667H7.63277C7.85019 4.66667 7.95897 4.66667 8.06127 4.69123C8.15197 4.713 8.23905 4.74901 8.31858 4.79774C8.40825 4.8527 8.48525 4.9297 8.63889 5.08333L11.3613 7.80577C11.5151 7.9595 11.5915 8.03594 11.6465 8.12565C11.6952 8.20518 11.7317 8.29211 11.7535 8.38281C11.7778 8.48407 11.7778 8.59158 11.7778 8.80458V15.3333M7.33333 4.66667H3.42188C2.92405 4.66667 2.67539 4.66667 2.48524 4.76355C2.31799 4.84877 2.1821 4.98465 2.09688 5.15191C2 5.34205 2 5.59115 2 6.08898V16.5779C2 17.0757 2 17.3243 2.09688 17.5144C2.1821 17.6817 2.31799 17.818 2.48524 17.9032C2.6752 18 2.92357 18 3.42044 18L10.3565 18C10.8533 18 11.1026 18 11.2926 17.9032C11.4599 17.818 11.5953 17.6819 11.6806 17.5146C11.7774 17.3245 11.7778 17.0755 11.7778 16.5777V15.3333M7.33333 4.66667V7.68889C7.33333 8.18671 7.33333 8.43545 7.43022 8.6256C7.51544 8.79285 7.65132 8.9291 7.81858 9.01432C8.00853 9.11111 8.2569 9.11111 8.75375 9.11111H11.7774M8.22222 4.66675V3.42231C8.22222 2.92448 8.22222 2.67539 8.31911 2.48524C8.40433 2.31799 8.54021 2.1821 8.70747 2.09688C8.89761 2 9.14627 2 9.6441 2H13.5556M13.5556 2H13.855C14.0724 2 14.1812 2 14.2835 2.02456C14.3742 2.04633 14.4613 2.08234 14.5408 2.13108C14.6305 2.18603 14.7075 2.26304 14.8611 2.41667L17.5836 5.1391C17.7373 5.29284 17.8137 5.36928 17.8687 5.45898C17.9174 5.53851 17.9539 5.62545 17.9757 5.71615C18 5.8174 18 5.92491 18 6.13791V13.911C18 14.4088 17.9997 14.6578 17.9028 14.8479C17.8176 15.0152 17.6826 15.1513 17.5154 15.2365C17.3254 15.3333 17.0764 15.3333 16.5796 15.3333H11.7778M13.5556 2V5.02222C13.5556 5.52005 13.5556 5.76879 13.6524 5.95893C13.7377 6.12618 13.8735 6.26244 14.0408 6.34766C14.2308 6.44444 14.4791 6.44444 14.976 6.44444H17.9997" stroke="#D6DBE2" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const String _navIconSearch = '''
<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12.6667 12.6667L18 18M8.22222 14.4444C4.78578 14.4444 2 11.6587 2 8.22222C2 4.78578 4.78578 2 8.22222 2C11.6587 2 14.4444 4.78578 14.4444 8.22222C14.4444 11.6587 11.6587 14.4444 8.22222 14.4444Z" stroke="#D6DBE2" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const String _inputIconHeart = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M22 9.5L12.0025 19.5L12 19.4975L11.9975 19.5L2 9.5L6.99877 4.5L12 9.50247L17.0012 4.5L22 9.5Z" stroke="#D6DBE2" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

class _StatCountBadge extends StatelessWidget {
  final String value;

  const _StatCountBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    final isLongNumber = value.length > 2;
    
    return Container(
      height: 18,
      constraints: BoxConstraints(
        minHeight: 18,
        maxHeight: 18,
        minWidth: 18,
      ),
      padding: EdgeInsets.only(
        left: 4.0,
        right: value.length == 1 ? 4.0 : value.length == 2 ? 6.0 : 8.0,
        top: 0,
        bottom: 0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF232B36),
        borderRadius: BorderRadius.circular(isLongNumber ? 9 : 999),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.clip,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1.0,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _MessageItem extends StatelessWidget {
  final MessageModel message;
  final String? currentUserId;

  const _MessageItem({
    required this.message,
    this.currentUserId,
  });

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  Color _getAvatarColor(String? userId) {
    if (userId == null) return const Color(0xFF7F00FF);
    final hash = userId.codeUnits.fold<int>(0, (acc, v) => (acc + v) & 0x7fffffff);
    final colors = [
      [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
      [const Color(0xFF7F00FF), const Color(0xFFE100FF)],
      [const Color(0xFFFF512F), const Color(0xFFDD2476)],
      [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      [const Color(0xFFFFB75E), const Color(0xFFED8F03)],
    ];
    return colors[hash % colors.length][0];
  }

  @override
  Widget build(BuildContext context) {
    final isAIMessage = message.isAIMessage;
    final isSystemMessage = message.isSystemMessage;
    final userName = message.userName ?? (isAIMessage ? 'Kyte' : 'User');
    final time = _formatTime(message.createdAt);
    final nameColor = isAIMessage ? Colors.white : const Color(0xFF4CAF50);

    if (isSystemMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2332).withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
            ),
          ),
        ),
      );
    }

    final isCurrentUser = currentUserId != null && message.userId == currentUserId;
    final showUserName = !isCurrentUser && !isAIMessage;
    
    // Цвет фона: #161B22 для других пользователей, #28323E для текущего пользователя
    final messageBackgroundColor = isCurrentUser 
        ? const Color(0xFF28323E) 
        : const Color(0xFF161B22);

    // Для сообщений от текущего пользователя - без аватара и хвоста
    if (isCurrentUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: messageBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // Текст сообщения
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        message.content,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                    ),
                    // Время в правом нижнем углу
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            time,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 11,
                                ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.done_all,
                            size: 14,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Для сообщений от других пользователей - с аватаром слева внизу и хвостом
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Аватар внизу слева
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getAvatarColor(message.userId),
            ),
            child: Center(
              child: isAIMessage
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Text(
                      _getInitials(userName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Сообщение
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: messageBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Текст сообщения
                  Padding(
                    padding: EdgeInsets.only(
                      top: showUserName ? 18 : 0,
                      bottom: 20,
                    ),
                    child: Text(
                      message.content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                  ),
                  // Никнейм в левом верхнем углу
                  if (showUserName)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Text(
                        userName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: nameColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                      ),
                    ),
                  // Время в правом нижнем углу
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 11,
                              ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onHeartPressed;

  const _InputBar({
    required this.controller,
    required this.onSend,
    this.onHeartPressed,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8, // Учитываем безопасную зону снизу
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Stack(
        children: [
          // Backdrop blur эффект
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
          // Контент в стиле Telegram
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Кнопка сердца
              _GlassButton(
                svg: _inputIconHeart,
                onPressed: widget.onHeartPressed ?? () {},
              ),
              const SizedBox(width: 8),
              // Кнопка плюса
              _GlassButton(
                icon: Icons.add,
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              // Поле ввода
              Expanded(
                child: _GlassInputField(
                  controller: widget.controller,
                  onSend: widget.onSend,
                  hasText: _hasText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData? icon;
  final String? svg;
  final VoidCallback onPressed;

  const _GlassButton({
    this.icon,
    this.svg,
    required this.onPressed,
  }) : assert(icon != null || svg != null, 'Either icon or svg must be provided');

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Backdrop blur
              Positioned.fill(
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              // Base fill
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.06),
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
              ),
              // Glass effect
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.2),
                  ),
                ),
              ),
              // Border
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                      width: 1,
                    ),
                  ),
                ),
              ),
              // Иконка
              Center(
                child: svg != null
                    ? SvgPicture.string(
                        svg!,
                        width: 20,
                        height: 20,
                      )
                    : Icon(
                        icon!,
                        size: 20,
                        color: const Color(0xFFD6DBE2),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool hasText;

  const _GlassInputField({
    required this.controller,
    required this.onSend,
    required this.hasText,
  });

  @override
  State<_GlassInputField> createState() => _GlassInputFieldState();
}

class _GlassInputFieldState extends State<_GlassInputField> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    widget.controller.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scrollToBottom);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Backdrop blur
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          // Base fill
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),
          // Glass effect
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.black.withOpacity(0.2),
              ),
            ),
          ),
          // Border
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                  width: 1,
                ),
              ),
            ),
          ),
          // TextField
          TextField(
            controller: widget.controller,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.2,
            ),
            decoration: InputDecoration(
              hintText: 'Message',
              hintStyle: const TextStyle(
                color: Color(0xFF9EA7B2),
                fontSize: 15,
                height: 1.2,
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.only(
                left: 16,
                right: widget.hasText ? 48 : 16, // Отступ справа для кнопки
                top: 10,
                bottom: 10,
              ),
              isDense: true,
            ),
            maxLines: null,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            textAlignVertical: TextAlignVertical.bottom,
            scrollController: _scrollController,
            onSubmitted: (_) => widget.onSend(),
          ),
          // Кнопка отправки внутри поля ввода (показывается только когда есть текст)
          if (widget.hasText)
            Positioned(
              right: 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: _SendButton(
                  onPressed: widget.onSend,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SendButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const String sendIconSvg = '''
<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect width="32" height="32" rx="16" fill="white"/>
<path d="M16 23V9M16 9L10 15M16 9L22 15" stroke="#161B22" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: SvgPicture.string(
            sendIconSvg,
            width: 28,
            height: 28,
          ),
        ),
      ),
    );
  }
}

class _PopupChatWidget extends StatefulWidget {
  @override
  State<_PopupChatWidget> createState() => _PopupChatWidgetState();
}

class _PopupChatWidgetState extends State<_PopupChatWidget> {
  final _popupMessageController = TextEditingController();
  final _popupScrollController = ScrollController();
  final List<MessageModel> _popupMessages = [];
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _popupMessageController.addListener(_onTextChanged);
    // Добавляем начальные сообщения для демонстрации
    _popupMessages.addAll([
      MessageModel(
        id: '1',
        chatId: 'popup',
        userId: 'kyte',
        userName: 'Kyte',
        content: 'Сообщение',
        type: MessageType.text,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      MessageModel(
        id: '2',
        chatId: 'popup',
        userId: 'kyte',
        userName: 'Kyte',
        content: 'Дедлайн по вашей задачи "Концепт UX/UI" истекает завтра',
        type: MessageType.text,
        createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    ]);
    // Прокрутка к низу после инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_popupScrollController.hasClients) {
        _popupScrollController.jumpTo(_popupScrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _popupMessageController.removeListener(_onTextChanged);
    _popupMessageController.dispose();
    _popupScrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _popupMessageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _sendPopupMessage() {
    final content = _popupMessageController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _popupMessages.add(
        MessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          chatId: 'popup',
          userId: 'current_user',
          content: content,
          type: MessageType.text,
          createdAt: DateTime.now(),
        ),
      );
    });

    _popupMessageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_popupScrollController.hasClients) {
        _popupScrollController.animateTo(
          _popupScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1D2631),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Заголовок всплывающего чата со стеклянным фоном
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.06),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Иконка закрытия слева
                        _GlassButton(
                          svg: '''
                          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <path d="M18 18L12 12M12 12L6 6M12 12L18 6M12 12L6 18" stroke="#D6DBE2" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                          </svg>
                          ''',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 12),
                        // Название посередине
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Kyte',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'Your private chat',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Аватарка справа
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                              width: 1,
                            ),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'K',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
                // Список сообщений
                Expanded(
                  child: ListView.builder(
                    controller: _popupScrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _popupMessages.length,
                    itemBuilder: (context, index) {
                      final message = _popupMessages[index];
                      return _PopupMessageItem(
                        message: message,
                        currentUserId: 'current_user',
                      );
                    },
                  ),
                ),
                // Строка ввода
                Container(
                  padding: EdgeInsets.only(
                    left: 8,
                    right: 8,
                    top: 8,
                    bottom: MediaQuery.of(context).padding.bottom + 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                            child: Container(
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Кнопка плюса
                          _GlassButton(
                            icon: Icons.add,
                            onPressed: () {},
                          ),
                          const SizedBox(width: 8),
                          // Поле ввода
                          Expanded(
                            child: _GlassInputField(
                              controller: _popupMessageController,
                              onSend: _sendPopupMessage,
                              hasText: _hasText,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

class _PopupMessageItem extends StatelessWidget {
  final MessageModel message;
  final String? currentUserId;

  const _PopupMessageItem({
    required this.message,
    this.currentUserId,
  });

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = currentUserId != null && message.userId == currentUserId;
    
    // Цвет фона: #161B22 для других пользователей, #28323E для текущего пользователя
    final messageBackgroundColor = isCurrentUser 
        ? const Color(0xFF28323E) 
        : const Color(0xFF161B22);

    final time = _formatTime(message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: messageBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Текст сообщения
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    message.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                ),
                // Время в правом нижнем углу
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 11,
                            ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

