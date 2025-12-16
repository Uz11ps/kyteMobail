import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';
import '../../bloc/chat/chat_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../../core/routing/app_router.dart';
import '../../../data/models/chat_model.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  bool _requestedReloadForForeignState = false;

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(ChatsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D2631),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1D2631),
        ),
        child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            Navigator.of(context).pushReplacementNamed(AppRouter.login);
          }
        },
          child: SafeArea(
            child: Column(
              children: [
                _ChatsHeader(
                  onCreate: () => Navigator.of(context).pushNamed(AppRouter.groupCreate),
                  onProfile: () => Navigator.of(context).pushNamed(AppRouter.profile),
                ),
                Expanded(
                  child: BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      if (state is ChatsLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (state is ChatsLoaded) {
                        _requestedReloadForForeignState = false;
                        if (state.chats.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 56,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Нет чатов',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Создайте группу или присоединитесь к существующей',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return RefreshIndicator(
                          color: Colors.white,
                          backgroundColor: const Color(0xFF1D2631),
                          onRefresh: () async {
                            context.read<ChatBloc>().add(ChatsLoadRequested());
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                            itemCount: state.chats.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final chat = state.chats[index];
                              return _ChatCard(chat: chat);
                            },
                          ),
                        );
                      }

                      if (state is ChatError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Ошибка',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  state.message,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.white.withOpacity(0.75),
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    context.read<ChatBloc>().add(ChatsLoadRequested());
                                  },
                                  child: const Text('Повторить'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Если текущий state относится к другому экрану (например, MessagesLoaded),
                      // перезагружаем список чатов и показываем loader, чтобы экран не становился пустым.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        if (_requestedReloadForForeignState) return;
                        _requestedReloadForForeignState = true;
                        context.read<ChatBloc>().add(ChatsLoadRequested());
                      });

                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatsHeader extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onProfile;

  const _ChatsHeader({
    required this.onCreate,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          const _KyteLogoSvg(width: 120, height: 44),
          const Spacer(),
          _EditCircleButton(
            onTap: onCreate,
          ),
          const SizedBox(width: 10),
          _ProfileCircleButton(
            onTap: onProfile,
          ),
        ],
      ),
    );
  }
}

class _KyteLogoSvg extends StatelessWidget {
  final double width;
  final double height;

  const _KyteLogoSvg({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _KyteLogoPainter(),
      ),
    );
  }
}

class _KyteLogoPainter extends CustomPainter {
  static const double _vbW = 125;
  static const double _vbH = 42;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / _vbW;
    final sy = size.height / _vbH;

