import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'dart:async';
import '../../bloc/auth/auth_bloc.dart';
import '../../../core/routing/app_router.dart';
import 'profile_setup_screen.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isEmail;
  final bool isLinking;

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.isEmail = false,
    this.isLinking = false,
  });

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _resendTimer;
  int _resendSeconds = 60;
  bool _showKeyboard = true;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // In new design, keyboard is likely always shown or shown by default
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
      if (widget.isEmail) {
        // Handle email resend logic
      } else {
        context.read<AuthBloc>().add(
              AuthPhoneCodeSendRequested(phone: widget.phoneNumber),
            );
      }
      _startResendTimer();
    }
  }

  void _handleCodeSubmit() {
    if (_codeController.text.length == 6) {
      _focusNode.unfocus();
      if (widget.isLinking) {
        // Logic for linking email/phone to profile
        // For now, simulating success and going back to profile
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully linked!')),
        );
        Navigator.of(context).pop(); // Back to Identifier screen
        Navigator.of(context).pop(); // Back to Profile
      } else if (widget.isEmail) {
        // Existing email logic
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        );
      } else {
        context.read<AuthBloc>().add(
              AuthPhoneLoginRequested(
                phone: widget.phoneNumber,
                code: _codeController.text,
              ),
            );
      }
    }
  }

  void _onNumberPressed(String number) {
    if (_codeController.text.length < 6) {
      setState(() {
        _codeController.text += number;
      });
      if (_codeController.text.length == 6) {
        _handleCodeSubmit();
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

  String _formatDisplayNumber(String val) {
    if (widget.isEmail) return val;
    // Форматируем номер для отображения
    final digits = val.replaceAll('+7', '').replaceAll(' ', '').replaceAll('(', '').replaceAll(')', '').replaceAll('-', '');
    if (digits.length == 10) {
      return '+7 ${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 8)} ${digits.substring(8)}';
    }
    return val;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // If authenticated but name is missing, go to profile setup
          // For MVP, assuming we go to chats if authenticated
          Navigator.of(context).pushReplacementNamed(AppRouter.chats);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF161B22),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.isEmail ? 'Confirm your email' : 'Confirm your number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Body Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Text(
                      'Please enter the code sent to',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDisplayNumber(widget.phoneNumber),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              // Code Input Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        final hasDigit = index < _codeController.text.length;
                        if (hasDigit) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              _codeController.text[index],
                              style: const TextStyle(
                                color: Color(0xFFFF8A8A), // Reddish color from mockup
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Send again
              TextButton(
                onPressed: _resendSeconds == 0 ? _handleResendCode : null,
                child: Text(
                  _resendSeconds > 0 
                      ? 'Send again ($_resendSeconds)' 
                      : 'Send again',
                  style: TextStyle(
                    color: _resendSeconds > 0 
                        ? Colors.white.withOpacity(0.4) 
                        : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              // Custom Keyboard
              _NumberKeyboard(
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
      ['1', ' '], ['2', 'DEF'], ['3', 'DEF'], // Using labels from mockup
      ['4', 'DEF'], ['5', 'DEF'], ['6', 'DEF'],
      ['7', 'DEF'], ['8', 'DEF'], ['9', 'DEF'],
      [null, null], ['0', ' '], ['backspace', null],
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int row = 0; row < 4; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: key == 'backspace' ? onBackspacePressed : () => onNumberPressed(key as String),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.08),
          ),
          child: key == 'backspace'
              ? const Icon(Icons.backspace_outlined, color: Colors.white, size: 24)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      key as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (label != null && label.toString().trim().isNotEmpty)
                      Text(
                        label.toString(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
