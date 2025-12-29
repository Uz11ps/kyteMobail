import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../data/models/user_model.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/config/app_config.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _nicknameController;
  late TextEditingController _phoneController;
  late TextEditingController _aboutController;
  late TextEditingController _birthdayController;
  DateTime? _birthday;
  bool _isLoading = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name ?? '');
    _nicknameController = TextEditingController(text: widget.user.nickname ?? '');
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _aboutController = TextEditingController(text: widget.user.about ?? '');
    _birthday = widget.user.birthday;
    _birthdayController = TextEditingController(
      text: _birthday != null ? DateFormat('dd.MM.yyyy').format(_birthday!) : '',
    );
    _avatarUrl = widget.user.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _aboutController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    input.onChange.listen((e) async {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();
        
        reader.onLoadEnd.listen((e) async {
          try {
            setState(() => _isLoading = true);
            final dio = ServiceLocator().apiClient.dio;
            
            // Получаем байты из FileReader (readAsArrayBuffer возвращает ByteBuffer из dart:typed_data)
            final result = reader.result;
            if (result == null) {
              throw Exception('Не удалось прочитать файл');
            }
            
            // Конвертируем ByteBuffer в List<int>
            List<int> bytes;
            if (result is ByteBuffer) {
              bytes = result.asUint8List().toList();
            } else {
              throw Exception('Неподдерживаемый тип результата: ${result.runtimeType}');
            }
            
            // Определяем ContentType
            String? contentType;
            if (file.type != null && file.type!.isNotEmpty) {
              contentType = file.type;
            } else {
              // Определяем по расширению
              final ext = file.name.split('.').last.toLowerCase();
              switch (ext) {
                case 'jpg':
                case 'jpeg':
                  contentType = 'image/jpeg';
                  break;
                case 'png':
                  contentType = 'image/png';
                  break;
                case 'gif':
                  contentType = 'image/gif';
                  break;
                case 'webp':
                  contentType = 'image/webp';
                  break;
                default:
                  contentType = 'image/jpeg';
              }
            }
            
            // Создаем FormData для загрузки
            // Для веб используем простую строку для contentType
            final formData = FormData.fromMap({
              'avatar': MultipartFile.fromBytes(
                bytes,
                filename: file.name,
              ),
            });
            
            // Устанавливаем Content-Type вручную через заголовки
            final headers = <String, dynamic>{};
            if (contentType != null) {
              headers['Content-Type'] = contentType;
            }
            
            // Загружаем аватар напрямую через Dio
            final response = await dio.post(
              '/api/user/avatar',
              data: formData,
              options: Options(
                headers: headers.isNotEmpty ? headers : null,
              ),
            );
            
            if (response.data != null && response.data['avatarUrl'] != null) {
              setState(() {
                _avatarUrl = response.data['avatarUrl'];
                _isLoading = false;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Аватар успешно загружен')),
              );
            } else {
              throw Exception('URL аватара не получен');
            }
          } catch (e) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка загрузки аватара: $e')),
            );
          }
        });
        
        reader.onError.listen((e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка чтения файла')),
          );
        });
        
        // Читаем файл как массив байтов
        reader.readAsArrayBuffer(file);
      }
    });
  }

  Future<void> _selectBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthday = picked;
        _birthdayController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    try {
      setState(() => _isLoading = true);
      final userRepository = ServiceLocator().userRepository;
      
      await userRepository.updateProfile(
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        nickname: _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        about: _aboutController.text.trim().isEmpty ? null : _aboutController.text.trim(),
        birthday: _birthday,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль успешно обновлен')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления профиля: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) {
      final email = widget.user.email;
      if (email != null && email.isNotEmpty) {
        return email[0].toUpperCase();
      }
      return 'U';
    }
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
    final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
    final avatarUrl = _avatarUrl != null && _avatarUrl!.startsWith('http')
        ? _avatarUrl
        : _avatarUrl != null
            ? '$baseUrl$_avatarUrl'
            : null;

    return Scaffold(
      backgroundColor: const Color(0xFF1D2631),
      body: SafeArea(
        child: Column(
          children: [
            // Заголовок
            ClipRRect(
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
                      SizedBox(
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
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Редактирование профиля',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),
            // Контент
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Аватарка
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                                width: 1,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _getAvatarColor(widget.user.id),
                                  _getAvatarColor(widget.user.id),
                                ],
                              ),
                            ),
                            child: avatarUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                          child: Text(
                                            _getInitials(_nameController.text.isNotEmpty ? _nameController.text : widget.user.name),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 48,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      _getInitials(_nameController.text.isNotEmpty ? _nameController.text : widget.user.name),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 48,
                                      ),
                                    ),
                                  ),
                          ),
                          if (_isLoading)
                            Positioned.fill(
                              child: ClipOval(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: Container(
                                    color: Colors.black.withOpacity(0.5),
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0072FF),
                                border: Border.all(
                                  color: const Color(0xFF1D2631),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Поля ввода
                    _EditField(
                      label: 'Имя',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 12),
                    _EditField(
                      label: 'Никнейм',
                      controller: _nicknameController,
                    ),
                    const SizedBox(height: 12),
                    _EditField(
                      label: 'Номер телефона',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _EditField(
                      label: 'День рождения',
                      controller: _birthdayController,
                      readOnly: true,
                      onTap: _selectBirthday,
                    ),
                    const SizedBox(height: 12),
                    _EditField(
                      label: 'О себе',
                      controller: _aboutController,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    // Кнопка сохранения
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0072FF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Сохранить',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;

  const _EditField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.06),
                Colors.black.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1,
            ),
            color: Colors.black.withOpacity(0.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: keyboardType,
                readOnly: readOnly,
                onTap: onTap,
                maxLines: maxLines,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

