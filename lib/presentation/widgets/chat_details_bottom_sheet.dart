import 'package:flutter/material.dart';
import 'dart:ui';
import '../../data/models/chat_model.dart';
import '../../data/models/user_model.dart';
import '../../core/di/service_locator.dart';
import '../../core/config/app_config.dart';

class ChatDetailsBottomSheet extends StatefulWidget {
  final ChatModel chat;
  final bool isAdmin;

  const ChatDetailsBottomSheet({
    super.key,
    required this.chat,
    this.isAdmin = true, // По умолчанию считаем админом для MVP
  });

  @override
  State<ChatDetailsBottomSheet> createState() => _ChatDetailsBottomSheetState();
}

class _ChatDetailsBottomSheetState extends State<ChatDetailsBottomSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isEditing = false;
  List<UserModel> _participants = [];
  bool _isLoadingParticipants = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.chat.name);
    _descriptionController = TextEditingController(text: 'Let\'s do it'); // Default description as in screenshot
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    try {
      final userRepository = ServiceLocator().userRepository;
      final List<UserModel> loaded = [];
      for (final id in widget.chat.participantIds) {
        try {
          // В реальном приложении лучше загружать всех участников одним запросом
          final user = await userRepository.getUserById(id);
          loaded.add(user);
        } catch (e) {
          debugPrint('Error loading user $id: $e');
        }
      }
      if (mounted) {
        setState(() {
          _participants = loaded;
          _isLoadingParticipants = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading participants: $e');
      if (mounted) setState(() => _isLoadingParticipants = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildMainCard(),
                  const SizedBox(height: 16),
                  _buildMembersCard(),
                ],
              ),
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
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
          Text(
            widget.chat.name,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (widget.isAdmin)
            GestureDetector(
              onTap: () {
                if (_isEditing) {
                  // Save changes logic here
                }
                setState(() => _isEditing = !_isEditing);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Icon(_isEditing ? Icons.check : Icons.edit_outlined, color: Colors.white, size: 20),
              ),
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.chat.name.isNotEmpty ? widget.chat.name[0].toUpperCase() : 'G',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              if (_isEditing)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFF0F1621), shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
          if (_isEditing)
             Padding(
               padding: const EdgeInsets.only(top: 8),
               child: Text('Set a new photo', style: TextStyle(color: Colors.blue.shade300, fontSize: 14)),
             ),
          const SizedBox(height: 16),
          if (_isEditing) ...[
            _buildEditField('GROUP NAME', _nameController),
            const SizedBox(height: 16),
            _buildEditField('GROUP DESCRIPTION', _descriptionController),
          ] else ...[
            Text(
              widget.chat.name,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.chat.participantIds.length} members',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Group description', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                const SizedBox(height: 8),
                Text(_descriptionController.text, style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ],
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

  Widget _buildMembersCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing)
            ListTile(
              leading: const Icon(Icons.add, color: Colors.white),
              title: const Text('Add member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              onTap: () {},
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '${widget.chat.participantIds.length} members',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          const Divider(color: Colors.white10, height: 1),
          if (_isLoadingParticipants)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _participants.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
              itemBuilder: (context, index) {
                final user = _participants[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.avatarUrl != null ? NetworkImage('${AppConfig.apiBaseUrl.replaceAll('/api', '')}${user.avatarUrl}') : null,
                    child: user.avatarUrl == null ? Text(user.name?[0] ?? 'U') : null,
                  ),
                  title: Text(user.name ?? 'User', style: const TextStyle(color: Colors.white)),
                  trailing: widget.isAdmin && _isEditing
                      ? IconButton(icon: const Icon(Icons.remove, color: Colors.white54), onPressed: () {})
                      : (index == 0 ? Text('Admin', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)) : null),
                );
              },
            ),
        ],
      ),
    );
  }
}






