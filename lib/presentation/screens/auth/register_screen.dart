import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../../core/routing/app_router.dart';
import 'dart:async';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isPhoneMode = false;
  bool _codeSent = false;
  Timer? _resendTimer;
  int _resendSeconds = 60;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
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

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) return;

    if (_isPhoneMode) {
      if (!_codeSent) {
        _handleSendCode();
        return;
      }
      
      // Нормализация номера телефона перед регистрацией
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
        AuthPhoneRegisterRequested(
          phone: normalizedPhone,
          code: _codeController.text.trim(),
          name: _nameController.text.isEmpty ? null : _nameController.text.trim(),
        ),
      );
    } else {
      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          email: _emailController.text,
          password: _passwordController.text,
          name: _nameController.text.isEmpty ? null : _nameController.text,
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Если имя и никнейм отсутствуют, значит это новый пользователь, отправляем на настройку профиля
          final bool hasName = state.user.name != null && state.user.name!.isNotEmpty;
          final bool hasNickname = state.user.nickname != null && state.user.nickname!.isNotEmpty;
          
          if (!hasName && !hasNickname) {
            Navigator.of(context).pushReplacementNamed(AppRouter.profileSetup);
          } else {
            Navigator.of(context).pushReplacementNamed(AppRouter.chats);
          }
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
        appBar: AppBar(title: const Text('Регистрация')),
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
                    'Создать аккаунт',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Заполните форму для регистрации',
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
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Имя (необязательно)',
                      hintText: 'Иван Иванов',
                      prefixIcon: Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.words,
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Подтвердите пароль',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                          },
                        ),
                      ),
                      obscureText: !_isConfirmPasswordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Подтвердите пароль';
                        }
                        if (value != _passwordController.text) {
                          return 'Пароли не совпадают';
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
                        onPressed: isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isPhoneMode && !_codeSent
                                ? 'Зарегистрироваться'
                                : 'Зарегистрироваться'),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Уже есть аккаунт? Войти'),
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