    // Shadow params from SVG filter:
    // dy=0.521739, blur std=1.30435, opacity=0.2
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.20)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.30435);

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    Path p1 = Path()
      ..moveTo(38.215 * sx, 15.4471 * sy)
      ..lineTo(20.4166 * sx, 33.2484 * sy)
      ..lineTo(20.4122 * sx, 33.244 * sy)
      ..lineTo(20.4078 * sx, 33.2484 * sy)
      ..lineTo(2.60938 * sx, 15.4471 * sy)
      ..lineTo(11.5086 * sx, 6.54649 * sy)
      ..lineTo(20.4122 * sx, 15.4515 * sy)
      ..lineTo(29.3158 * sx, 6.54649 * sy)
      ..close();

    Path p2 = Path()
      ..moveTo(76.8529 * sx, 28.4342 * sy)
      ..lineTo(82.0344 * sx, 9.60344 * sy)
      ..lineTo(88.4419 * sx, 9.60344 * sy)
      ..lineTo(80.6105 * sx, 38.087 * sy)
      ..lineTo(74.2029 * sx, 38.087 * sy)
      ..lineTo(76.3783 * sx, 30.1749 * sy)
      ..lineTo(71.2364 * sx, 30.1749 * sy)
      ..lineTo(65.5012 * sx, 9.60344 * sy)
      ..lineTo(72.3043 * sx, 9.60344 * sy)
      ..close();

    Path p3 = Path()
      ..moveTo(49.9379 * sx, 17.5484 * sy)
      ..lineTo(56.7784 * sx, 9.60344 * sy)
      ..lineTo(65.1063 * sx, 9.60344 * sy)
      ..lineTo(57.1079 * sx, 18.8932 * sy)
      ..lineTo(65.7243 * sx, 30.1749 * sy)
      ..lineTo(57.7833 * sx, 30.1749 * sy)
      ..lineTo(49.9379 * sx, 19.9028 * sy)
      ..lineTo(49.9379 * sx, 30.1659 * sy)
      ..lineTo(43.6094 * sx, 30.1659 * sy)
      ..lineTo(43.6094 * sx, 4.06442 * sy)
      ..lineTo(49.9379 * sx, 2.08696 * sy)
      ..close();

    Path p4 = Path()
      ..moveTo(99.1993 * sx, 9.60344 * sy)
      ..lineTo(104.143 * sx, 9.60344 * sy)
      ..lineTo(104.143 * sx, 15.1419 * sy)
      ..lineTo(99.1993 * sx, 15.1419 * sy)
      ..lineTo(99.1993 * sx, 30.1749 * sy)
      ..lineTo(92.8709 * sx, 30.1749 * sy)
      ..lineTo(92.8709 * sx, 15.1419 * sy)
      ..lineTo(88.9156 * sx, 15.1419 * sy)
      ..lineTo(88.9156 * sx, 9.60344 * sy)
      ..lineTo(92.8709 * sx, 9.60344 * sy)
      ..lineTo(92.8709 * sx, 4.06498 * sy)
      ..lineTo(99.1993 * sx, 2.08696 * sy)
      ..close();

    Path p5 = Path()
      ..moveTo(120.351 * sx, 15.1419 * sy)
      ..lineTo(111.371 * sx, 15.1419 * sy)
      ..lineTo(111.371 * sx, 17.5155 * sy)
      ..lineTo(117.651 * sx, 17.5155 * sy)
      ..lineTo(116.344 * sx, 22.2628 * sy)
      ..lineTo(111.371 * sx, 22.2628 * sy)
      ..lineTo(111.371 * sx, 24.6364 * sy)
      ..lineTo(121.87 * sx, 24.6364 * sy)
      ..lineTo(120.346 * sx, 30.1749 * sy)
      ..lineTo(105.042 * sx, 30.1749 * sy)
      ..lineTo(105.042 * sx, 9.60344 * sy)
      ..lineTo(121.87 * sx, 9.60344 * sy)
      ..close();

    final shadowDy = 0.521739 * sy;

    void drawWithShadow(Path path) {
      canvas.save();
      canvas.translate(0, shadowDy);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();
      canvas.drawPath(path, fillPaint);
    }

    drawWithShadow(p1);
    drawWithShadow(p2);
    drawWithShadow(p3);
    drawWithShadow(p4);
    drawWithShadow(p5);
  }

  @override
  bool shouldRepaint(covariant _KyteLogoPainter oldDelegate) => false;
}

class _EditCircleButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EditCircleButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: const _GlassCircle(
          size: 48,
          child: _EditIconSvg(),
        ),
      ),
    );
  }
}

class _ProfileCircleButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfileCircleButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: const _GlassCircle(
          size: 48,
          child: _ProfileIconSvg(),
        ),
      ),
    );
  }
}

class _EditIconSvg extends StatelessWidget {
  const _EditIconSvg();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(20, 20),
      painter: _EditIconPainter(),
    );
  }
}

class _ProfileIconSvg extends StatelessWidget {
  const _ProfileIconSvg();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(20, 20),
      painter: _ProfileIconPainter(),
    );
  }
}

class _EditIconPainter extends CustomPainter {
  const _EditIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final scaleX = size.width / 24;
    final scaleY = size.height / 24;

