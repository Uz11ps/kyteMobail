import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import '../../bloc/auth/auth_bloc.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/config/app_config.dart';
import '../../../core/routing/app_router.dart';
import 'package:intl/intl.dart';
import 'edit_profile_screen.dart';

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
    try {
      final userRepository = ServiceLocator().userRepository;
      final user = await userRepository.getCurrentUser();
      setState(() {
        _user = user;
        _birthday = user.birthday != null ? DateFormat('dd.MM.yyyy').format(user.birthday!) : null;
        _about = user.about;
      });
    } catch (e) {
      // Fallback на authRepository если userRepository не работает
      final authRepository = ServiceLocator().authRepository;
      final user = await authRepository.getCurrentUser();
      setState(() {
        _user = user;
        _birthday = null;
        _about = null;
      });
    }
  }

  Future<void> _editProfile() async {
    if (_user == null) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: _user!),
      ),
    );
    if (result == true) {
      _loadUserData();
    }
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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.login,
            (route) => false,
          );
        }
      },
      child: Scaffold(
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
                      // Кнопка редактирования
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _editProfile,
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
                                    <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                                      <path d="M14.1667 2.5C14.3855 2.28113 14.6454 2.10751 14.9313 1.98906C15.2173 1.87061 15.5238 1.80957 15.8333 1.80957C16.1429 1.80957 16.4494 1.87061 16.7353 1.98906C17.0213 2.10751 17.2812 2.28113 17.5 2.5C17.7189 2.71887 17.8925 2.97881 18.0109 3.26476C18.1294 3.55072 18.1904 3.85724 18.1904 4.16667C18.1904 4.47609 18.1294 4.78261 18.0109 5.06857C17.8925 5.35452 17.7189 5.61446 17.5 5.83333L6.25 17.0833L1.66667 18.3333L2.91667 13.75L14.1667 2.5Z" stroke="#D6DBE2" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                                    </svg>
                                    ''',
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
                    Builder(
                      builder: (context) {
                        final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
                        final avatarUrl = _user?.avatarUrl != null && _user!.avatarUrl!.startsWith('http')
                            ? _user!.avatarUrl
                            : _user?.avatarUrl != null
                                ? '$baseUrl${_user!.avatarUrl}'
                                : null;

                        return Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                              width: 1,
                            ),
                            gradient: _user != null && avatarUrl == null
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
                          child: avatarUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Text(
                                          _getInitials(_user?.name),
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
                                    _getInitials(_user?.name),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 48,
                                    ),
                                  ),
                                ),
                        );
                      },
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
                                  value: _user?.nickname ?? _user?.name ?? 'Не указан',
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
                          const SizedBox(height: 24),
                          // Кнопка выхода
                          SizedBox(
                            width: double.infinity,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      final shouldLogout = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: const Color(0xFF1D2631),
                                          title: const Text(
                                            'Выход',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                          content: const Text(
                                            'Вы уверены, что хотите выйти?',
                                            style: TextStyle(color: Colors.white70),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: const Text('Отмена'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                              child: const Text('Выйти'),
                                            ),
                                          ],
                                        ),
                                      );
                                      
                                      if (shouldLogout == true) {
                                        context.read<AuthBloc>().add(AuthLogoutRequested());
                                        // Навигация на экран входа будет обработана через BlocListener
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.red.withOpacity(0.2),
                                            Colors.red.withOpacity(0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: Colors.red.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.logout,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Выйти',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
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
            ),
          ],
        ),
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

