import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../widgets/ai_chat_popup.dart';
import '../../core/di/service_locator.dart';
import '../../data/models/meeting_model.dart';
import '../../data/models/user_model.dart';
import '../screens/groups/event_create_edit_screen.dart';

class CalendarBottomSheet extends StatefulWidget {
  final String chatId;
  final String chatName;
  final int chatCount;
  final int meetingsCount;
  final int fileCount;

  const CalendarBottomSheet({
    super.key,
    required this.chatId,
    required this.chatName,
    this.chatCount = 12,
    this.meetingsCount = 12,
    this.fileCount = 0,
  });

  @override
  State<CalendarBottomSheet> createState() => _CalendarBottomSheetState();
}

class _CalendarBottomSheetState extends State<CalendarBottomSheet> {
  bool _showEventsList = false;
  MeetingModel? _selectedMeeting;
  List<MeetingModel> _meetings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);
      
      final meetings = await ServiceLocator().meetingRepository.getCalendarEvents(
        chatId: widget.chatId,
      );
      
      if (!mounted) return;
      setState(() {
        _meetings = meetings;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading meetings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // В демо режиме если бэкенд не вернул данные, показываем пример
          if (_meetings.isEmpty) {
            _meetings = [
              MeetingModel(
                id: 'm1',
                summary: 'Обсуждение обновлений интерфейса для MVP',
                description: "We'll discuss important, long-awaited UI updates",
                start: DateTime.now().add(const Duration(hours: 2)),
                end: DateTime.now().add(const Duration(hours: 3)),
                meetUrl: 'https://meet.google.com/kyte-mvp-demo',
                attendees: [
                  AttendeeModel(email: 'you@kyte.me', displayName: 'you'),
                  AttendeeModel(email: 'dmitry@kyte.me', displayName: 'Dmitry Bilyk'),
                ],
              ),
            ];
          }
        });
      }
    }
  }

  Future<void> _createMeeting() async {
    // В реальном приложении получаем список участников группы через репозиторий
    // Для демо используем текущих из selected meeting или заглушку
    final groupMembers = [
      UserModel(id: 'u1', name: 'you', email: 'you@kyte.me'),
      UserModel(id: 'u2', name: 'Dmitry Bilyk', email: 'dmitry@kyte.me'),
      UserModel(id: 'u3', name: 'Jason Statham', email: 'jason@kyte.me'),
      UserModel(id: 'u4', name: 'Mick Jagger', email: 'mick@kyte.me'),
    ];

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventCreateEditScreen(
          chatId: widget.chatId,
          groupMembers: groupMembers,
        ),
      ),
    );

    if (result == true) {
      _loadMeetings();
    }
  }

  Future<void> _editMeeting(MeetingModel meeting) async {
    final groupMembers = [
      UserModel(id: 'u1', name: 'you', email: 'you@kyte.me'),
      UserModel(id: 'u2', name: 'Dmitry Bilyk', email: 'dmitry@kyte.me'),
      UserModel(id: 'u3', name: 'Jason Statham', email: 'jason@kyte.me'),
      UserModel(id: 'u4', name: 'Mick Jagger', email: 'mick@kyte.me'),
    ];

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventCreateEditScreen(
          chatId: widget.chatId,
          meeting: meeting,
          groupMembers: groupMembers,
        ),
      ),
    );

    if (result == true) {
      setState(() => _selectedMeeting = null);
      _loadMeetings();
    }
  }

  void _showAIChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AIChatPopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1621),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          if (_selectedMeeting != null)
            _EventDetailView(
              meeting: _selectedMeeting!,
              onBack: () => setState(() => _selectedMeeting = null),
              onEdit: () => _editMeeting(_selectedMeeting!),
            )
          else if (_showEventsList)
            _EventsListView(
              meetings: _meetings,
              isLoading: _isLoading,
              onBack: () => setState(() => _showEventsList = false),
              onEventTap: (meeting) => setState(() => _selectedMeeting = meeting),
            )
          else
            _CalendarMainView(
              chatName: widget.chatName,
              chatCount: widget.chatCount,
              meetingsCount: widget.meetingsCount,
              fileCount: widget.fileCount,
              meetings: _meetings,
              isLoading: _isLoading,
              onToggleList: () => setState(() => _showEventsList = true),
              onCreateMeeting: _createMeeting,
              onShowAIChat: _showAIChat,
            ),
          
          // Drag handle
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarMainView extends StatelessWidget {
  final String chatName;
  final int chatCount;
  final int meetingsCount;
  final int fileCount;
  final List<MeetingModel> meetings;
  final bool isLoading;
  final VoidCallback onToggleList;
  final VoidCallback onCreateMeeting;
  final VoidCallback onShowAIChat;

  const _CalendarMainView({
    required this.chatName,
    required this.chatCount,
    required this.meetingsCount,
    required this.fileCount,
    required this.meetings,
    required this.isLoading,
    required this.onToggleList,
    required this.onCreateMeeting,
    required this.onShowAIChat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Custom App Bar
        Padding(
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
                      chatName,
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
        ),
        const SizedBox(height: 16),
        // Search/Tabs Bar
        Padding(
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
                _TabIcon(icon: Icons.calendar_today, badge: meetingsCount.toString(), isActive: true),
                _TabIcon(icon: Icons.copy_outlined, badge: fileCount > 0 ? fileCount.toString() : null),
                _TabIcon(icon: Icons.search, badge: null),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Day headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => SizedBox(
                      width: 40,
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        // Calendar Content (Scrollable)
        Expanded(
          child: isLoading 
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _MonthSection(
                    month: DateFormat('MMMM yyyy').format(DateTime.now()), 
                    startDay: DateTime(DateTime.now().year, DateTime.now().month, 1).weekday - 1, 
                    daysCount: DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day, 
                    meetings: meetings.where((m) => m.start.month == DateTime.now().month).toList(),
                  ),
                  _MonthSection(
                    month: DateFormat('MMMM yyyy').format(DateTime(DateTime.now().year, DateTime.now().month + 1)), 
                    startDay: DateTime(DateTime.now().year, DateTime.now().month + 1, 1).weekday - 1, 
                    daysCount: DateTime(DateTime.now().year, DateTime.now().month + 2, 0).day, 
                    meetings: meetings.where((m) => m.start.month == (DateTime.now().month % 12 + 1)).toList(),
                  ),
                ],
              ),
        ),
        // Bottom Navigation
        _BottomBar(
          onToggleList: onToggleList,
          onCreateMeeting: onCreateMeeting,
          onShowAIChat: onShowAIChat,
        ),
      ],
    );
  }
}

