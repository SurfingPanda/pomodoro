import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/skeleton.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  final _tasks = TaskService();

  bool _loading = true;
  String? _error;
  List<Task> _items = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _error = null);
    try {
      final list = await _tasks.list();
      if (mounted) setState(() => _items = list);
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't load tasks.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final title = await _showAddSheet();
    if (title == null || title.isEmpty) return;
    try {
      await _tasks.create(title);
      await _refresh();
    } catch (_) {
      _toast('Failed to add task.');
    }
  }

  Future<void> _toggle(Task t) async {
    // optimistic
    setState(() {
      final i = _items.indexOf(t);
      _items[i] = Task(id: t.id, title: t.title, isDone: !t.isDone);
    });
    try {
      await _tasks.setDone(t.id, !t.isDone);
      await _refresh();
    } catch (_) {
      await _refresh();
    }
  }

  Future<void> _delete(Task t) async {
    setState(() => _items.remove(t));
    try {
      await _tasks.delete(t.id);
    } catch (_) {
      await _refresh();
    }
  }

  void _toast(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<String?> _showAddSheet() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('New task',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
              decoration: const InputDecoration(
                hintText: 'What needs doing?',
                prefixIcon: Icon(Icons.check_circle_outline),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Add task',
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            ),
            ],
          ),
        ),
      ),
    );
  }

  int get _openCount => _items.where((t) => !t.isDone).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        titleSpacing: 20,
        title: const Text('Tasks', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
      ),
      body: AppBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: _loading && _items.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    children: const [
                      Skeleton(width: 120, height: 14, radius: 7),
                      SizedBox(height: 16),
                      SkeletonList(count: 6, height: 56),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    children: [
                      if (_error != null)
                        _infoCard(_error!, Icons.cloud_off)
                      else if (_items.isEmpty)
                        _infoCard('No tasks yet. Add one to plan your focus.', Icons.checklist_rounded)
                      else ...[
                        Text('$_openCount open · ${_items.length - _openCount} done',
                            style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                        const SizedBox(height: 12),
                        ..._items.map(_tile),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _tile(Task t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              t.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: t.isDone ? AppColors.week : AppColors.muted,
            ),
            onPressed: () => _toggle(t),
          ),
          Expanded(
            child: Text(
              t.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: t.isDone ? AppColors.muted : AppColors.ink,
                decoration: t.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
            onPressed: () => _delete(t),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.muted),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.muted))),
        ],
      ),
    );
  }
}
