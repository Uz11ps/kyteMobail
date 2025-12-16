import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/chat/chat_bloc.dart';
import '../../../core/routing/app_router.dart';

class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _participantEmailController = TextEditingController();
  final List<String> _participantIds = [];

  @override
  void dispose() {
    _nameController.dispose();
    _participantEmailController.dispose();
    super.dispose();
  }

  void _addParticipant() {
    final email = _participantEmailController.text.trim();
    if (email.isNotEmpty && !_participantIds.contains(email)) {
      setState(() {
        _participantIds.add(email);
        _participantEmailController.clear();
      });
    }
  }

  void _removeParticipant(String id) {
    setState(() {
      _participantIds.remove(id);
    });
  }

  void _createGroup() {
    if (!_formKey.currentState!.validate()) return;

    context.read<ChatBloc>().add(
          GroupCreateRequested(
            name: _nameController.text,
            participantIds: _participantIds,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
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
        appBar: AppBar(title: const Text('Создать группу')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Название группы',
                      hintText: 'Моя группа',
                      prefixIcon: Icon(Icons.group),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите название группы';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Участники (опционально)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _participantEmailController,
                          decoration: const InputDecoration(
                            labelText: 'Email участника',
                            hintText: 'user@example.com',
                            prefixIcon: Icon(Icons.person_add),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onFieldSubmitted: (_) => _addParticipant(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addParticipant,
                        tooltip: 'Добавить участника',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_participantIds.isNotEmpty) ...[
                    ..._participantIds.map(
                      (id) => Card(
                        child: ListTile(
                          title: Text(id),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _removeParticipant(id),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      final isLoading = state is GroupCreateLoading;
                      return ElevatedButton(
                        onPressed: isLoading ? null : _createGroup,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Создать группу'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