class _TabIcon extends StatelessWidget {
  final IconData icon;
  final String? badge;
  final bool isActive;

  const _TabIcon({required this.icon, this.badge, this.isActive = false});

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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          if (badge != null)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFF232B36),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthSection extends StatelessWidget {
  final String month;
  final int startDay; // 0 = Mon, 6 = Sun
  final int daysCount;
  final List<MeetingModel> meetings;

  const _MonthSection({
    required this.month,
    required this.startDay,
    required this.daysCount,
    required this.meetings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          month,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Divider(color: Colors.white10),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: startDay + daysCount,
          itemBuilder: (context, index) {
            if (index < startDay) return const SizedBox();
            final day = index - startDay + 1;
            
            final dayMeetings = meetings.where((m) => m.start.day == day).toList();
            final hasEvents = dayMeetings.isNotEmpty;
            final eventCount = dayMeetings.length;
            final now = DateTime.now();
            final isToday = day == now.day && 
                           month.toLowerCase().contains(DateFormat('MMMM').format(now).toLowerCase()) &&
                           month.contains(now.year.toString());

            return GestureDetector(
              onTap: hasEvents ? () {
                // Если нужно, можно сразу открывать первое событие дня
              } : null,
              child: Container(
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFF425671) : const Color(0xFF1A2332),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$day',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    if (hasEvents)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Color(0xFF232B36), shape: BoxShape.circle),
                          child: Text('$eventCount', style: const TextStyle(color: Colors.white, fontSize: 8)),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final VoidCallback onToggleList;
  final VoidCallback onCreateMeeting;
  final VoidCallback onShowAIChat;

  const _BottomBar({
    required this.onToggleList,
    required this.onCreateMeeting,
    required this.onShowAIChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          _BottomButton(icon: Icons.favorite_border, badge: '12', onTap: onShowAIChat),
          const SizedBox(width: 16),
          _BottomButton(icon: Icons.list, isActive: true, onTap: onToggleList),
          const SizedBox(width: 16),
          _BottomButton(icon: Icons.add, onTap: onCreateMeeting),
        ],
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final IconData icon;
  final String? badge;
  final bool isActive;
  final VoidCallback? onTap;

  const _BottomButton({required this.icon, this.badge, this.isActive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF3E4752) : const Color(0xFF1A2332),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            if (badge != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFF425671), shape: BoxShape.circle),
                  child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EventsListView extends StatelessWidget {
  final List<MeetingModel> meetings;
  final bool isLoading;
  final VoidCallback onBack;
  final Function(MeetingModel) onEventTap;

  const _EventsListView({
    required this.meetings,
    required this.isLoading,
    required this.onBack,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (meetings.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 20),
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: onBack,
            ),
            title: const Text('Upcoming Events', style: TextStyle(color: Colors.white, fontSize: 16)),
            centerTitle: true,
          ),
          const Expanded(
            child: Center(
              child: Text('Нет запланированных встреч', style: TextStyle(color: Colors.white54)),
            ),
          ),
        ],
      );
    }

    // Группировка по датам
    final Map<String, List<MeetingModel>> grouped = {};
    for (var m in meetings) {
      final dateStr = DateFormat('EEEE - MMM d, yyyy').format(m.start);
      grouped.putIfAbsent(dateStr, () => []).add(m);
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onBack,
          ),
          title: const Text('Upcoming Events', style: TextStyle(color: Colors.white, fontSize: 16)),
          centerTitle: true,
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final date = grouped.keys.elementAt(index);
              final dateMeetings = grouped[date]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...dateMeetings.map((m) => _EventCard(meeting: m, onTap: () => onEventTap(m))),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final MeetingModel meeting;
  final VoidCallback onTap;

  const _EventCard({required this.meeting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeStr = '${DateFormat('HH:mm').format(meeting.start)} - ${DateFormat('HH:mm').format(meeting.end)}';
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(meeting.summary, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(timeStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${meeting.attendees.length} participants', style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EventDetailView extends StatelessWidget {
  final MeetingModel meeting;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  const _EventDetailView({required this.meeting, required this.onBack, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE - MMM d, yyyy').format(meeting.start);
    final timeStr = '${DateFormat('HH:mm').format(meeting.start)} - ${DateFormat('HH:mm').format(meeting.end)}';
    final duration = meeting.end.difference(meeting.start).inMinutes;

    return Column(
      children: [
        const SizedBox(height: 20),
        AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: onBack,
          ),
          title: Text(meeting.summary, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16)),
          actions: [
            IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.white), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.ios_share, color: Colors.white), onPressed: () {}),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2332),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meeting.summary, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(dateStr, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(timeStr, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('$duration min', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Info', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(meeting.description, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),
                  Text('${meeting.attendees.length} participants', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 16),
                  ...meeting.attendees.map((a) => _ParticipantItem(name: a.displayName ?? a.email)),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),
                  const Text('Link', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (meeting.meetUrl != null)
                    GestureDetector(
                      onTap: () async {
                        final Uri url = Uri.parse(meeting.meetUrl!);
                        // if (await canLaunchUrl(url)) {
                        //   await launchUrl(url);
                        // }
                      },
                      child: Text(
                        meeting.meetUrl!, 
                        style: const TextStyle(
                          color: Color(0xFF64B5F6), 
                          fontSize: 15, 
                          decoration: TextDecoration.underline
                        ),
                      ),
                    )
                  else
                    const Text('Ссылка отсутствует', style: TextStyle(color: Colors.white24)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ParticipantItem extends StatelessWidget {
  final String name;
  final bool isYou;

  const _ParticipantItem({required this.name, this.isYou = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=$name'),
          ),
          const SizedBox(width: 12),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class EventModel {
  final String title;
  final String time;
  final String date;
  final int participantsCount;
  final String? description;
  final String? link;

  EventModel({
    required this.title,
    required this.time,
    required this.date,
    required this.participantsCount,
    this.description,
    this.link,
  });
}

