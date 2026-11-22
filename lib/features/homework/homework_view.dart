// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/database/local_database.dart';
import '../../core/database/local_schema.dart';
import '../messaging/whatsapp_queue.dart';
import '../workspace/fee_format.dart';
import '../workspace/record_form.dart';

String formatHomeworkMessage(LocalRow homework, MaterialLocalizations dates) {
  final due = dates.formatFullDate(
    DateTime.parse(homework['due_date']! as String),
  );
  final assigned = dates.formatFullDate(
    DateTime.fromMicrosecondsSinceEpoch(homework['created_at']! as int),
  );
  return '*${homework['batch']} - Homework*\n'
      '*Date:* $assigned\n'
      '*Subject:* ${homework['subject']}\n'
      '*Topic:* ${homework['title']}\n'
      '*Task:* ${homework['description']}\n'
      '*Submit by:* $due';
}

class HomeworkView extends StatefulWidget {
  const HomeworkView({
    super.key,
    required this.database,
    required this.students,
    required this.leftHanded,
    required this.onChanged,
  });
  final LocalDatabase database;
  final List<LocalRow> students;
  final bool leftHanded;
  final VoidCallback onChanged;

  @override
  State<HomeworkView> createState() => _HomeworkViewState();
}

class _HomeworkViewState extends State<HomeworkView> {
  late Future<List<LocalRow>> _homework;
  bool _saving = false;
  LocalRepository get _repository =>
      widget.database.repository(LocalTable.homework);

  @override
  void initState() {
    super.initState();
    _homework = _repository.list();
  }

  void _reload() => setState(() => _homework = _repository.list());

  Future<void> _edit([LocalRow? row]) async {
    final values = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RecordForm(
        title: row == null ? 'Add homework' : 'Edit homework',
        fields: [
          (
            'batch',
            'Class or batch',
            row?['batch'] as String? ??
                (widget.students.firstOrNull?['batch'] as String? ?? ''),
          ),
          (
            'homework_student_id',
            'Assign to',
            row?['student_id'] as String? ?? '',
          ),
          ('subject', 'Subject', row?['subject'] as String? ?? ''),
          ('title', 'Topic', row?['title'] as String? ?? ''),
          ('description', 'Task details', row?['description'] as String? ?? ''),
          (
            'due_date',
            'Submit by',
            row?['due_date'] as String? ?? dateKey(DateTime.now()),
          ),
        ],
        students: widget.students,
        lockStudent: false,
        paymentLimit: null,
        validate: (values) =>
            values.entries.any(
              (entry) =>
                  entry.key != 'homework_student_id' && entry.value.isEmpty,
            )
            ? 'Enter the batch, subject, topic, task and due date.'
            : null,
      ),
    );
    if (values == null || !mounted || _saving) return;
    final batch = widget.students
        .map((student) => student['batch']! as String)
        .where((name) => name.toLowerCase() == values['batch']!.toLowerCase())
        .firstOrNull;
    if (batch != null) values['batch'] = batch;
    final selectedId = values.remove('homework_student_id');
    final target = widget.students
        .where((student) => student['id'] == selectedId)
        .firstOrNull;
    if (selectedId != null && selectedId.isNotEmpty && target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose an active student or an entire batch.'),
        ),
      );
      return;
    }
    final record = <String, Object?>{
      ...values,
      'student_id': target?['id'],
      if (target != null) 'batch': target['batch'],
    };
    setState(() => _saving = true);
    try {
      if (row == null) {
        await _repository.create(record);
      } else {
        await _repository.update(row['id']! as String, record);
      }
      if (mounted) {
        _reload();
        widget.onChanged();
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save homework. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _queue(LocalRow row) async {
    final recipients =
        widget.students
            .where(
              (student) => row['student_id'] != null
                  ? student['id'] == row['student_id']
                  : student['batch'] == row['batch'],
            )
            .toList()
          ..sort(
            (a, b) => (a['name']! as String).compareTo(b['name']! as String),
          );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WhatsAppQueue(
          database: widget.database,
          recipients: recipients,
          message: formatHomeworkMessage(
            row,
            MaterialLocalizations.of(context),
          ),
          homeworkId: row['id']! as String,
        ),
      ),
    );
    if (mounted) widget.onChanged();
  }

  String _audience(LocalRow row) {
    final id = row['student_id'];
    if (id == null) return row['batch']! as String;
    final student = widget.students
        .where((student) => student['id'] == id)
        .firstOrNull;
    return student?['name'] as String? ?? 'Student unavailable';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Homework', style: theme.textTheme.headlineLarge),
        ),
        const SizedBox(height: 8),
        const Text('Assign work by batch and share it with parents.'),
        const SizedBox(height: 16),
        Align(
          alignment: widget.leftHanded
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _saving ? null : () => _edit(),
            icon: const Icon(LucideIcons.plus),
            label: const Text('Add homework'),
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<LocalRow>>(
          future: _homework,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Loading homework',
                ),
              );
            }
            if (snapshot.hasError) {
              return OutlinedButton(
                onPressed: _reload,
                child: const Text('Retry loading homework'),
              );
            }
            final rows = snapshot.data!;
            if (rows.isEmpty) return const Text('No homework yet.');
            return Column(
              children: [
                for (final row in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          row['title']! as String,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_audience(row)} · ${row['subject']} · Due ${row['due_date']}',
                        ),
                        const SizedBox(height: 8),
                        Text(row['description']! as String),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _queue(row),
                              icon: const Icon(LucideIcons.messageCircle),
                              label: const Text('Send to parents'),
                            ),
                            TextButton(
                              onPressed: _saving ? null : () => _edit(row),
                              child: const Text('Edit'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
