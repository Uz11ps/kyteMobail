import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import '../bloc/chat/chat_bloc.dart';
import '../../data/models/chat_model.dart';

class EditChatBottomSheet extends StatefulWidget {
  final ChatModel chat;

  const EditChatBottomSheet({
    super.key,
    required this.chat,
  });

  @override
  State<EditChatBottomSheet> createState() => _EditChatBottomSheetState();
}

class _EditChatBottomSheetState extends State<EditChatBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  final List<String> _participantIds = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.chat.name);
    _descriptionController = TextEditingController(text: ''); // Описание пока не хранится в модели
    _participantIds.addAll(widget.chat.participantIds);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateChat() {
    if (!_formKey.currentState!.validate()) return;

    // TODO: Добавить событие для обновления чата в ChatBloc
    // context.read<ChatBloc>().add(
    //       ChatUpdateRequested(
    //         chatId: widget.chat.id,
    //         name: _nameController.text,
    //         description: _descriptionController.text,
    //         participantIds: _participantIds,
    //       ),
    //     );
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: const BoxDecoration(
          color: Color(0xFF1D2631),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Column(
            children: [
              // Заголовок с кнопками
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
                        // Кнопка закрытия (X)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(20),
                            child: const _GlassCircle(
                              size: 40,
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Заголовок
                        const Text(
                          'Edit project',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        // Кнопка подтверждения (галочка)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _updateChat,
                            borderRadius: BorderRadius.circular(20),
                            child: const _GlassCircle(
                              size: 40,
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Форма
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Form(
                    key: _formKey,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Карточка с полями (370x120)
                          SizedBox(
                            width: 370,
                            height: 120,
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
                                // Content
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Поле GROUP NAME
                                      Expanded(
                                        child: Center(
                                          child: TextFormField(
                                            controller: _nameController,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'GROUP NAME',
                                              hintStyle: TextStyle(
                                                color: Colors.white.withOpacity(0.5),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.5,
                                              ),
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              filled: false,
                                              fillColor: Colors.transparent,
                                              contentPadding: EdgeInsets.zero,
                                              isDense: true,
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Введите название группы';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ),
                                      // Разделительная линия
                                      Container(
                                        height: 1,
                                        color: Colors.white.withOpacity(0.1),
                                        margin: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                      // Поле GROUP DESCRIPTION
                                      Expanded(
                                        child: Center(
                                          child: TextFormField(
                                            controller: _descriptionController,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                            maxLines: null,
                                            textAlignVertical: TextAlignVertical.center,
                                            decoration: InputDecoration(
                                              hintText: 'GROUP DESCRIPTION',
                                              hintStyle: TextStyle(
                                                color: Colors.white.withOpacity(0.5),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.5,
                                              ),
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              filled: false,
                                              fillColor: Colors.transparent,
                                              contentPadding: EdgeInsets.zero,
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Список участников
                          if (_participantIds.isNotEmpty) ...[
                            SizedBox(
                              width: 370,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                                    child: Text(
                                      'Участники (${_participantIds.length})',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  ..._participantIds.map((participantId) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: SizedBox(
                                        width: 370,
                                        height: 60,
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
                                            // Content
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: Row(
                                                children: [
                                                  // Аватар участника
                                                  Container(
                                                    width: 36,
                                                    height: 36,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                        colors: [
                                                          const Color(0xFF00C6FF),
                                                          const Color(0xFF0072FF),
                                                        ],
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        participantId.substring(0, 1).toUpperCase(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.w800,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  // Имя участника
                                                  Expanded(
                                                    child: Text(
                                                      participantId,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  // Кнопка удаления
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          _participantIds.remove(participantId);
                                                        });
                                                      },
                                                      borderRadius: BorderRadius.circular(20),
                                                      child: const Padding(
                                                        padding: EdgeInsets.all(8),
                                                        child: Icon(
                                                          Icons.remove_circle_outline,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Кнопка Add member (370x60)
                          SizedBox(
                            width: 370,
                            height: 60,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // TODO: Добавить логику добавления участников
                                },
                                borderRadius: BorderRadius.circular(18),
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
                                    // Content
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.add,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Add member',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Экспортируем _GlassCircle для использования в модальном окне
class _GlassCircle extends StatelessWidget {
  final double size;
  final Widget child;

  const _GlassCircle({
    required this.size,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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

