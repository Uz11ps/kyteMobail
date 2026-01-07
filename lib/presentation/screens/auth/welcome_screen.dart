import 'package:flutter/material.dart';
import '../../widgets/kyte_logo.dart';
import '../../../core/routing/app_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161B22),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Logo
              const KyteLogo(width: 100, height: 36),
              const SizedBox(height: 60),
              // Title
              const Text(
                'Your work.\nOne place.\nFinally.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              // Buttons
              _AuthButton(
                text: 'Log In With Email',
                icon: Icons.alternate_email,
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.login);
                },
              ),
              const SizedBox(height: 12),
              _AuthButton(
                text: 'Log In With Telegram',
                icon: Icons.send, // Telegram-like icon
                onPressed: () {
                  // Telegram login logic or placeholder
                },
              ),
              const SizedBox(height: 40),
              // Footer
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'By continue using the service you are agreeing\nwith '),
                        TextSpan(
                          text: 'the Terms Of Use',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'the Privacy Policy',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {

