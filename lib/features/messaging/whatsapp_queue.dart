// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/database/local_database.dart';
import '../../core/theme/class_theme.dart';

const defaultFeeTemplate =
    "Hello {parent_name}, this is a gentle reminder from {class_name}. "
    "{student_name}'s fee balance of ₹{remaining} is due on {date}. "
    'Paid so far: ₹{paid}. Thank you.';

String renderMessage(String template, Map<String, String> values) => template
    .replaceAllMapped(
      RegExp(r'\{([a-z_]+)\}'),
      (match) => values[match[1]] ?? match[0]!,
    )
    .trim();

String? normalizeWhatsAppNumber(String phone) {
  final compact = phone.replaceAll(RegExp(r'[ ()-]'), '');
  final normalized = RegExp(r'^[6-9]\d{9}$').hasMatch(compact)
      ? '+91$compact'
      : compact;
  if (!RegExp(r'^\+91[6-9]\d{9}$').hasMatch(normalized)) return null;
  return normalized;
}

Uri? whatsappUri(String phone, String message) {
  final normalized = normalizeWhatsAppNumber(phone);
  if (normalized == null) return null;
  return Uri.https('wa.me', '/${normalized.substring(1)}', {'text': message});
}

class WhatsAppQueue extends StatefulWidget {
  const WhatsAppQueue({
    super.key,
    required this.database,
    required this.recipients,
    this.message,
    this.homeworkId,
    this.feeValues,
  }) : assert((message != null && homeworkId != null) || feeValues != null);

  final LocalDatabase database;
  final List<LocalRow> recipients;
  final String? message;
  final String? homeworkId;
  final Map<String, String>? feeValues;

  @override
  State<WhatsAppQueue> createState() => _WhatsAppQueueState();
}

class _WhatsAppQueueState extends State<WhatsAppQueue> {
  static const _templateKey = 'fee_reminder_template';
  static const _classKey = 'message_class_name';
  final _preferences = SharedPreferencesAsync();
  final _opened = <String>{};
  final _sent = <String>{};
  bool _busy = false;
  bool _loading = true;
  bool _loadFailed = false;
  String _template = defaultFeeTemplate;
  String _className = 'Class Desk';

  String get _message =>
      widget.message ??
      renderMessage(_template, {
        ...widget.feeValues!,
        'class_name': _className,
      });

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final homeworkId = widget.homeworkId;
      if (homeworkId == null) {
        _template =
            await _preferences.getString(_templateKey) ?? defaultFeeTemplate;
        _className = await _preferences.getString(_classKey) ?? 'Class Desk';
      } else {
        _sent.addAll(await widget.database.homeworkRecipientsSent(homeworkId));
      }
    } on Exception {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _notice(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _open(LocalRow recipient) async {
    final uri = whatsappUri(recipient['parent_whatsapp']! as String, _message);
    if (uri == null) {
      _notice('Update the student’s WhatsApp number before sending.');
      return;
    }
    setState(() => _busy = true);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (opened) {
        setState(() => _opened.add(recipient['id']! as String));
      } else {
        _notice(
          'Could not open WhatsApp. You can copy the message and try again.',
        );
      }
    } on Exception {
      _notice(
        'Could not open WhatsApp. You can copy the message and try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markSent(String id) async {
    setState(() => _busy = true);
    try {
      await widget.database.confirmWhatsAppSent(
        studentId: id,
        homeworkId: widget.homeworkId,
      );
      if (mounted) setState(() => _sent.add(id));
    } on Exception {
      _notice('Could not save the sent status. Try marking it again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: _message));
      _notice('Message copied');
    } on Exception {
      _notice('Could not copy the message. You can select the text above.');
    }
  }

  Future<void> _editTemplate() async {
    final edited = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TemplateForm(template: _template, className: _className),
    );
    if (edited == null || !mounted) return;
    try {
      await _preferences.setString(_templateKey, edited.$1);
      await _preferences.setString(_classKey, edited.$2);
      if (mounted) {
        setState(() {
          _template = edited.$1;
          _className = edited.$2;
        });
      }
    } on Exception {
      _notice('Could not save the template. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final homework = widget.homeworkId != null;
    return Scaffold(
      appBar: AppBar(title: Text(homework ? 'Send queue' : 'Fee reminder')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
          ? Center(
              child: FilledButton(
                onPressed: _load,
                child: const Text('Retry loading messages'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'WhatsApp message',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                SelectableText(_message),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _copy,
                      icon: const Icon(LucideIcons.copy),
                      label: const Text('Copy message'),
                    ),
                    if (!homework)
                      TextButton(
                        onPressed: _editTemplate,
                        child: const Text('Edit template'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  homework ? 'Parents' : 'Parent',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Send the message in WhatsApp, then return here to confirm it.',
                ),
                const SizedBox(height: 8),
                if (widget.recipients.isEmpty)
                  const Text('There are no students in this batch.'),
                for (final recipient in widget.recipients)
                  _recipient(recipient),
              ],
            ),
    );
  }

  Widget _recipient(LocalRow recipient) {
    final id = recipient['id']! as String;
    final sent = _sent.contains(id);
    final opened = _opened.contains(id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${recipient['parent_name']} · ${recipient['name']}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (sent)
            const Chip(
              avatar: Icon(LucideIcons.circleCheck, size: 18),
              label: Text('Sent'),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : () => _open(recipient),
                  style: FilledButton.styleFrom(
                    backgroundColor: ClassPalette.whatsapp,
                    foregroundColor: ClassPalette.light.textPrimary,
                  ),
                  icon: const Icon(LucideIcons.messageCircle),
                  label: Text(opened ? 'Reopen WhatsApp' : 'Open WhatsApp'),
                ),
                if (opened)
                  OutlinedButton(
                    onPressed: _busy ? null : () => _markSent(id),
                    child: const Text('Mark as sent'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TemplateForm extends StatefulWidget {
  const _TemplateForm({required this.template, required this.className});
  final String template;
  final String className;

  @override
  State<_TemplateForm> createState() => _TemplateFormState();
}

class _TemplateFormState extends State<_TemplateForm> {
  late final _template = TextEditingController(text: widget.template);
  late final _className = TextEditingController(text: widget.className);
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _template.dispose();
    _className.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'Enter a value' : null;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      child: Form(
        key: _form,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Fee reminder template',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _className,
              validator: _required,
              decoration: const InputDecoration(labelText: 'Class name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _template,
              validator: _required,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Variables: {parent_name}, {class_name}, {student_name}, {remaining}, {paid}, {date}, {link}',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => _template.text = defaultFeeTemplate,
                  child: const Text('Reset template'),
                ),
                FilledButton(
                  onPressed: () {
                    if (_form.currentState!.validate()) {
                      Navigator.pop(context, (
                        _template.text.trim(),
                        _className.text.trim(),
                      ));
                    }
                  },
                  child: const Text('Save template'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
