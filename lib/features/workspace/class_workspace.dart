// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/database/local_database.dart';
import '../../core/database/local_schema.dart';

import '../homework/homework_view.dart';
import '../messaging/whatsapp_queue.dart';
import '../reminders/monthly_fee_reminders.dart';
import '../sync/sync_panel.dart';
import 'fee_format.dart';
import 'record_form.dart';

class ClassWorkspace extends StatefulWidget {
  const ClassWorkspace({
    super.key,
    required this.openDatabase,
    required this.settings,
    required this.leftHanded,
  });

  final Future<LocalDatabase> Function() openDatabase;
  final Widget Function(VoidCallback, Widget?) settings;
  final bool leftHanded;

  @override
  State<ClassWorkspace> createState() => _ClassWorkspaceState();
}

class _ClassWorkspaceState extends State<ClassWorkspace> {
  final _scaffold = GlobalKey<ScaffoldState>();
  final _searchInput = TextEditingController();
  LocalDatabase? _db;
  SyncController? _sync;
  final _monthlyReminders = MonthlyFeeReminders();
  bool _remindersEnabled = false;
  bool _changingReminders = false;
  List<LocalRow> _students = [], _fees = [], _payments = [], _promises = [];
  int _tab = 0;
  int _monthOffset = 0;
  bool _loading = true, _failed = false, _saving = false;
  String _search = '', _batch = '';
  bool _descending = false;

  String get _month {
    final now = DateTime.now();
    return dateKey(
      DateTime(now.year, now.month + _monthOffset),
    ).substring(0, 7);
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchInput.dispose();
    _sync?.dispose();
    final database = _db;
    if (database != null) database.close();
    super.dispose();
  }