    final path = Path()
      // M10.0002 4H7.2002 - начало документа
      ..moveTo(10.0002 * scaleX, 4.0 * scaleY)
      ..lineTo(7.2002 * scaleX, 4.0 * scaleY)
      // C6.08009 4 5.51962 4 5.0918 4.21799 - левый верхний угол
      ..cubicTo(
        6.08009 * scaleX, 4.0 * scaleY,
        5.51962 * scaleX, 4.0 * scaleY,
        5.0918 * scaleX, 4.21799 * scaleY,
      )
      // C4.71547 4.40973 4.40973 4.71547 4.21799 5.0918
      ..cubicTo(
        4.71547 * scaleX, 4.40973 * scaleY,
        4.40973 * scaleX, 4.71547 * scaleY,
        4.21799 * scaleX, 5.0918 * scaleY,
      )
      // C4 5.51962 4 6.08009 4 7.2002V16.8002
      ..cubicTo(
        4.0 * scaleX, 5.51962 * scaleY,
        4.0 * scaleX, 6.08009 * scaleY,
        4.0 * scaleX, 7.2002 * scaleY,
      )
      ..lineTo(4.0 * scaleX, 16.8002 * scaleY)
      // C4 17.9203 4 18.4801 4.21799 18.9079 - правый нижний угол
      ..cubicTo(
        4.0 * scaleX, 17.9203 * scaleY,
        4.0 * scaleX, 18.4801 * scaleY,
        4.21799 * scaleX, 18.9079 * scaleY,
      )
      // C4.40973 19.2842 4.71547 19.5905 5.0918 19.7822
      ..cubicTo(
        4.40973 * scaleX, 19.2842 * scaleY,
        4.71547 * scaleX, 19.5905 * scaleY,
        5.0918 * scaleX, 19.7822 * scaleY,
      )
      // C5.5192 20 6.07899 20 7.19691 20H16.8031
      ..cubicTo(
        5.5192 * scaleX, 20.0 * scaleY,
        6.07899 * scaleX, 20.0 * scaleY,
        7.19691 * scaleX, 20.0 * scaleY,
      )
      ..lineTo(16.8031 * scaleX, 20.0 * scaleY)
      // C17.921 20 18.48 20 18.9074 19.7822
      ..cubicTo(
        17.921 * scaleX, 20.0 * scaleY,
        18.48 * scaleX, 20.0 * scaleY,
        18.9074 * scaleX, 19.7822 * scaleY,
      )
      // C19.2837 19.5905 19.5905 19.2839 19.7822 18.9076
      ..cubicTo(
        19.2837 * scaleX, 19.5905 * scaleY,
        19.5905 * scaleX, 19.2839 * scaleY,
        19.7822 * scaleX, 18.9076 * scaleY,
      )
      // C20 18.4802 20 17.921 20 16.8031V14
      ..cubicTo(
        20.0 * scaleX, 18.4802 * scaleY,
        20.0 * scaleX, 17.921 * scaleY,
        20.0 * scaleX, 16.8031 * scaleY,
      )
      ..lineTo(20.0 * scaleX, 14.0 * scaleY)
      // M16 5L10 11V14H13L19 8 - карандаш
      ..moveTo(16.0 * scaleX, 5.0 * scaleY)
      ..lineTo(10.0 * scaleX, 11.0 * scaleY)
      ..lineTo(10.0 * scaleX, 14.0 * scaleY)
      ..lineTo(13.0 * scaleX, 14.0 * scaleY)
      ..lineTo(19.0 * scaleX, 8.0 * scaleY)
      // M16 5L19 2L22 5L19 8 - ластик
      ..moveTo(16.0 * scaleX, 5.0 * scaleY)
      ..lineTo(19.0 * scaleX, 2.0 * scaleY)
      ..lineTo(22.0 * scaleX, 5.0 * scaleY)
      ..lineTo(19.0 * scaleX, 8.0 * scaleY)
      // M16 5L19 8 - соединение
      ..moveTo(16.0 * scaleX, 5.0 * scaleY)
      ..lineTo(19.0 * scaleX, 8.0 * scaleY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _EditIconPainter oldDelegate) => false;
}

