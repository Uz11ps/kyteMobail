import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../bloc/auth/auth_bloc.dart';
import '../../../core/routing/app_router.dart';
import 'phone_verification_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_formatPhoneNumber);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_formatPhoneNumber);
    _phoneController.dispose();
    super.dispose();
  }

  void _formatPhoneNumber() {
    final text = _phoneController.text.replaceAll(' ', '').replaceAll('(', '').replaceAll(')', '').replaceAll('-', '');
    // Ограничиваем до 10 цифр
    final limitedText = text.length > 10 ? text.substring(0, 10) : text;
    
    final buffer = StringBuffer();
    for (int i = 0; i < limitedText.length; i++) {
      if (i == 0) {
        buffer.write('(');
      } else if (i == 3) {
        buffer.write(') - ');
      } else if (i == 6) {
        buffer.write(' - ');
      } else if (i == 8) {
        buffer.write(' - ');
      }
      buffer.write(limitedText[i]);
    }
    final formatted = buffer.toString();
    if (_phoneController.text != formatted) {
      final oldLength = _phoneController.text.length;
      final newLength = formatted.length;
      final cursorOffset = newLength > oldLength ? newLength - oldLength : 0;
      final newCursorPosition = (_phoneController.selection.baseOffset + cursorOffset).clamp(0, formatted.length);
      _phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );
    }
    setState(() {}); // Обновляем UI для изменения цвета кнопки
  }
  
  bool get _hasPhoneNumber {
    final text = _phoneController.text.replaceAll(' ', '').replaceAll('(', '').replaceAll(')', '').replaceAll('-', '');
    return text.length == 10;
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate()) {
      final phone = '+7${_phoneController.text.replaceAll(' ', '').replaceAll('(', '').replaceAll(')', '').replaceAll('-', '')}';
      context.read<AuthBloc>().add(
            AuthPhoneCodeSendRequested(phone: phone),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushReplacementNamed(AppRouter.chats);
        } else if (state is AuthPhoneCodeSent) {
          // Переход на экран ввода кода
          final phone = '+7${_phoneController.text.replaceAll(' ', '').replaceAll('(', '').replaceAll(')', '').replaceAll('-', '')}';
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PhoneVerificationScreen(phoneNumber: phone),
            ),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1D2631),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Логотип
                const _KyteLogo(),
                const SizedBox(height: 48),
                // Заголовок
                const Text(
                  'Your work. One place.\nFinally.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 40),
                // Форма
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Поле ввода телефона
                      SizedBox(
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
                            // Content
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Лейбл PHONE NUMBER
                                  Text(
                                    'PHONE NUMBER',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  // Поле ввода
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      const Text(
                                        '+7',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          height: 1.0,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _phoneController,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.left,
                                          textAlignVertical: TextAlignVertical.center,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                          ],
                                          maxLength: 20, // Максимальная длина с форматированием (10 цифр + форматирование)
                                          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            height: 1.0,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: '( _ _ _ ) - _ _ _ - _ _ - _ _',
                                            hintStyle: TextStyle(
                                              color: Colors.white.withOpacity(0.3),
                                              fontSize: 16,
                                              letterSpacing: 1.5,
                                              height: 1.0,
                                            ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            filled: false,
                                            contentPadding: EdgeInsets.zero,
                                            isDense: true,
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Введите номер телефона';
                                            }
                                            final digits = value.replaceAll(' ', '').replaceAll('(', '').replaceAll(')', '').replaceAll('-', '');
                                            if (digits.length != 10) {
                                              return 'Некорректный номер телефона';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Кнопка Continue
                      SizedBox(
                        height: 56,
                        child: BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthLoading;
                            final hasPhone = _hasPhoneNumber;
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: (isLoading || !hasPhone) ? null : _handleContinue,
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: hasPhone 
                                        ? Colors.white 
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                  child: Center(
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF1D2631),
                                            ),
                                          )
                                        : Text(
                                            'Continue',
                                            style: TextStyle(
                                              color: hasPhone 
                                                  ? const Color(0xFF1D2631) 
                                                  : const Color(0xFF1D2631).withOpacity(0.5),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Текст с согласием
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        height: 1.4,
                      ),
                      children: const [
                        TextSpan(text: 'By continue using the service you are agreeing with the '),
                        TextSpan(
                          text: 'Terms Of Use',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ' and '),
                        TextSpan(
                          text: 'the Privacy Policy',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
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
    );
  }
}

class _KyteLogo extends StatelessWidget {
  const _KyteLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 44,
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

