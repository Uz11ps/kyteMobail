import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import '../../bloc/chat/chat_bloc.dart';
import '../../../core/routing/app_router.dart';
import '../../../data/models/user_model.dart';
import '../../../core/config/app_config.dart';
import 'add_member_view.dart';

class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<UserModel> _selectedUsers = [];
  final List<String> _invitedIdentifiers = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addMember() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddMemberView(
          onMemberAdded: (user, identifier) {
            setState(() {
              if (user != null) {
                if (!_selectedUsers.any((u) => u.id == user.id)) {
                  _selectedUsers.add(user);
                }
              } else if (identifier != null) {
                if (!_invitedIdentifiers.contains(identifier)) {
                  _invitedIdentifiers.add(identifier);
                }
              }
            });
          },
        ),
      ),
    );
  }

  void _createGroup() {
    if (!_formKey.currentState!.validate()) return;

    final participantIds = _selectedUsers.map((u) => u.id).toList();
    // In a real app, we'd also send invitedIdentifiers to the backend
    // to handle auto-join upon registration.
    
    context.read<ChatBloc>().add(
          GroupCreateRequested(
            name: _nameController.text,
            participantIds: participantIds,
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _nameController.text.trim().isNotEmpty;

    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is GroupCreated) {
          Navigator.of(context).pushReplacementNamed(
            AppRouter.chat,
            arguments: {
              'chatId': state.group.id,
              'chatName': state.group.name,
            },
          );
        } else if (state is ChatError) {
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
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'New project',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          actions: [
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                final isLoading = state is GroupCreateLoading;
                return IconButton(
                  onPressed: (isValid && !isLoading) ? _createGroup : null,
                  icon: Icon(
                    Icons.check_circle,
                    color: (isValid && !isLoading) ? Colors.white : Colors.white.withOpacity(0.3),
                    size: 28,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Group Info Container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                    child: Column(
                      children: [
                        _buildInputField(
                          label: 'GROUP NAME',
                          controller: _nameController,
                          hint: 'Kyte.me MVP',
                        ),
                        Divider(color: Colors.white.withOpacity(0.1), height: 1, indent: 24, endIndent: 24),
                        _buildInputField(
                          label: 'GROUP DESCRIPTION',
                          controller: _descriptionController,
                          hint: 'Let\'s do it',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Members Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                    child: Column(
                      children: [
                        // Add Member Button
                        InkWell(
                          onTap: _addMember,
                          borderRadius: const BorderRadius.all(Radius.circular(24)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Add member',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_selectedUsers.isNotEmpty || _invitedIdentifiers.isNotEmpty) ...[
                          Divider(color: Colors.white.withOpacity(0.1), height: 1, indent: 24, endIndent: 24),
                          // List of members
                          ..._selectedUsers.map((user) => _buildMemberTile(
                                name: user.name ?? 'No Name',
                                avatarUrl: user.avatarUrl,
                                onRemove: () => setState(() => _selectedUsers.remove(user)),
                              )),
                          ..._invitedIdentifiers.map((id) => _buildMemberTile(
                                name: id,
                                isInvited: true,
                                onRemove: () => setState(() => _invitedIdentifiers.remove(id)),
                              )),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({required String label, required TextEditingController controller, required String hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile({required String name, String? avatarUrl, bool isInvited = false, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.1),
            backgroundImage: avatarUrl != null ? NetworkImage('${AppConfig.apiBaseUrl.replaceAll('/api', '')}$avatarUrl') : null,
            child: avatarUrl == null ? Icon(isInvited ? Icons.person_outline : Icons.person, color: Colors.white, size: 20) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                if (isInvited) ...[
                  const SizedBox(width: 8),
                  Text(
                    'invited',
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.remove, color: Colors.white.withOpacity(0.3)),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