class _ProfileIconPainter extends CustomPainter {
  const _ProfileIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final scaleX = size.width / 24;
    final scaleY = size.height / 24;

    final path = Path()
      // M20 21C20 18.2386 16.4183 16 12 16C7.58172 16 4 18.2386 4 21
      ..moveTo(20.0 * scaleX, 21.0 * scaleY)
      ..cubicTo(
        20.0 * scaleX, 18.2386 * scaleY,
        16.4183 * scaleX, 16.0 * scaleY,
        12.0 * scaleX, 16.0 * scaleY,
      )
      ..cubicTo(
        7.58172 * scaleX, 16.0 * scaleY,
        4.0 * scaleX, 18.2386 * scaleY,
        4.0 * scaleX, 21.0 * scaleY,
      )
      // M12 13C9.23858 13 7 10.7614 7 8C7 5.23858 9.23858 3 12 3C14.7614 3 17 5.23858 17 8C17 10.7614 14.7614 13 12 13Z
      ..moveTo(12.0 * scaleX, 13.0 * scaleY)
      ..cubicTo(
        9.23858 * scaleX, 13.0 * scaleY,
        7.0 * scaleX, 10.7614 * scaleY,
        7.0 * scaleX, 8.0 * scaleY,
      )
      ..cubicTo(
        7.0 * scaleX, 5.23858 * scaleY,
        9.23858 * scaleX, 3.0 * scaleY,
        12.0 * scaleX, 3.0 * scaleY,
      )
      ..cubicTo(
        14.7614 * scaleX, 3.0 * scaleY,
        17.0 * scaleX, 5.23858 * scaleY,
        17.0 * scaleX, 8.0 * scaleY,
      )
      ..cubicTo(
        17.0 * scaleX, 10.7614 * scaleY,
        14.7614 * scaleX, 13.0 * scaleY,
        12.0 * scaleX, 13.0 * scaleY,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ProfileIconPainter oldDelegate) => false;
}

class _GlassCircle extends StatelessWidget {
  final double size;
  final Widget child;

