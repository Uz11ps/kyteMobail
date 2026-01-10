import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../core/config/app_config.dart';

class UserProfileBottomSheet extends StatelessWidget {
  final UserModel user;

  const UserProfileBottomSheet({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1621),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildProfileView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle, border: Border.all(color: Colors.white12)),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
          Text(user.name ?? 'Profile', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white12)),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: user.avatarUrl != null ? NetworkImage('${AppConfig.apiBaseUrl.replaceAll('/api', '')}${user.avatarUrl}') : null,
            child: user.avatarUrl == null ? Text(user.name?[0] ?? 'U', style: const TextStyle(fontSize: 32)) : null,
          ),
          const SizedBox(height: 16),
          Text(user.name ?? 'No Name', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          _buildInfoField('Phone number', user.phone ?? 'Not provided', isVerified: true),
          const SizedBox(height: 24),
          _buildInfoField('Email', user.email ?? 'Not provided'),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value, {bool isVerified = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isVerified) const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ],
    );
  }
}







