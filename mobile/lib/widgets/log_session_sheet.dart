import 'package:flutter/material.dart';

import '../theme.dart';
import 'primary_button.dart';

/// Shows the "log a past session" dialog, centered on screen. Returns the
/// chosen task + minutes, or null if dismissed.
Future<({String task, int minutes})?> showLogSessionSheet(BuildContext context) {
  return showDialog<({String task, int minutes})>(
    context: context,
    builder: (_) => const _LogSessionSheet(),
  );
}

class _LogSessionSheet extends StatefulWidget {
  const _LogSessionSheet();

  @override
  State<_LogSessionSheet> createState() => _LogSessionSheetState();
}

class _LogSessionSheetState extends State<_LogSessionSheet> {
  final _taskController = TextEditingController();
  int _minutes = 25;
  static const _choices = [15, 25, 50];

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Log a past session',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 16),
          TextField(
            controller: _taskController,
            decoration: const InputDecoration(
              hintText: 'What did you work on? (optional)',
              prefixIcon: Icon(Icons.edit_note),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Duration', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 8),
          Row(
            children: _choices.map((m) {
              final selected = m == _minutes;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text('$m min'),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: AppColors.accent,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _minutes = m),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Save session',
            onPressed: () => Navigator.of(context).pop(
              (task: _taskController.text.trim(), minutes: _minutes),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