  const _GlassCircle({
    required this.size,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Визуально близко к CSS "Liquid Glass - Regular - Small":
    // - backdrop blur 20
    // - тёмная стеклянная заливка с тонким светлым бордером
    // - мягкий внутренний блик и лёгкая виньетка
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Backdrop blur слой (backdrop-filter: blur(20px))
          Positioned.fill(
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // Base fill (тёмное стекло)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2A3441).withOpacity(0.50),
                    const Color(0xFF0B1320).withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),

          // Inner highlight (soft white film) + slight blur feel
          Positioned.fill(
            child: ClipOval(
              child: Padding(
                padding: EdgeInsets.all(size * 0.06),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.45, -0.55),
                      radius: 0.95,
                      colors: [
                        Colors.white.withOpacity(0.10),
                        Colors.white.withOpacity(0.03),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Vignette
          Positioned.fill(
            child: ClipOval(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.92,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.26),
                    ],
                    stops: const [0.65, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Border (тонкий светлый ободок)
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

          // Иконка по центру
          Center(child: child),
        ],
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  final ChatModel chat;

  const _ChatCard({required this.chat});

  @override
  Widget build(BuildContext context) {
    final seed = _stableSeed(chat.id);
    final lastMessage = chat.lastMessage?.trim();

    // Используем реальные данные из API
    final messageCount = chat.unreadCount ?? 0;
    final favCount = chat.likesCount ?? 0;
    final calendarCount = chat.meetingsCount ?? 0;

    final time = chat.lastMessageAt != null ? _formatTime(chat.lastMessageAt!) : '';
    final author = _previewAuthor(chat);
    final previewText = (lastMessage == null || lastMessage.isEmpty) ? 'Нет сообщений' : lastMessage;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRouter.chat,
            arguments: {
              'chatId': chat.id,
              'chatName': chat.name,
            },
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ChatAvatar(chat: chat),
                    const SizedBox(width: 16), // Увеличен отступ между аватаром и названием
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chat.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 10), // Увеличен отступ между названием и иконками
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start, // Выравнивание по верхнему краю
                            children: [
                              _MetaBadgeStat(
                                svg: _chatStatSvgChat,
                                value: messageCount.toString(),
                              ),
                              const SizedBox(width: 24),
                              _MetaBadgeStat(
                                svg: _chatStatSvgHeart,
                                value: favCount.toString(),
                              ),
                              const SizedBox(width: 24),
                              _MetaBadgeStat(
                                svg: _chatStatSvgCalendar,
                                value: calendarCount.toString(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14), // Увеличен отступ между иконками и последним сообщением
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2330).withOpacity(0.75),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                  child: author.isEmpty
                      ? Row(
                          children: [
                            Expanded(
                              child: Text(
                                previewText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.80),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                            if (time.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Text(
                                time,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withOpacity(0.60),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    author,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: const Color(0xFF4CAF50),
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                if (time.isNotEmpty) ...[
                                  const SizedBox(width: 12),
                                  Text(
                                    time,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.white.withOpacity(0.60),
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              previewText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.82),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _previewAuthor(ChatModel chat) {
    // В проде лучше отдавать lastMessageAuthorName с backend и прокинуть в ChatModel.
    return '';
  }

  int _stableSeed(String input) {
    var hash = 0;
    for (final unit in input.codeUnits) {
      hash = 0x1fffffff & (hash + unit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash.abs();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }
  }
}

class _MetaBadgeStat extends StatelessWidget {
  final String svg;
  final String value;

  const _MetaBadgeStat({
    required this.svg,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Иконка по центру
          Center(
            child: SvgPicture.string(
              svg,
              width: 24,
              height: 24,
            ),
          ),
          // Бейдж: сдвинут на 5px вниз и влево от правого верхнего угла иконки
          // Все бейджи выровнены по одной горизонтальной линии
          Positioned(
            left: 19, // Правый край иконки (24px) минус 5px влево
            top: -13, // Фиксированная позиция (высота 18px) плюс 5px вниз
            child: _StatCountBadge(value: value),
          ),
        ],
      ),
    );
  }
}

class _StatCountBadge extends StatelessWidget {
  final String value;

  const _StatCountBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    // Определяем padding в зависимости от длины числа
    // Левый padding фиксированный минимальный, правый увеличивается
    final leftPadding = 4.0; // Фиксированный минимальный левый padding
    final rightPadding = value.length == 1 
        ? 4.0 
        : value.length == 2 
            ? 6.0 
            : 8.0; // Правый padding увеличивается с длиной числа - бейдж расширяется вправо
    
    // Для чисел из 1-2 цифр делаем круглый бейдж, для длинных - овальный
    final isLongNumber = value.length > 2;
    
    return Container(
      height: 18, // Фиксированная высота для всех бейджей
      constraints: BoxConstraints(
        minHeight: 18,
        maxHeight: 18,
        minWidth: 18, // Минимальная ширина (круг для одной цифры)
      ),
      padding: EdgeInsets.only(
        left: leftPadding, // Фиксированный минимальный левый padding
        right: rightPadding, // Правый padding увеличивается - бейдж расширяется только вправо
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
      alignment: Alignment.center, // Центрирование текста
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.clip,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1.0, // Фиксированная высота строки
          color: Colors.white,
        ),
      ),
    );
  }
}

const String _chatStatSvgChat = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M9.33814 15.9905C12.4946 15.8151 15 13.2003 15 10C15 6.68629 12.3137 4 9 4C5.68629 4 3 6.68629 3 10C3 11.1807 3.34094 12.2817 3.92989 13.21L3.50586 14.482L3.50518 14.4839C3.34278 14.9711 3.26154 15.2149 3.31938 15.3771C3.36979 15.5184 3.48169 15.6299 3.62305 15.6803C3.78472 15.7379 4.02675 15.6573 4.51069 15.4959L4.51758 15.4939L5.79004 15.0698C6.7183 15.6588 7.81935 15.9998 9.00006 15.9998C9.11352 15.9998 9.22624 15.9967 9.33814 15.9905ZM9.33814 15.9905C9.33822 15.9907 9.33806 15.9902 9.33814 15.9905ZM9.33814 15.9905C10.1591 18.3259 12.3841 20.0002 15.0001 20.0002C16.1808 20.0002 17.2817 19.6588 18.2099 19.0698L19.482 19.4939L19.4845 19.4944C19.9717 19.6567 20.2158 19.7381 20.378 19.6803C20.5194 19.6299 20.6299 19.5184 20.6803 19.3771C20.7382 19.2146 20.6572 18.9706 20.4943 18.4821L20.0703 17.21L20.2123 16.9746C20.7138 16.0979 20.9995 15.0823 20.9995 14C20.9995 10.6863 18.3137 8 15 8L14.7754 8.00414L14.6621 8.00967" stroke="#D6DBE2" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const String _chatStatSvgHeart = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M22 9.5L12.0025 19.5L12 19.4975L11.9975 19.5L2 9.5L6.99877 4.5L12 9.50247L17.0012 4.5L22 9.5Z" stroke="#D6DBE2" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const String _chatStatSvgCalendar = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M4 8H20M4 8V16.8002C4 17.9203 4 18.4801 4.21799 18.9079C4.40973 19.2842 4.71547 19.5905 5.0918 19.7822C5.5192 20 6.07899 20 7.19691 20H16.8031C17.921 20 18.48 20 18.9074 19.7822C19.2837 19.5905 19.5905 19.2842 19.7822 18.9079C20 18.4805 20 17.9215 20 16.8036V8M4 8V7.2002C4 6.08009 4 5.51962 4.21799 5.0918C4.40973 4.71547 4.71547 4.40973 5.0918 4.21799C5.51962 4 6.08009 4 7.2002 4H8M20 8V7.19691C20 6.07899 20 5.5192 19.7822 5.0918C19.5905 4.71547 19.2837 4.40973 18.9074 4.21799C18.4796 4 17.9203 4 16.8002 4H16M16 2V4M16 4H8M8 2V4" stroke="#D6DBE2" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

class _ChatAvatar extends StatelessWidget {
  final ChatModel chat;

  const _ChatAvatar({required this.chat});

  @override
  Widget build(BuildContext context) {
    final seed = chat.id.codeUnits.fold<int>(0, (acc, v) => (acc + v) & 0x7fffffff);
    final colors = _gradientFromSeed(seed);
    final initials = _initials(chat.name);

    return Container(
      height: 54,
      width: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return chat.type == ChatType.group ? 'G' : 'U';
    if (parts.length == 1) {
      final token = parts.first;
      final runesLen = token.runes.length;
      final take = runesLen >= 3 && runesLen <= 3 ? 3 : 2;
      return _takeFirstRunes(token, take).toUpperCase();
    }
    final lastToken = parts.last;
    if (lastToken.runes.length == 3) {
      return _takeFirstRunes(lastToken, 3).toUpperCase();
    }
    final first = _takeFirstRunes(parts.first, 1).toUpperCase();
    final second = _takeFirstRunes(parts[1], 1).toUpperCase();
    return '$first$second';
  }

  String _takeFirstRunes(String input, int count) {
    if (count <= 0) return '';
    final runes = input.runes.toList();
    if (runes.isEmpty) return '';
    final end = count > runes.length ? runes.length : count;
    return String.fromCharCodes(runes.take(end));
  }

  List<Color> _gradientFromSeed(int seed) {
    final palette = <List<Color>>[
      [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
      [const Color(0xFF7F00FF), const Color(0xFFE100FF)],
      [const Color(0xFFFF512F), const Color(0xFFDD2476)],
      [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      [const Color(0xFFFFB75E), const Color(0xFFED8F03)],
    ];
    return palette[seed % palette.length];
  }
}

class _DiagonalStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Сине-фиолетовый градиент для диагональной полосы
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF0072FF), // Синий
        const Color(0xFF7F00FF), // Фиолетовый
      ],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect);

    // Рисуем диагональную полосу
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

