import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../../data/models/meeting_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/config/app_config.dart';

class EventCreateEditScreen extends StatefulWidget {
  final String chatId;
  final MeetingModel? meeting;
  final List<UserModel> groupMembers;

  const EventCreateEditScreen({
    super.key,
    required this.chatId,
    this.meeting,
    required this.groupMembers,
  });

  @override
  State<EventCreateEditScreen> createState() => _EventCreateEditScreenState();
}

class _EventCreateEditScreenState extends State<EventCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _infoController;
  late final TextEditingController _linkController;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  final List<String> _invitedMemberIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meeting?.summary ?? '');
    _infoController = TextEditingController(text: widget.meeting?.description ?? '');
    _linkController = TextEditingController(text: widget.meeting?.meetUrl ?? '');
    _selectedDate = widget.meeting?.start ?? DateTime.now();
    _startTime = TimeOfDay.fromDateTime(widget.meeting?.start ?? DateTime.now());
    _endTime = TimeOfDay.fromDateTime(widget.meeting?.end ?? DateTime.now().add(const Duration(hours: 1)));
    
    if (widget.meeting != null) {
      // In a real app, match attendees emails/names to group member IDs
      // For now, initializing with all for demo
      _invitedMemberIds.addAll(widget.groupMembers.map((m) => m.id));
    } else {
      _invitedMemberIds.addAll(widget.groupMembers.map((m) => m.id));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _infoController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final start = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final end = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      if (widget.meeting == null) {
        await ServiceLocator().meetingRepository.createMeeting(
          chatId: widget.chatId,
          // title: _nameController.text,
          // description: _infoController.text,
          // link: _linkController.text,
          // start: start,
          // end: end,
          // attendeeIds: _invitedMemberIds,
        );
      } else {
        // Handle update
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
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
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Kyte.me MVP', // As per mockup
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _handleSave,
            icon: Icon(
              Icons.check_circle,
              color: _isLoading ? Colors.white.withOpacity(0.3) : Colors.white,
              size: 28,
            ),
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
              children: [
                const SizedBox(height: 40),
                // Main Fields Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                  ),
                  child: Column(
                    children: [
                      _buildInputField(label: 'EVENT NAME', controller: _nameController),
                      _buildDivider(),
                      _buildClickableField(
                        label: 'DATE',
                        value: DateFormat('EEEE - MMM d, yyyy').format(_selectedDate),
                        onTap: _selectDate,
                      ),
                      _buildDivider(),
                      Row(
                        children: [
                          Expanded(
                            child: _buildClickableField(
                              label: 'START TIME',
                              value: _startTime.format(context),
                              onTap: () => _selectTime(true),
                            ),
                          ),
                          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                          Expanded(
                            child: _buildClickableField(
                              label: 'END TIME',
                              value: _endTime.format(context),
                              onTap: () => _selectTime(false),
                            ),
                          ),
                        ],
                      ),
                      _buildDivider(),
                      _buildInputField(label: 'EVENT INFO', controller: _infoController),
                      _buildDivider(),
                      _buildInputField(label: 'LINK', controller: _linkController),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Invite Section
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
                        child: Text(
                          'Who to invite',
                          style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      ...widget.groupMembers.map((member) => _buildInviteTile(member)),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({required String label, required TextEditingController controller}) {
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
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableField({required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2),
            ),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Divider(color: Colors.white.withOpacity(0.1), height: 1, indent: 24, endIndent: 24);

  Widget _buildInviteTile(UserModel user) {
    final isSelected = _invitedMemberIds.contains(user.id);
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _invitedMemberIds.remove(user.id);
          } else {
            _invitedMemberIds.add(user.id);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withOpacity(0.1),
              backgroundImage: user.avatarUrl != null ? NetworkImage('${AppConfig.apiBaseUrl.replaceAll('/api', '')}${user.avatarUrl}') : null,
              child: user.avatarUrl == null ? Text(user.name?[0] ?? 'U', style: const TextStyle(fontSize: 14)) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user.name ?? 'No Name',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

