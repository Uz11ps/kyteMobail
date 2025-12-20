import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../bloc/auth/auth_bloc.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/config/app_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isPhoneMode = false;
  bool _codeSent = false;
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  GoogleSignIn? _googleSignIn;
  Timer? _resendTimer;
  int _resendSeconds = 60;
  
  GoogleSignIn? get googleSignIn {
    if (_googleSignIn == null) {
      try {
        _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );
      } catch (e) {
        debugPrint('⚠️  Ошибка инициализации GoogleSignIn: $e');
        return null;
      }
    }
    return _googleSignIn;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _handleSendCode() {
    // Валидация номера телефона перед отправкой
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите номер телефона')),
      );
      return;
    }
    
    // Нормализация номера телефона
    String normalizedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (!normalizedPhone.startsWith('+')) {
      if (normalizedPhone.startsWith('8')) {
        normalizedPhone = '+7' + normalizedPhone.substring(1);
      } else if (normalizedPhone.startsWith('7')) {
        normalizedPhone = '+' + normalizedPhone;
      } else {
        normalizedPhone = '+7' + normalizedPhone;
      }
    }
    
    context.read<AuthBloc>().add(
      AuthPhoneCodeSendRequested(phone: normalizedPhone),
    );
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите номер телефона';
    }
    
    // Нормализация номера для проверки
    String cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Если номер начинается с 8, заменяем на +7
    if (cleaned.startsWith('8')) {
      cleaned = '+7' + cleaned.substring(1);
    }
    // Если номер начинается с 7, добавляем +
    else if (cleaned.startsWith('7') && !cleaned.startsWith('+7')) {
      cleaned = '+' + cleaned;
    }
    // Если номер не начинается с +, добавляем +7
    else if (!cleaned.startsWith('+')) {
      cleaned = '+7' + cleaned;
    }
    
    // Проверка формата: +7XXXXXXXXXX (11 цифр после +7)
    final phoneRegex = RegExp(r'^\+7\d{10}$');
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Введите номер в формате +7XXXXXXXXXX (11 цифр)';
    }
    
    return null;
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;

    if (_isPhoneMode) {
      if (!_codeSent) {
        _handleSendCode();
        return;
      }
      
      // Нормализация номера телефона перед входом
      String normalizedPhone = _phoneController.text.trim().replaceAll(RegExp(r'[^\d+]'), '');
      if (!normalizedPhone.startsWith('+')) {
        if (normalizedPhone.startsWith('8')) {
          normalizedPhone = '+7' + normalizedPhone.substring(1);
        } else if (normalizedPhone.startsWith('7')) {
          normalizedPhone = '+' + normalizedPhone;
        } else {
          normalizedPhone = '+7' + normalizedPhone;
        }
      }
      
      context.read<AuthBloc>().add(
        AuthPhoneLoginRequested(
          phone: normalizedPhone,
          code: _codeController.text.trim(),
        ),
      );
    } else {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: _emailController.text,
              password: _passwordController.text,
            ),
          );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      // Проверка доступности GoogleSignIn
      final signIn = googleSignIn;
      if (signIn == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign In недоступен на этой платформе'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final GoogleSignInAccount? account = await signIn.signIn();
      if (account == null) {
        // Пользователь отменил вход
        return;
      }

      // Проверяем наличие email перед запросом authentication
      final accountEmail = account.email;
      if (accountEmail == null || accountEmail.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось получить email от Google'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      GoogleSignInAuthentication? auth;
      try {
        auth = await account.authentication;
      } catch (e, stackTrace) {
        String errorMessage = 'Ошибка получения данных от Google';
        try {
          if (e != null) {
            try {
              final errorStr = e.toString();
              if (errorStr.isNotEmpty && errorStr != 'null') {
                errorMessage = errorStr;
              }
            } catch (toStringError) {
              // Если toString() сам выбрасывает ошибку, используем сообщение по умолчанию
              debugPrint('❌ Ошибка при вызове toString(): $toStringError');
            }
          }
        } catch (parseError) {
          // Если проверка e != null выбрасывает ошибку, используем сообщение по умолчанию
          debugPrint('❌ Ошибка при проверке ошибки: $parseError');
        }
        debugPrint('❌ Ошибка получения authentication: $errorMessage');
        try {
          if (e != null) {
            debugPrint('   Тип ошибки: ${e.runtimeType}');
          }
        } catch (_) {
          // Игнорируем ошибки при получении типа
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (auth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось получить данные авторизации от Google'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Проверяем наличие всех необходимых данных
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;
      
      if (idToken == null || idToken.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось получить ID токен от Google'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (accessToken == null || accessToken.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось получить токен доступа от Google'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      context.read<AuthBloc>().add(
        AuthGoogleLoginRequested(
          idToken: idToken,
          accessToken: accessToken,
          email: accountEmail,
          name: account.displayName ?? '',
          picture: account.photoUrl,
          googleId: account.id,
        ),
      );
    } catch (e, stackTrace) {
      String errorMessage = 'Ошибка входа через Google';
      try {
        if (e != null) {
          try {
            final errorStr = e.toString();
            if (errorStr.isNotEmpty && errorStr != 'null') {
              errorMessage = errorStr;
            }
          } catch (toStringError) {
            // Если toString() сам выбрасывает ошибку, используем сообщение по умолчанию
            debugPrint('❌ Ошибка при вызове toString(): $toStringError');
          }
        }
      } catch (parseError) {
        // Если проверка e != null выбрасывает ошибку, используем сообщение по умолчанию
        debugPrint('❌ Ошибка при проверке ошибки: $parseError');
      }
      debugPrint('❌ Google sign in error: $errorMessage');
      try {
        if (e != null) {
          debugPrint('   Тип ошибки: ${e.runtimeType}');
        }
      } catch (_) {
        // Игнорируем ошибки при получении типа
      }
      try {
        if (stackTrace != null) {
          try {
            debugPrint('   Stack trace: $stackTrace');
          } catch (traceError) {
            debugPrint('   Ошибка при логировании stack trace: $traceError');
          }
        }
      } catch (_) {
        // Игнорируем ошибки при проверке stackTrace
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushReplacementNamed(AppRouter.chats);
        } else if (state is AuthPhoneCodeSent) {
          setState(() {
            _codeSent = true;
          });
          _startResendTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Код отправлен на ваш номер телефона'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Вход')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Text(
                    'Добро пожаловать',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Войдите в свой аккаунт',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => setState(() {
                          _isPhoneMode = false;
                          _codeSent = false;
                          _resendTimer?.cancel();
                        }),
                        child: Text(
                          'Email',
                          style: TextStyle(
                            color: _isPhoneMode ? null : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _isPhoneMode = true;
                          _codeSent = false;
                          _resendTimer?.cancel();
                        }),
                        child: Text(
                          'Телефон',
                          style: TextStyle(
                            color: !_isPhoneMode ? null : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isPhoneMode) ...[
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Номер телефона',
                        hintText: '+7 (999) 123-45-67',
                        prefixIcon: Icon(Icons.phone),
                        helperText: 'Введите номер в формате +7XXXXXXXXXX',
                      ),
                      keyboardType: TextInputType.phone,
                      enabled: !_codeSent,
                      validator: _validatePhone,
                    ),
                    if (!_codeSent) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _handleSendCode();
                          }
                        },
                        icon: const Icon(Icons.send),
                        label: const Text('Получить код'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                    if (_codeSent) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Код отправлен на ${_phoneController.text}',
                                style: const TextStyle(color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Код подтверждения',
                          hintText: '123456',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите код подтверждения';
                          }
                          if (value.length != 6) {
                            return 'Код должен состоять из 6 цифр';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Не получили код? ',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          TextButton(
                            onPressed: _resendSeconds > 0
                                ? null
                                : () {
                                    setState(() {
                                      _codeSent = false;
                                    });
                                    _handleSendCode();
                                  },
                            child: Text(
                              _resendSeconds > 0
                                  ? 'Повторить через $_resendSeconds сек'
                                  : 'Отправить повторно',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ] else ...[
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'example@mail.com',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите email';
                        }
                        if (!value.contains('@')) {
                          return 'Введите корректный email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() => _isPasswordVisible = !_isPasswordVisible);
                          },
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите пароль';
                        }
                        if (value.length < 6) {
                          return 'Пароль должен быть не менее 6 символов';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Войти'),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 1,
                          color: Colors.grey[300],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'или',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 1,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _handleGoogleSignIn,
                    icon: Image.network(
                      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                      height: 24,
                      width: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.g_mobiledata, size: 24);
                      },
                    ),
                    label: const Text('Войти через Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRouter.register);
                    },
                    child: const Text('Нет аккаунта? Зарегистрироваться'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

