import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/di/service_locator.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../core/config/app_config.dart';

class AddMemberView extends StatefulWidget {
  final Function(UserModel?, String?) onMemberAdded;

  const AddMemberView({super.key, required this.onMemberAdded});

  @override
  State<AddMemberView> createState() => _AddMemberViewState();
}

class _AddMemberViewState extends State<AddMemberView> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  bool _hasSearched = false;
  UserModel? _foundUser;
  String? _identifier;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch() async {
    final val = _searchController.text.trim();
    if (val.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = false;
      _identifier = val;
    });

    try {
      final userRepository = getIt<UserRepository>();
      final user = await userRepository.findUserByIdentifier(val);
      
      setState(() {
        _foundUser = user;
        _isSearching = false;
        _hasSearched = true;
      });
    } catch (e) {
      setState(() {
        _foundUser = null;
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161B22),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add member',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              if (!_hasSearched || _isSearching) ...[
                const SizedBox(height: 40),
                const Text(
                  'Search by phone number\nor email address',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, height: 1.2),
                ),
                const SizedBox(height: 40),
                Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.white.withOpacity(0.5), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'search users',
                            hintStyle: TextStyle(color: Colors.white24),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _searchController.text.trim().isEmpty || _isSearching ? null : _handleSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _searchController.text.trim().isNotEmpty ? Colors.white : Colors.white.withOpacity(0.2),
                      foregroundColor: const Color(0xFF161B22),
                      disabledBackgroundColor: Colors.white.withOpacity(0.2),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    ),
                    child: _isSearching
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF161B22)))
                        : Text(
                            'Search',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _searchController.text.trim().isNotEmpty ? const Color(0xFF161B22) : Colors.white.withOpacity(0.3),
                            ),
                          ),
                  ),
                ),
              ] else if (_foundUser != null) ...[
                const SizedBox(height: 40),
                _buildUserResult(_foundUser!),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onMemberAdded(_foundUser, null);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF161B22),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    ),
                    child: const Text('Add as a member', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'The user with the ${_identifier?.contains('@') == true ? 'email' : 'phone number'}\n"$_identifier" is not registered',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Invite user to join Kyte. The user will automatically join the group when register.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onMemberAdded(null, _identifier);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF161B22),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    ),
                    child: const Text('Send the invitation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserResult(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
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
          _buildInfoField('Phone number', user.phone ?? 'Not provided', isVerified: user.phone != null),
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
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            if (isVerified) const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ],
    );
  }
}

