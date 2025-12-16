import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import '../../bloc/auth/auth_bloc.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../core/di/service_locator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  String? _birthday;
  String? _about;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authRepository = ServiceLocator().authRepository;
    final user = await authRepository.getCurrentUser();
    setState(() {
      _user = user;
      // Демо данные для полей, которых нет в UserModel
      _birthday = '15.03.1990';
      _about = 'Разработчик мобильных приложений';
    });
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) {
      final email = _user?.email ?? '';
      if (email.isNotEmpty) {
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
    return Scaffold(
      backgroundColor: const Color(0xFF1D2631),
      body: SafeArea(
        child: Column(
          children: [
            // Заголовок со стеклянным фоном
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
                      // Кнопка назад
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
                            'Профиль',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Отступ для симметрии
                    ],
                  ),
                ),
              ),
            ),
            // Контент профиля
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Аватарка слева
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 1,
                        ),
                        gradient: _user != null
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _getAvatarColor(_user!.id),
                                  _getAvatarColor(_user!.id),
                                ],
                              )
                            : null,
                        color: _user == null ? const Color(0xFF7F00FF) : null,
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(_user?.name),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 48,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Блоки справа
                    Expanded(
                      child: Column(
                        children: [
                          // Первая строка: Никнейм и Номер телефона
                          Row(
                            children: [
                              Expanded(
                                child: _ProfileField(
                                  label: 'Никнейм',
                                  value: _user?.name ?? 'Не указан',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ProfileField(
                                  label: 'Номер телефона',
                                  value: _user?.phone ?? 'Не указан',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Вторая строка: Email и День рождения
                          Row(
                            children: [
                              Expanded(
                                child: _ProfileField(
                                  label: 'Email',
                                  value: _user?.email ?? 'Не указан',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ProfileField(
                                  label: 'День рождения',
                                  value: _birthday ?? 'Не указан',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Третья строка: О себе (в два раза выше)
                          _ProfileField(
                            label: 'О себе',
                            value: _about ?? 'Не указано',
                            isMultiline: true,
                            height: 2,
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
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final bool isMultiline;
  final int height; // Множитель высоты (1 для обычных, 2 для "О себе")

  const _ProfileField({
    required this.label,
    required this.value,
    this.isMultiline = false,
    this.height = 1,
  });

  @override
  Widget build(BuildContext context) {
    // Базовая высота для обычных полей
    const baseHeight = 80.0;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: baseHeight * height,
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
            mainAxisAlignment: MainAxisAlignment.start,
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
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: isMultiline ? null : 1,
                  overflow: isMultiline ? null : TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

