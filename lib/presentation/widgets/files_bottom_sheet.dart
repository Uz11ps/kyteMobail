import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../../data/models/message_model.dart';
import '../../core/di/service_locator.dart';
import '../screens/chats/chat_screen.dart';

class FilesBottomSheet extends StatefulWidget {
  final String chatId;
  final String chatName;
  final int fileCount;

  const FilesBottomSheet({
    super.key,
    required this.chatId,
    required this.chatName,
    this.fileCount = 0,
  });

  @override
  State<FilesBottomSheet> createState() => _FilesBottomSheetState();
}

class _FilesBottomSheetState extends State<FilesBottomSheet> {
  int _selectedTab = 0; // 0: Files, 1: Media
  List<MessageModel> _files = [];
  List<MessageModel> _media = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      // Загружаем все сообщения чата и фильтруем их по типу
      final messages = await ServiceLocator().chatRepository.getMessages(widget.chatId, limit: 1000);
      
      setState(() {
        _files = messages.where((m) => m.isFileMessage).toList();
        _media = messages.where((m) => m.isImageMessage).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading files/media: $e');
      setState(() => _isLoading = false);
    }
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
          // Drag handle
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
          // Custom App Bar (Title and Tabs)
          _buildHeader(context),
          const SizedBox(height: 16),
          // Search/Tabs Bar (Copy from navigation style)
          _buildNavBar(context),
          const SizedBox(height: 24),
          // Tab Switcher (104 files | 582 media)
          _buildTabSwitcher(),
          const SizedBox(height: 16),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 0
                    ? _buildFilesList()
                    : _buildMediaGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.chatName,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  '4 members',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF1A2332),
            child: Text('MVP', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.chat_bubble_outline, color: Colors.white54, size: 18),
            const SizedBox(width: 8),
            const Text('Chat', style: TextStyle(color: Colors.white54)),
            const Spacer(),
            const _HeaderTabIcon(icon: Icons.calendar_today, isActive: false),
            const _HeaderTabIcon(icon: Icons.copy_outlined, isActive: true),
            const _HeaderTabIcon(icon: Icons.search, isActive: false),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _TabButton(
            label: '${_files.length} files',
            isSelected: _selectedTab == 0,
            onTap: () => setState(() => _selectedTab = 0),
          ),
          const SizedBox(width: 16),
          _TabButton(
            label: '${_media.length} media',
            isSelected: _selectedTab == 1,
            onTap: () => setState(() => _selectedTab = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList() {
    if (_files.isEmpty) {
      return const Center(child: Text('No files found', style: TextStyle(color: Colors.white54)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _files.length,
      separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
      itemBuilder: (context, index) {
        final file = _files[index];
        return _FileListItem(message: file);
      },
    );
  }

  Widget _buildMediaGrid() {
    if (_media.isEmpty) {
      return const Center(child: Text('No media found', style: TextStyle(color: Colors.white54)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: _media.length,
      itemBuilder: (context, index) {
        final item = _media[index];
        return GestureDetector(
          onTap: () {
            // Open full screen preview
          },
          child: Image.network(
            item.fileUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.white.withOpacity(0.05),
              child: const Icon(Icons.broken_image, color: Colors.white24),
            ),
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3E4752) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _FileListItem extends StatelessWidget {
  final MessageModel message;

  const _FileListItem({required this.message});

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(message.createdAt);
    final dateStr = DateFormat('dd.MM.yyyy').format(message.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _SmallFileIcon(fileName: message.fileName ?? 'file'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.fileName ?? 'Unnamed file',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(_formatFileSize(message.fileSize), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 8),
                    Text(timeStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 8),
                    Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallFileIcon extends StatelessWidget {
  final String fileName;

  const _SmallFileIcon({required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF425671).withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.insert_drive_file_outlined, color: Colors.white, size: 20),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: const BoxDecoration(color: Color(0xFF0F1621), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_downward, color: Colors.white, size: 12),
          ),
        ),
      ],
    );
  }
}

class _HeaderTabIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;

  const _HeaderTabIcon({required this.icon, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 36,
      decoration: isActive
          ? BoxDecoration(
              color: const Color(0xFF3E4752),
              borderRadius: BorderRadius.circular(18),
            )
          : null,
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}






