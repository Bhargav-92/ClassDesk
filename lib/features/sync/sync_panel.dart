import 'dart:convert';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/database/local_database.dart';
import 'manual_sync.dart';

class SyncController extends ChangeNotifier {
  SyncController(this.store, this.onComplete);

  final LocalSyncStore store;
  final Future<void> Function() onComplete;
  final _storage = const FlutterSecureStorage();
  static const _configKey = 'class_desk_sync_connection';

  SyncCredentials? credentials;
  DateTime? lastSuccess;
  String? error;
  String? progress;
  int pending = 0;
  bool running = false;
  bool _disposed = false;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    try {
      final value = await _storage.read(key: _configKey);
      if (value != null) {
        final config = jsonDecode(value);
        if (config is! List ||
            config.length != 2 ||
            config[0] is! String ||
            config[1] is! String) {
          throw const FormatException('Invalid saved sync configuration.');
        }
        final saved = SyncCredentials(config[0] as String, config[1] as String);
        lastSuccess = (await store.checkpoint(
          saved.endpoint.toString(),
        )).lastSuccess;
        credentials = saved;
      }
    } on Exception {
      error = 'Could not load the saved sync configuration. Check Settings.';
    }
    await refreshCount();
  }

  Future<void> refreshCount() async {
    try {
      pending = await store.pendingCount();
    } on Exception {
      return;
    }
    _changed();
  }

  Future<void> configure(SyncCredentials value) async {
    final state = await store.checkpoint(value.endpoint.toString());
    await _storage.write(
      key: _configKey,
      value: jsonEncode([value.endpoint.toString(), value.token]),
    );
    credentials = value;
    lastSuccess = state.lastSuccess;
    error = null;
    _changed();
  }

  Future<void> run() async {
    final config = credentials;
    if (config == null || running || _disposed) return;
    running = true;
    progress = 'Checking connection';
    error = null;
    _changed();
    final client = http.Client();
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.every((result) => result == ConnectivityResult.none)) {
        throw const FormatException(
          'No internet. Your data is safe on this device.',
        );
      }
      final state = await ManualSync(store, HttpSyncTransport(config, client))
          .run(config.endpoint.toString(), (value) {
            progress = value;
            _changed();
          });
      lastSuccess = state.lastSuccess;
    } on FormatException catch (issue) {
      error = issue.message;
    } on Exception {
      error =
          'Could not finish sync. Saved changes are safe on this device. Try again.';
    } finally {
      client.close();
      if (!_disposed) await onComplete();
      running = false;
      progress = null;
      if (!_disposed) {
        await refreshCount();
        _changed();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

Future<void> showSyncPanel(BuildContext context, SyncController controller) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SyncPanel(controller: controller),
    );

class _SyncPanel extends StatefulWidget {
  const _SyncPanel({required this.controller});
  final SyncController controller;

  @override
  State<_SyncPanel> createState() => _SyncPanelState();
}

class _SyncPanelState extends State<_SyncPanel> {
  SyncController get _sync => widget.controller;
  static const _hostedEndpoint = String.fromEnvironment(
    'CLASS_DESK_SYNC_URL',
    defaultValue: 'https://classdesk-qcvs.onrender.com',
  );
  static const _defaultEndpoint = 'https://classdesk-qcvs.onrender.com';

  final _token = TextEditingController();
  String? _configError;
  bool _saving = false;

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _configError = null;
    });
    try {
      final endpoint =
          _sync.credentials?.endpoint.toString() ??
          (_hostedEndpoint.isEmpty ? _defaultEndpoint : _hostedEndpoint);
      final token = _token.text.trim();
      if (token.isNotEmpty || _sync.credentials == null) {
        if (token.length < 32 || RegExp(r'\s').hasMatch(token)) {
          throw const FormatException(
            'Enter the setup code from your administrator.',
          );
        }
        await _sync.configure(SyncCredentials(endpoint, token));
        if (mounted) _token.clear();
      }
      await _sync.run();
    } on FormatException catch (issue) {
      if (mounted) setState(() => _configError = issue.message);
    } on Exception {
      if (mounted) {
        setState(() => _configError = 'Could not save sync settings.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      child: ListenableBuilder(
        listenable: _sync,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(24),
          shrinkWrap: true,
          children: [
            Text('Sync', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('${_sync.pending} changes waiting'),
            if (_sync.lastSuccess case final time?)
              Text(
                'Last synced ${MaterialLocalizations.of(context).formatShortDate(time)} at ${TimeOfDay.fromDateTime(time).format(context)}',
              ),
            if (_sync.progress case final progress?) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
              Text(progress),
            ],
            if (_sync.error case final error?)
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 24),
            if (_sync.credentials == null) ...[
              const Text(
                'Enter the setup code from your administrator to connect this device.',
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _token,
              enabled: !_sync.running && !_saving,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: _sync.credentials == null
                    ? 'Setup code'
                    : 'New setup code (optional)',
                border: const OutlineInputBorder(),
              ),
            ),
            if (_configError case final error?)
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _sync.running || _saving ? null : _save,
              icon: const Icon(LucideIcons.refreshCw),
              label: Text(
                _sync.credentials == null ? 'Connect and sync' : 'Sync now',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
