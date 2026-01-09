import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'dart:ui';
import 'dart:io';
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';
import '../../data/models/message_model.dart';
import '../../core/di/service_locator.dart';
import '../../core/constants/api_endpoints.dart';

class AIChatPopup extends StatefulWidget {
  const AIChatPopup({super.key});

  @override
  State<AIChatPopup> createState() => _AIChatPopupState();
}

class _AIChatPopupState extends State<AIChatPopup> {
  final _popupMessageController = TextEditingController();
  final _popupScrollController = ScrollController();
  final List<MessageModel> _popupMessages = [];
  bool _hasText = false;
  String? _aiChatId;

  @override
  void initState() {
    super.initState();
    _popupMessageController.addListener(_onTextChanged);
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      final response = await ServiceLocator().apiClient.dio.get(
        ApiEndpoints.aiChatHistory,
      );
      if (response.data != null) {
        _aiChatId = response.data['chatId'];
        final messages = response.data['messages'] as List<dynamic>?;
        if (messages != null && messages.isNotEmpty) {
          setState(() {
            _popupMessages.addAll(
              messages.map((json) => MessageModel.fromJson(json)),
            );
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_popupScrollController.hasClients) {
              _popupScrollController.jumpTo(
                _popupScrollController.position.maxScrollExtent,
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Ошибка загрузки истории AI чата: $e');
    }
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

  Future<void> _pickAndUploadFileForAI() async {
    try {
      FilePickerResult? result;
      
      if (!kIsWeb) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );
        if (result != null && result.files.single.path != null) {
          await _uploadFileForAIMobile(result.files.single.path!);
        }
      } else {
        html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
        uploadInput.click();
        await uploadInput.onChange.first;
        if (uploadInput.files != null && uploadInput.files!.isNotEmpty) {
          await _uploadFileForAIWeb(uploadInput.files!.first);
        }
      }
    } catch (e) {
      debugPrint('Ошибка выбора файла для AI: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки файла: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadFileForAIMobile(String filePath) async {
    try {
      final file = File(filePath);
      final fileName = file.path.split('/').last;
      
      if (_aiChatId == null) {
        final response = await ServiceLocator().apiClient.dio.get(
          ApiEndpoints.aiChatHistory,
        );
        if (response.data != null && response.data['chatId'] != null) {
          _aiChatId = response.data['chatId'];
        } else {
          throw Exception('AI чат не найден');
        }
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final response = await ServiceLocator().apiClient.dio.post(
        ApiEndpoints.uploadFile(_aiChatId!),
        data: formData,
      );

      if (response.data != null && response.data['file'] != null) {
        final messageContent = _popupMessageController.text.trim();
        final content = messageContent.isNotEmpty 
            ? '$messageContent\n📎 $fileName'
            : '📎 $fileName';
        await _sendPopupMessageWithContent(content);
      }
    } catch (e) {
      debugPrint('Ошибка загрузки файла для AI: $e');
      rethrow;
    }
  }

  Future<void> _uploadFileForAIWeb(html.File file) async {
    try {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoadEnd.first;
      
      final result = reader.result;
      Uint8List uint8list;
      if (result is Uint8List) {
        uint8list = result;
      } else if (result is ByteBuffer) {
        uint8list = result.asUint8List();
      } else {
        throw Exception('Неподдерживаемый формат результата FileReader');
      }
      
      final fileName = file.name;
      
      if (_aiChatId == null) {
        final response = await ServiceLocator().apiClient.dio.get(
          ApiEndpoints.aiChatHistory,
        );
        if (response.data != null && response.data['chatId'] != null) {
          _aiChatId = response.data['chatId'];
        } else {
          throw Exception('AI чат не найден');
        }
      }

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          uint8list,
          filename: fileName,
        ),
      });

      final response = await ServiceLocator().apiClient.dio.post(
        ApiEndpoints.uploadFile(_aiChatId!),
        data: formData,
      );

      if (response.data != null && response.data['file'] != null) {
        final messageContent = _popupMessageController.text.trim();
        final content = messageContent.isNotEmpty 
            ? '$messageContent\n📎 $fileName'
            : '📎 $fileName';
        await _sendPopupMessageWithContent(content);
      }
    } catch (e) {
      debugPrint('Ошибка загрузки файла для AI: $e');
      rethrow;
    }
  }

  Future<void> _sendPopupMessageWithContent(String content) async {
    if (content.isEmpty) return;

    final userMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: 'popup',
      userId: 'current_user',
      content: content,
      type: MessageType.text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _popupMessages.add(userMessage);
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

    try {
      final response = await ServiceLocator().apiClient.dio.post(
        ApiEndpoints.aiChat,
        data: {'question': content},
      );
      
      if (response.data != null) {
        final userMessageData = response.data['userMessage'];
        final aiMessageData = response.data['aiMessage'];
        
        if (userMessageData != null) {
          setState(() {
            _popupMessages.add(MessageModel.fromJson(userMessageData));
          });
        }
        
        if (aiMessageData != null) {
          setState(() {
            _popupMessages.add(MessageModel.fromJson(aiMessageData));
          });
          
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
      }
    } catch (e) {
      debugPrint('Ошибка отправки сообщения AI: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка отправки сообщения: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendPopupMessage() async {
    final content = _popupMessageController.text.trim();
    await _sendPopupMessageWithContent(content);
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
                        _GlassButton(
                          svg: '''
                          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <path d="M18 18L12 12M12 12L6 6M12 12L18 6M12 12L6 18" stroke="#D6DBE2" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                          </svg>
                          ''',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 12),
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
              Container(
                padding: EdgeInsets.only(
                  left: 8,
                  right: 8,
                  top: 8,
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                ),
                decoration: const BoxDecoration(
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
                        _GlassButton(
                          icon: Icons.add,
                          onPressed: _pickAndUploadFileForAI,
                        ),
                        const SizedBox(width: 8),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    message.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                ),
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
              Positioned.fill(
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
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
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.2),
                  ),
                ),
              ),
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
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: const SizedBox.expand(),
              ),
            ),
          ),
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
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.black.withOpacity(0.2),
              ),
            ),
          ),
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
                right: widget.hasText ? 48 : 16,
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

