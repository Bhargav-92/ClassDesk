// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/database/local_database.dart';
import 'fee_format.dart';

class RecordForm extends StatefulWidget {
  const RecordForm({
    super.key,
    required this.title,
    required this.fields,
    required this.students,
    required this.validate,
    required this.lockStudent,
    required this.paymentLimit,
    this.feeTotal,
    this.recordedPaid,
  });
  final String title;
  final List<(String, String, String)> fields;
  final List<LocalRow> students;
  final String? Function(Map<String, String>) validate;
  final bool lockStudent;
  final int? paymentLimit;
  final int? feeTotal;
  final int? recordedPaid;

  @override
  State<RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<RecordForm> {
  late final _inputs = {
    for (final (key, _, value) in widget.fields)
      key: TextEditingController(text: value),
  };
  String? _error;

  @override
  void dispose() {
    for (final controller in _inputs.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final values = _inputs.map(
      (key, controller) => MapEntry(key, controller.text.trim()),
    );
    final error = widget.validate(values);
    if (error != null) {
      setState(() => _error = error);
    } else {
      Navigator.pop(context, values);
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final first = DateTime(now.year - 20);
    final last = DateTime(now.year + 20, 12, 31);
    final value = DateTime.tryParse(controller.text) ?? now;
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: SizedBox(
          height: 340,
          child: CalendarDatePicker(
            initialDate: value.isBefore(first) || value.isAfter(last)
                ? now
                : value,
            firstDate: first,
            lastDate: last,
            onDateChanged: (date) => Navigator.pop(sheet, date),
          ),
        ),
      ),
    );
    if (mounted && picked != null) {
      setState(() => controller.text = dateKey(picked));
    }
  }

  Widget _field(String key, String label) {
    final input = _inputs[key]!;
    if (key == 'mode' || key == 'student_id' || key == 'homework_student_id') {
      final options = key == 'mode'
          ? {'cash': 'Cash', 'upi': 'UPI'}
          : {
              if (key == 'homework_student_id') '': 'Entire batch',
              for (final row in widget.students)
                row['id']! as String: row['name']! as String,
            };
      return DropdownButtonFormField<String>(
        initialValue: options.containsKey(input.text) ? input.text : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final item in options.entries)
            DropdownMenuItem(value: item.key, child: Text(item.value)),
        ],
        onChanged: widget.lockStudent && key == 'student_id'
            ? null
            : (value) {
                if (value == null) return;
                input.text = value;
                if (key == 'homework_student_id' && value.isNotEmpty) {
                  final student = widget.students.firstWhere(
                    (row) => row['id'] == value,
                  );
                  _inputs['batch']!.text = student['batch']! as String;
                }
              },
      );
    }
    final isDate = key.endsWith('_date') || key == 'paid_on';
    return TextField(
      controller: input,
      minLines: key == 'description' ? 3 : 1,
      maxLines: key == 'description' ? 6 : 1,
      keyboardType: key == 'amount'
          ? const TextInputType.numberWithOptions(decimal: true)
          : key == 'parent_whatsapp'
          ? TextInputType.phone
          : null,
      onChanged: key == 'amount' && widget.paymentLimit != null
          ? (_) => setState(() {})
          : null,
      readOnly: isDate,
      onTap: isDate ? () => _pickDate(input) : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: isDate
            ? IconButton(
                tooltip: key == 'promised_date' && input.text.isNotEmpty
                    ? 'Clear promised date'
                    : 'Select date',
                onPressed: key == 'promised_date' && input.text.isNotEmpty
                    ? () => setState(input.clear)
                    : () => _pickDate(input),
                icon: Icon(
                  key == 'promised_date' && input.text.isNotEmpty
                      ? LucideIcons.x
                      : LucideIcons.calendar,
                ),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining =
        (widget.paymentLimit ?? 0) -
        (parseRupees(_inputs['amount']?.text ?? '') ?? 0);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (widget.feeTotal case final total?) ...[
              Text('Fee: ${rupees(total)}'),
              Text('Already paid: ${rupees(widget.recordedPaid ?? 0)}'),
              Text(
                'Remaining after this payment: ${rupees(remaining.clamp(0, total).toInt())}',
              ),
              const SizedBox(height: 16),
            ],
            for (final (key, label, _) in widget.fields)
              if (key != 'promised_date' || remaining > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _field(
                    key,
                    key == 'promised_date'
                        ? 'When will the remaining ${rupees(remaining)} be paid?'
                        : label,
                  ),
                ),
            if (_error case final error?) ...[
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
            ],
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
