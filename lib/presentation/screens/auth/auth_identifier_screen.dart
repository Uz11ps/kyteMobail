import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import '../../bloc/auth/auth_bloc.dart';
import '../../../core/routing/app_router.dart';
import 'phone_verification_screen.dart';

enum AuthIdentifierMode {
  loginEmail,
  addEmail,
  addPhone,
}

class AuthIdentifierScreen extends StatefulWidget {
  final AuthIdentifierMode mode;

  const AuthIdentifierScreen({
    super.key,
    this.mode = AuthIdentifierMode.loginEmail,
  });

  @override
  State<AuthIdentifierScreen> createState() => _AuthIdentifierScreenState();
}

class _AuthIdentifierScreenState extends State<AuthIdentifierScreen> {
  final _identifierController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final val = _identifierController.text.trim();
    if (widget.mode == AuthIdentifierMode.addPhone) {
      return val.length >= 10; // Simple phone check
    }
    return val.isNotEmpty && val.contains('@') && val.contains('.');
  }

  void _handleContinue() {
    print('🚀 AuthIdentifierScreen: Continue button pressed');
    // Using simple validation since we use TextField not TextFormField
    if (_isValid) {
      final identifier = _identifierController.text.trim();
      print('🚀 AuthIdentifierScreen: Valid identifier: $identifier');
      
      // If adding phone, we might want to normalize it
      String finalIdentifier = identifier;
      if (widget.mode == AuthIdentifierMode.addPhone && !identifier.startsWith('+')) {
        finalIdentifier = '+7$identifier';
      }

      print('🚀 AuthIdentifierScreen: Navigating to PhoneVerificationScreen');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PhoneVerificationScreen(
            phoneNumber: finalIdentifier,
            isEmail: widget.mode != AuthIdentifierMode.addPhone,
            isLinking: widget.mode == AuthIdentifierMode.addEmail || widget.mode == AuthIdentifierMode.addPhone,
          ),
        ),
      );
    } else {
      print('🚀 AuthIdentifierScreen: Invalid identifier');
    }
  }

  String _getTitle() {
    switch (widget.mode) {
      case AuthIdentifierMode.loginEmail:
        return 'Log In With Email';
      case AuthIdentifierMode.addEmail:
        return 'Add Email Address';
      case AuthIdentifierMode.addPhone:
        return 'Add Phone Number';
    }
  }

  String _getPrompt() {
    switch (widget.mode) {
      case AuthIdentifierMode.loginEmail:
      case AuthIdentifierMode.addEmail:
        return 'Please enter your\nemail address';
      case AuthIdentifierMode.addPhone:
        return 'Please confirm your\nphone number with Telegram';
    }
  }

  String _getLabel() {
    return widget.mode == AuthIdentifierMode.addPhone ? 'PHONE NUMBER' : 'EMAIL ADDRESS';
  }

  String _getHint() {
    return widget.mode == AuthIdentifierMode.addPhone ? '( _ _ _ ) - _ _ _ - _ _ - _ _' : 'name@example.com';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161B22),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            widget.mode == AuthIdentifierMode.loginEmail ? Icons.close : Icons.arrow_back_ios,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _getTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Text(
                _getPrompt(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 40),
              if (widget.mode == AuthIdentifierMode.addPhone) ...[
                // Mockup 3 shows "Continue with Telegram" button
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      // Logic for Telegram linking
                      // For now, let's show the input field version too or just navigate to verification
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF161B22),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Continue with Telegram',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.send, size: 24),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'OR ENTER MANUALLY',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Identifier Input Field with Glass Effect
                    Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getLabel(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Row(
                            children: [
                              if (widget.mode == AuthIdentifierMode.addPhone)
                                const Text(
                                  '+7 ',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                              Expanded(
                                child: TextField(
                                  controller: _identifierController,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.only(top: 4),
                                    hintText: _getHint(),
                                    hintStyle: const TextStyle(color: Colors.white24),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  keyboardType: widget.mode == AuthIdentifierMode.addPhone ? TextInputType.phone : TextInputType.emailAddress,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: _isValid ? _handleContinue : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isValid ? Colors.white : Colors.white.withOpacity(0.2),
                          foregroundColor: const Color(0xFF161B22),
                          disabledBackgroundColor: Colors.white.withOpacity(0.2),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _isValid ? const Color(0xFF161B22) : Colors.white.withOpacity(0.3),
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
    );
  }
}
