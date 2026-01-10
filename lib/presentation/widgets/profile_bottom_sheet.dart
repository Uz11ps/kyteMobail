import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import '../../data/models/user_model.dart';
import '../../core/di/service_locator.dart';
import '../../core/config/app_config.dart';
import '../bloc/auth/auth_bloc.dart';
import '../screens/auth/auth_identifier_screen.dart';
import '../../core/constants/api_endpoints.dart';

class ProfileBottomSheet extends StatefulWidget {
  final UserModel user;

  const ProfileBottomSheet({super.key, required this.user});

  @override
  State<ProfileBottomSheet> createState() => _ProfileBottomSheetState();
}

class _ProfileBottomSheetState extends State<ProfileBottomSheet> {
  bool _isEditing = false;
  bool _isLoading = false;
  String? _avatarUrl;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _aboutController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final names = widget.user.name?.split(' ') ?? [''];
    _firstNameController = TextEditingController(text: names[0]);
    _lastNameController = TextEditingController(text: names.length > 1 ? names[1] : '');
    _nicknameController = TextEditingController(text: widget.user.nickname ?? '');
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _aboutController = TextEditingController(text: widget.user.about ?? '');
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _avatarUrl = widget.user.avatarUrl;
  }

  Future<void> _pickAvatar() async {
    try {
      setState(() => _isLoading = true);
      
      String? filePath;
      Uint8List? fileBytes;
      String? fileName;

      if (kIsWeb) {
        final input = html.FileUploadInputElement()..accept = 'image/*';
        input.click();
        await input.onChange.first;
        if (input.files != null && input.files!.isNotEmpty) {
          final file = input.files![0];
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          await reader.onLoadEnd.first;
          fileBytes = reader.result as Uint8List?;
          fileName = file.name;
        }
      } else {
        final result = await FilePicker.platform.pickFiles(type: FileType.image);
        if (result != null && result.files.single.path != null) {
          filePath = result.files.single.path;
          fileName = result.files.single.name;
        }
      }

      if ((filePath != null || fileBytes != null) && fileName != null) {
        final dio = ServiceLocator().apiClient.dio;
        FormData formData;
        
        if (kIsWeb) {
          formData = FormData.fromMap({
            'avatar': MultipartFile.fromBytes(fileBytes!, filename: fileName),
          });
        } else {
          formData = FormData.fromMap({
            'avatar': await MultipartFile.fromFile(filePath!, filename: fileName),
          });
        }

        final response = await dio.post(ApiEndpoints.uploadAvatar, data: formData);
        
        if (response.data != null && response.data['avatarUrl'] != null) {
          setState(() {
            _avatarUrl = response.data['avatarUrl'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated successfully')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking avatar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating avatar: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    try {
      setState(() => _isLoading = true);
      final userRepository = ServiceLocator().userRepository;
      
      final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
      
      await userRepository.updateProfile(
        name: fullName.isEmpty ? null : fullName,
        nickname: _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        about: _aboutController.text.trim().isEmpty ? null : _aboutController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      );
      
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      debugPrint('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

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
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _isEditing ? _buildEditView() : _buildProfileView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              if (_isEditing) {
                setState(() => _isEditing = false);
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle, border: Border.all(color: Colors.white12)),
              child: Icon(_isEditing ? Icons.arrow_back_ios_new : Icons.close, color: Colors.white, size: 20),
            ),
          ),
          Text(_isEditing ? 'Edit your profile' : 'Your profile', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          GestureDetector(
            onTap: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle, border: Border.all(color: Colors.white12)),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(_isEditing ? Icons.check : Icons.edit_outlined, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
    final avatarUrl = _avatarUrl != null && _avatarUrl!.startsWith('http')
        ? _avatarUrl
        : _avatarUrl != null
            ? '$baseUrl$_avatarUrl'
            : null;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white12)),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? Text(widget.user.name?[0] ?? 'U', style: const TextStyle(fontSize: 32)) : null,
              ),
              const SizedBox(height: 16),
              Text(widget.user.name ?? 'No Name', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              _buildInfoField(
                'Phone number',
                widget.user.phone ?? 'Add your phone number',
                isVerified: widget.user.phone != null,
                isLink: widget.user.phone == null,
                onTap: widget.user.phone == null
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AuthIdentifierScreen(mode: AuthIdentifierMode.addPhone),
                          ),
                        );
                      }
                    : null,
              ),
              const SizedBox(height: 24),
              _buildInfoField(
                'Email',
                widget.user.email ?? 'Add your email address',
                isLink: widget.user.email == null,
                onTap: widget.user.email == null
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AuthIdentifierScreen(mode: AuthIdentifierMode.addEmail),
                          ),
                        );
                      }
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
            child: const Text('Log out', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildEditView() {
    final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
    final avatarUrl = _avatarUrl != null && _avatarUrl!.startsWith('http')
        ? _avatarUrl
        : _avatarUrl != null
            ? '$baseUrl$_avatarUrl'
            : null;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white12)),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickAvatar,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null ? Text(widget.user.name?[0] ?? 'U') : null,
                    ),
                    const SizedBox(width: 16),
                    Text('Set a new photo', style: TextStyle(color: Colors.blue.shade300, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildEditField('FIRST NAME', _firstNameController),
              const SizedBox(height: 16),
              _buildEditField('LAST NAME', _lastNameController),
              const SizedBox(height: 16),
              _buildEditField('NICKNAME', _nicknameController),
              const SizedBox(height: 16),
              _buildEditField('PHONE NUMBER', _phoneController),
              const SizedBox(height: 16),
              _buildEditField('ABOUT', _aboutController),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoField(String label, String value, {bool isVerified = false, bool isLink = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: isLink ? Colors.blue.shade300 : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isVerified) const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600)),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
      ],
    );
  }
}






