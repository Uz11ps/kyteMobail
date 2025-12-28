import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'dart:async';
import '../../bloc/auth/auth_bloc.dart';
import '../../../core/routing/app_router.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _resendTimer;
  int _resendSeconds = 60;
  bool _showKeyboard = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _focusNode.addListener(() {
      setState(() {
        _showKeyboard = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
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

  void _handleResendCode() {
    if (_resendSeconds == 0) {
      context.read<AuthBloc>().add(
            AuthPhoneCodeSendRequested(phone: widget.phoneNumber),
          );
      _startResendTimer();
    }
  }

  void _handleCodeSubmit() {
    if (_codeController.text.length == 6) {
      _focusNode.unfocus();
      setState(() {
        _showKeyboard = false;
      });
      context.read<AuthBloc>().add(
            AuthPhoneLoginRequested(
              phone: widget.phoneNumber,
              code: _codeController.text,
            ),
          );
    }
  }

  void _onNumberPressed(String number) {
    if (_codeController.text.length < 6) {
      setState(() {
        _codeController.text += number;
      });
      if (_codeController.text.length == 6) {
        // Даем небольшую задержку перед авто-отправкой, чтобы пользователь увидел 6-ю точку
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _codeController.text.length == 6) {
            _handleCodeSubmit();
          }
        });
      }
    }
  }

  void _onBackspacePressed() {
    if (_codeController.text.isNotEmpty) {
      setState(() {
        _codeController.text = _codeController.text.substring(0, _codeController.text.length - 1);
      });
    }
  }

  String _formatPhoneNumber(String phone) {
    // Форматируем номер для отображения
    final digits = phone.replaceAll('+7', '').replaceAll(' ', '').replaceAll('(', '').replaceAll(')', '').replaceAll('-', '');
    if (digits.length == 10) {
      return '+7 ${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 8)} ${digits.substring(8)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushReplacementNamed(AppRouter.chats);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1D2631),
        body: SafeArea(
          child: Column(
            children: [
              // Заголовок
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
                      'Confirm your number',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40), // Для симметрии
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Текст с номером телефона
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Please enter the code sent to\n${_formatPhoneNumber(widget.phoneNumber)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Поле ввода кода
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () {
                    _focusNode.requestFocus();
                    setState(() {
                      _showKeyboard = true;
                    });
                  },
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return SizedBox(
                        height: 56,
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
                            // TextField (скрытый, для фокуса)
                            Opacity(
                              opacity: 0,
                              child: TextField(
                                controller: _codeController,
                                focusNode: _focusNode,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                                onChanged: (value) {
                                  setState(() {}); // Обновляем точки при вводе с системной клавиатуры
                                  if (value.length == 6) {
                                    _handleCodeSubmit();
                                  }
                                },
                              ),
                            ),
                            // Отображение точек или индикатора загрузки
                            Center(
                              child: isLoading 
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(6, (index) {
                                      final hasDigit = index < _codeController.text.length;
                                      return Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 8),
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: hasDigit 
                                              ? Colors.white 
                                              : Colors.white.withOpacity(0.3),
                                        ),
                                      );
                                    }),
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Кнопка подтверждения
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  final isCodeComplete = _codeController.text.length == 6;
                  
                  if (!isCodeComplete && !isLoading) return const SizedBox.shrink();
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton(
                      onPressed: (isCodeComplete && !isLoading) ? _handleCodeSubmit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1D2631),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1D2631)),
                              ),
                            )
                          : const Text(
                              'Confirm',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // Кнопка "Send again"
              TextButton(
                onPressed: _resendSeconds == 0 ? _handleResendCode : null,
                child: Text(
                  _resendSeconds > 0 
                      ? 'Send again ($_resendSeconds)' 
                      : 'Send again',
                  style: TextStyle(
                    color: _resendSeconds > 0 
                        ? Colors.white.withOpacity(0.5) 
                        : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              // Клавиатура
              if (_showKeyboard) _NumberKeyboard(
                onNumberPressed: _onNumberPressed,
                onBackspacePressed: _onBackspacePressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberKeyboard extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onBackspacePressed;

  const _NumberKeyboard({
    required this.onNumberPressed,
    required this.onBackspacePressed,
  });

  @override
  Widget build(BuildContext context) {
    final keypadData = [
      ['1', ''], ['2', 'ABC'], ['3', 'DEF'],
      ['4', 'GHI'], ['5', 'JKL'], ['6', 'MNO'],
      ['7', 'PQRS'], ['8', 'TUV'], ['9', 'WXYZ'],
      [null, null], ['0', '+'], ['backspace', null],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2631),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int row = 0; row < 4; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  for (int col = 0; col < 3; col++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildKey(keypadData[row * 3 + col]),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKey(List<dynamic> data) {
    final key = data[0];
    final label = data[1];

    if (key == null) return const SizedBox.shrink();
    if (key == 'backspace') {
      return _BackspaceKey(onPressed: onBackspacePressed);
    }

    return _NumberKey(
      number: key as String,
      label: label as String,
      onPressed: () => onNumberPressed(key),
    );
  }
}

class _NumberKey extends StatelessWidget {
  final String number;
  final String label;
  final VoidCallback onPressed;

  const _NumberKey({
    required this.number,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF161B22),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
              if (label.isNotEmpty)
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackspaceKey extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackspaceKey({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF161B22),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.backspace_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

// Экспортируем _GlassCircle для использования
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
          // Backdrop blur слой
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
                    const Color(0xFF2A3441).withOpacity(0.50),
                    const Color(0xFF0B1320).withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),
          // Inner highlight
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
          // Иконка по центру
          Center(child: child),
        ],
      ),
    );
  }
}