  LocalRepository _repo(LocalTable table) => _db!.repository(table);

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      if (_db == null) {
        final database = await widget.openDatabase();
        if (!mounted) {
          await database.close();
          return;
        }
        _db = database;
        _sync = SyncController(database.sync, _refresh);
        await _sync!.initialize();
        if (MonthlyFeeReminders.supported) {
          try {
            _remindersEnabled = await _monthlyReminders.enabled();
          } on Exception {
            _remindersEnabled = false;
          }
        }
        if (!mounted) return;
      }
      final rows = await Future.wait([
        _repo(LocalTable.students).list(),
        _repo(LocalTable.feeRecords).list(),
        _repo(LocalTable.payments).list(),
        _repo(LocalTable.promises).list(),
      ]);
      if (!mounted) return;
      setState(() {
        _students = rows[0];
        _fees = rows[1];
        _payments = rows[2];
        _promises = rows[3];
      });
      if (_remindersEnabled) await _scheduleFeeReminder();
    } on Exception {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _scheduleFeeReminder() async {
    final balance = _fees.fold<int>(0, (total, fee) => total + _balance(fee));
    try {
      await _monthlyReminders.schedule(balance);
    } on Exception {
      if (mounted) _message('Could not schedule the monthly fee reminder.');
    }
  }

  Future<void> _toggleReminders(bool value) async {
    setState(() => _changingReminders = true);
    try {
      final changed = await _monthlyReminders.setEnabled(value);
      if (!mounted) return;
      if (!changed) {
        _message(
          'Allow notifications in Android settings to enable reminders.',
        );
        return;
      }
      setState(() => _remindersEnabled = value);
      if (value) await _scheduleFeeReminder();
    } on Exception {
      if (mounted) {
        _message('Could not change the reminder setting. Try again.');
      }
    } finally {
      if (mounted) setState(() => _changingReminders = false);
    }
  }

  void _message(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), action: action));
  }

  Future<void> _write(Future<void> Function() action, String message) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
      if (!mounted) return;
      await _refresh();
      await _sync?.refreshCount();
      if (mounted && message.isNotEmpty) _message(message);
    } on Exception catch (error) {
      if (mounted) {
        _message(
          error is FormatException
              ? error.message
              : 'Could not save the change. Check the details and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(LocalTable table, LocalRow row) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: ListTile(
          title: const Text('Remove this record?'),
          subtitle: const Text('You can undo the removal.'),
          trailing: TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final id = row['id']! as String;
    await _write(() async {
      if (table == LocalTable.payments) {
        await _db!.setPaymentRemoved(id, removed: true);
      } else if (!await _repo(table).softDelete(id)) {
        return;
      }
      if (!mounted) return;
      _message(
        'Record removed',
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            _write(() async {
              if (table == LocalTable.payments) {
                await _db!.setPaymentRemoved(id, removed: false);
              } else {
                await _repo(table).restore(id);
              }
            }, 'Record restored');
          },
        ),
      );
    }, '');
  }

  List<LocalRow> _paymentsFor(LocalRow fee) =>
      _payments.where((row) => row['fee_record_id'] == fee['id']).toList();

  int _paid(LocalRow fee) => _paymentsFor(
    fee,
  ).fold(0, (sum, row) => sum + (row['amount_paise']! as int));
  int _due(LocalRow fee) => fee['amount_due_paise']! as int;
  int _balance(LocalRow fee) =>
      (_due(fee) - _paid(fee)).clamp(0, _due(fee)).toInt();
  String _name(Object? id) =>
      _students.where((row) => row['id'] == id).firstOrNull?['name']
          as String? ??
      'Student';
  bool _overdue(LocalRow fee) =>
      (fee['due_date']! as String).compareTo(dateKey(DateTime.now())) < 0;

  Future<void> _editStudent([LocalRow? row]) async {
    final values = await _form(
      'Student',
      [
        ('name', 'Student name', row?['name'] as String? ?? ''),
        ('batch', 'Class or batch', row?['batch'] as String? ?? ''),
        ('parent_name', 'Parent name', row?['parent_name'] as String? ?? ''),
        (
          'parent_whatsapp',
          'Parent WhatsApp',
          row?['parent_whatsapp'] as String? ?? '',
        ),
        (
          'amount',
          'Monthly fee (₹)',
          row == null
              ? ''
              : rupees(row['monthly_fee_paise']! as int).substring(1),
        ),
        (
          'joining_date',
          'Joining date',
          row?['joining_date'] as String? ?? dateKey(DateTime.now()),
        ),
        ('notes', 'Notes (optional)', row?['notes'] as String? ?? ''),
      ],
      validate: (values) {
        if ([
          'name',
          'batch',
          'parent_name',
        ].any((key) => values[key]!.isEmpty)) {
          return 'Enter a student name, batch and parent name.';
        }
        if (normalizeWhatsAppNumber(values['parent_whatsapp']!) == null) {
          return 'Enter a valid Indian WhatsApp number.';
        }
        if (parseRupees(values['amount']!) == null) {
          return 'Enter a valid monthly fee.';
        }
        return null;
      },
    );
    if (values == null || !mounted) return;
    final data = <String, Object?>{
      'name': values['name'],
      'batch': values['batch'],
      'parent_name': values['parent_name'],
      'parent_whatsapp': normalizeWhatsAppNumber(values['parent_whatsapp']!),
      'monthly_fee_paise': parseRupees(values['amount']!),
      'joining_date': values['joining_date'],
      'notes': values['notes'],
    };
    await _write(() async {
      final students = _repo(LocalTable.students);
      if (row == null) {
        await students.create(data);
      } else {
        await students.update(row['id']! as String, data);
      }
    }, 'Student saved');
  }

  Future<void> _editFee({LocalRow? existing, LocalRow? student}) async {
    if (_students.isEmpty) {
      await _editStudent();
      return;
    }
    final selected = student ?? _students.first;
    final month = existing?['month'] as String? ?? _month;
    final values = await _form(
      'Monthly fee',
      [
        (
          'student_id',
          'Student',
          (existing?['student_id'] ?? selected['id'])! as String,
        ),
        ('month', 'Fee month (YYYY-MM)', month),
        (
          'amount',
          'Amount due (₹)',
          existing == null ? '' : rupees(_due(existing)).substring(1),
        ),
        (
          'due_date',
          'Due date',
          existing?['due_date'] as String? ?? '$month-10',
        ),
      ],
      lockStudent: existing != null,
      validate: (values) {
        if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(values['month']!)) {
          return 'Use YYYY-MM for the fee month.';
        }
        if ((parseRupees(values['amount']!) ?? -1) <
            (existing == null ? 0 : _paid(existing))) {
          return 'Enter an amount that covers payments already recorded.';
        }
        if (_fees.any(
          (row) =>
              row['student_id'] == values['student_id'] &&
              row['month'] == values['month'] &&
              row['id'] != existing?['id'],
        )) {
          return 'This student already has a fee for that month.';
        }
        return null;
      },
    );
    if (values == null || !mounted) return;
    await _write(() async {
      await _db!.saveFee(
        id: existing?['id'] as String?,
        studentId: values['student_id']!,
        month: values['month']!,
        amount: parseRupees(values['amount']!)!,
        dueDate: values['due_date']!,
      );
    }, 'Monthly fee saved');
  }

  Future<void> _editPayment(LocalRow fee, [LocalRow? payment]) async {
    final max = _balance(fee) + (payment?['amount_paise'] as int? ?? 0);
    final values = await _form(
      'Record payment',
      [
        (
          'amount',
          'Amount received (₹)',
          payment == null
              ? ''
              : rupees(payment['amount_paise']! as int).substring(1),
        ),
        (
          'paid_on',
          'Payment date',
          payment?['paid_on'] as String? ?? dateKey(DateTime.now()),
        ),
        ('mode', 'Payment method', payment?['mode'] as String? ?? 'cash'),
        ('note', 'Note (optional)', payment?['note'] as String? ?? ''),
        ('promised_date', 'Promised date (optional)', ''),
      ],
      paymentLimit: max,
      feeTotal: _due(fee),
      recordedPaid: _paid(fee) - (payment?['amount_paise'] as int? ?? 0),
      validate: (values) {
        final amount = parseRupees(values['amount']!) ?? 0;
        return amount <= 0 || amount > max
            ? 'Enter an amount between ₹0.01 and ${rupees(max)}.'
            : null;
      },
    );
    if (values == null || !mounted) return;
    await _write(() async {
      final amount = parseRupees(values['amount']!)!;
      await _db!.savePayment(
        feeId: fee['id']! as String,
        id: payment?['id'] as String?,
        amount: amount,
        paidOn: values['paid_on']!,
        mode: values['mode']!,
        note: values['note']!,
        promisedDate: values['promised_date']!.isEmpty
            ? null
            : values['promised_date'],
      );
    }, 'Fee received');
  }

  Future<Map<String, String>?> _form(
    String title,
    List<(String, String, String)> fields, {
    required String? Function(Map<String, String>) validate,
    bool lockStudent = false,
    int? paymentLimit,
    int? feeTotal,
    int? recordedPaid,
  }) => showModalBottomSheet<Map<String, String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => RecordForm(
      title: title,
      fields: fields,
      students: _students,
      validate: validate,
      lockStudent: lockStudent,
      paymentLimit: paymentLimit,
      feeTotal: feeTotal,
      recordedPaid: recordedPaid,
    ),
  );

  Future<void> _remindParent(LocalRow fee) async {
    final student = _students
        .where((row) => row['id'] == fee['student_id'])
        .firstOrNull;
    if (student == null) return;
    final promise = _promises
        .where((row) => row['fee_record_id'] == fee['id'])
        .firstOrNull;
    final date = (promise?['promised_date'] ?? fee['due_date'])! as String;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WhatsAppQueue(
          database: _db!,
          recipients: [student],
          feeValues: {
            'parent_name': student['parent_name']! as String,
            'student_name': student['name']! as String,
            'remaining': rupees(_balance(fee)).substring(1),
            'paid': rupees(_paid(fee)).substring(1),
            'date': MaterialLocalizations.of(
              context,
            ).formatFullDate(DateTime.parse(date)),
            'link': '',
          },
        ),
      ),
    );
    if (mounted) await _sync?.refreshCount();
  }

  void _details(LocalRow fee) {
    final payments = _paymentsFor(fee);
    final canPay = _balance(fee) > 0;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => FractionallySizedBox(
        heightFactor: .75,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              _name(fee['student_id']),
              style: Theme.of(sheet).textTheme.headlineSmall,
            ),
            Text('${fee['month']}'),
            Text('Fee: ${rupees(_due(fee))}'),
            Text('Paid: ${rupees(_paid(fee))}'),
            Text('Remaining: ${rupees(_balance(fee))}'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canPay)
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(sheet);
                      _editPayment(fee);
                    },
                    child: const Text('Record payment'),
                  ),
                if (canPay)
                  OutlinedButton.icon(
                    icon: const Icon(LucideIcons.messageCircle),
                    label: const Text('Send WhatsApp reminder'),
                    onPressed: () {
                      Navigator.pop(sheet);
                      _remindParent(fee);
                    },
                  ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(sheet);
                    _editFee(existing: fee);
                  },
                  child: const Text('Edit fee'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(sheet);
                    _delete(LocalTable.feeRecords, fee);
                  },
                  child: const Text('Remove fee'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Payment history',
              style: Theme.of(sheet).textTheme.titleMedium,
            ),
            if (payments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No payments recorded yet.'),
              ),
            for (final payment in payments)
              ListTile(
                title: Text(rupees(payment['amount_paise']! as int)),
                subtitle: Text('${payment['paid_on']} · ${payment['mode']}'),
                onTap: payment['mode'] == 'razorpay'
                    ? null
                    : () {
                        Navigator.pop(sheet);
                        _editPayment(fee, payment);
                      },
                trailing: payment['mode'] == 'razorpay'
                    ? null
                    : IconButton(
                        tooltip: 'Remove payment',
                        icon: const Icon(LucideIcons.trash2),
                        onPressed: () {
                          Navigator.pop(sheet);
                          _delete(LocalTable.payments, payment);
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _heading(String title, String description) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.headlineLarge),
      ),
      const SizedBox(height: 8),
      Text(description),
      const SizedBox(height: 24),
    ],
  );

  void _openSync() {
    final sync = _sync;
    if (sync == null) return;
    _scaffold.currentState?.closeDrawer();
    _scaffold.currentState?.closeEndDrawer();
    showSyncPanel(context, sync);
  }

  Widget _syncSummary(SyncController sync) => ListenableBuilder(
    listenable: sync,
    builder: (context, _) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: sync.running
                ? null
                : sync.credentials == null
                ? _openSync
                : sync.run,
            icon: const Icon(LucideIcons.refreshCw),
            label: Text(
              sync.running
                  ? 'Syncing'
                  : sync.error == null
                  ? 'Sync'
                  : 'Retry sync',
            ),
          ),
          Chip(label: Text('${sync.pending} changes waiting')),
          if (sync.progress case final progress?)
            Text(progress)
          else if (sync.error case final error?)
            Text(error)
          else if (sync.lastSuccess case final time?)
            Text(
              'Synced ${MaterialLocalizations.of(context).formatShortDate(time)} at ${TimeOfDay.fromDateTime(time).format(context)}',
            ),
        ],
      ),
    ),
  );

  Widget _dashboard() {
    final today = dateKey(DateTime.now());
    final currentMonth = today.substring(0, 7);
    final monthly = _fees.where((fee) => fee['month'] == currentMonth);
    final byId = {for (final fee in _fees) fee['id']: fee};
    final collected = _payments
        .where((row) => (row['paid_on']! as String).startsWith(currentMonth))
        .fold(0, (sum, row) => sum + (row['amount_paise']! as int));
    final pending = monthly.fold(
      0,
      (sum, fee) => sum + _balance(fee).clamp(0, _due(fee)).toInt(),
    );
    final dates = <Object?, String>{
      for (final fee in _fees) fee['id']: fee['due_date']! as String,
      for (final promise in _promises.reversed)
        promise['fee_record_id']: promise['promised_date']! as String,
    };
    final due =
        _fees
            .where(
              (fee) =>
                  _balance(fee) > 0 && dates[fee['id']]!.compareTo(today) <= 0,
            )
            .toList()
          ..sort((a, b) => dates[a['id']]!.compareTo(dates[b['id']]!));
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading('Dashboard', 'A quick look at your classes and collections.'),
        if (_sync case final sync?) _syncSummary(sync),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: scheme.onPrimaryContainer),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collected this month',
                  style: TextStyle(color: scheme.onPrimaryContainer),
                ),
                const SizedBox(height: 8),
                Text(
                  rupees(collected),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    Text('${rupees(pending)} pending this month'),
                    Text(
                      '${due.where((fee) => dates[fee['id']] == today).length} due today',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Due today and overdue',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (due.isEmpty) const Text('Nothing due right now.'),
        for (final fee in due) _feeTile(fee, detail: 'Due ${dates[fee['id']]}'),
        if (_promises.any(
          (row) => (row['promised_date']! as String).compareTo(today) > 0,
        )) ...[
          const SizedBox(height: 24),
          Text(
            'Upcoming promises',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (final promise in _promises)
            if ((promise['promised_date']! as String).compareTo(today) > 0 &&
                byId.containsKey(promise['fee_record_id']))
              if (_balance(byId[promise['fee_record_id']]!) > 0)
                _feeTile(
                  byId[promise['fee_record_id']]!,
                  detail: 'Promised for ${promise['promised_date']}',
                ),
        ],
        if (_students.isEmpty) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _saving
                  ? null
                  : () => _write(() async {
                      await _db!.seedDemoData();
                    }, 'Demo data loaded'),
              child: const Text('Load demo data'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _studentsView() {
    final batches =
        _students.map((row) => row['batch']! as String).toSet().toList()
          ..sort();
    final students =
        _students
            .where(
              (row) =>
                  (_batch.isEmpty ||
                      !batches.contains(_batch) ||
                      row['batch'] == _batch) &&
                  '${row['name']} ${row['parent_name']} ${row['parent_whatsapp']}'
                      .toLowerCase()
                      .contains(_search.toLowerCase()),
            )
            .toList()
          ..sort(
            (a, b) =>
                (a['name']! as String).toLowerCase().compareTo(
                  (b['name']! as String).toLowerCase(),
                ) *
                (_descending ? -1 : 1),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading('Students', 'Manage your roster and parent contact details.'),
        TextField(
          controller: _searchInput,
          onChanged: (value) => setState(() => _search = value.trim()),
          decoration: const InputDecoration(
            prefixIcon: Icon(LucideIcons.search),
            labelText: 'Search students',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.listFilter),
              label: Text(batches.contains(_batch) ? _batch : 'All batches'),
              onPressed: () async {
                final value = await showModalBottomSheet<String>(
                  context: context,
                  builder: (sheet) => SafeArea(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final batch in ['', ...batches])
                          ListTile(
                            title: Text(batch.isEmpty ? 'All batches' : batch),
                            onTap: () => Navigator.pop(sheet, batch),
                          ),
                      ],
                    ),
                  ),
                );
                if (mounted && value != null) setState(() => _batch = value);
              },
            ),
            TextButton(
              onPressed: () => setState(() => _descending = !_descending),
              child: Text(_descending ? 'Name Z–A' : 'Name A–Z'),
            ),
          ],
        ),
        if (students.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No students match this view.'),
          ),
        for (final row in students)
          ListTile(
            leading: const CircleAvatar(child: Icon(LucideIcons.userRound)),
            title: Text(row['name']! as String),
            subtitle: Text(
              '${row['batch']} · ${rupees(row['monthly_fee_paise']! as int)}/month',
            ),
            onTap: () => _editStudent(row),
            trailing: IconButton(
              tooltip: 'Student actions',
              icon: const Icon(LucideIcons.ellipsisVertical),
              onPressed: () => _studentActions(row),
            ),
          ),
      ],
    );
  }

  void _studentActions(LocalRow row) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              title: Text(row['name']! as String),
              subtitle: Text(
                '${row['parent_name']} · ${row['parent_whatsapp']}',
              ),
            ),
            ListTile(
              leading: const Icon(LucideIcons.pencil),
              title: const Text('Edit student'),
              onTap: () {
                Navigator.pop(sheet);
                _editStudent(row);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.plus),
              title: const Text('Add monthly fee'),
              onTap: () {
                Navigator.pop(sheet);
                _editFee(student: row);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2),
              title: const Text('Remove student'),
              onTap: () {
                Navigator.pop(sheet);
                _delete(LocalTable.students, row);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _feeTile(LocalRow fee, {String? detail}) {
    final (status, icon) = switch ((
      _balance(fee) <= 0,
      _paid(fee) > 0,
      _overdue(fee),
    )) {
      (true, _, _) => ('Paid', LucideIcons.circleCheck),
      (false, true, _) => ('Partial', LucideIcons.timer),
      (false, false, true) => ('Overdue', LucideIcons.circleAlert),
      _ => ('Pending', LucideIcons.clock),
    };
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(_name(fee['student_id'])),
      subtitle: Text(
        '${detail ?? 'Due ${fee['due_date']}'}\n${rupees(_due(fee))} fee · ${rupees(_paid(fee))} paid · ${rupees(_balance(fee))} left',
      ),
      isThreeLine: true,
      trailing: Tooltip(
        message: status,
        child: Chip(
          avatar: Icon(icon, size: 16),
          label: Text(status),
          backgroundColor: status == 'Overdue'
              ? colors.errorContainer
              : colors.primaryContainer,
          labelStyle: TextStyle(
            color: status == 'Overdue'
                ? colors.onErrorContainer
                : colors.onPrimaryContainer,
          ),
        ),
      ),
      onTap: () => _details(fee),
    );
  }

  Widget _feesView() {
    final fees = _fees.where((fee) => fee['month'] == _month).toList()
      ..sort(
        (a, b) =>
            (a['due_date']! as String).compareTo(b['due_date']! as String),
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading('Fees', 'Review balances and record cash or UPI payments.'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: 'Previous month',
              onPressed: () => setState(() => _monthOffset--),
              icon: const Icon(LucideIcons.chevronLeft),
            ),
            Text(
              MaterialLocalizations.of(
                context,
              ).formatMonthYear(DateTime.parse('$_month-01')),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: () => setState(() => _monthOffset++),
              icon: const Icon(LucideIcons.chevronRight),
            ),
          ],
        ),
        const Divider(),
        if (fees.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No fee records for this month.'),
          ),
        for (final fee in fees) _feeTile(fee),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.leftHanded;
    final tabs = [
      const NavigationDestination(
        icon: Icon(LucideIcons.layoutDashboard),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(LucideIcons.users),
        label: 'Students',
      ),
      const NavigationDestination(
        icon: Icon(LucideIcons.receipt),
        label: 'Fees',
      ),

      const NavigationDestination(
        icon: Icon(LucideIcons.bookOpen),
        label: 'Homework',
      ),
      const NavigationDestination(
        icon: Icon(LucideIcons.settings),
        label: 'Settings',
      ),
    ];
    final settings = widget.settings(
      _openSync,
      MonthlyFeeReminders.supported
          ? SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Monthly fee reminders'),
              subtitle: const Text(
                'Unpaid fee total on the first of each month',
              ),
              value: _remindersEnabled,
              onChanged: _loading || _changingReminders
                  ? null
                  : _toggleReminders,
            )
          : null,
    );
    return Scaffold(
      key: _scaffold,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: const [SizedBox.shrink()],
        title: const Text('Class Desk'),
      ),
      drawer: left ? settings : null,
      endDrawer: left ? null : settings,
      bottomNavigationBar: NavigationBar(
        selectedIndex: left ? tabs.length - 1 - _tab : _tab,
        destinations: left ? tabs.reversed.toList() : tabs,
        onDestinationSelected: (index) {
          final selected = left ? tabs.length - 1 - index : index;
          if (selected == tabs.length - 1) {
            if (left) {
              _scaffold.currentState?.openDrawer();
            } else {
              _scaffold.currentState?.openEndDrawer();
            }
          } else {
            setState(() => _tab = selected);
          }
        },
      ),
      floatingActionButtonLocation: left
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
      floatingActionButton:
          _loading ||
              _failed ||
              _saving ||
              (_tab != 1 && (_tab != 2 || _students.isEmpty))
          ? null
          : FloatingActionButton.extended(
              onPressed: _tab == 2 ? () => _editFee() : () => _editStudent(),
              icon: const Icon(LucideIcons.plus),
              label: Text(_tab == 2 ? 'Add fee' : 'Add student'),
            ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Loading Class Desk',
              ),
            )
          : _failed
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Local storage could not be opened. Try again.'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              key: PageStorageKey(_tab),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 104),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 880),
                    child: switch (_tab) {
                      1 => _studentsView(),
                      2 => _feesView(),
                      3 => HomeworkView(
                        database: _db!,
                        students: _students,
                        leftHanded: left,
                        onChanged: () => _sync?.refreshCount(),
                      ),
                      _ => _dashboard(),
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
