import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/database/local_database.dart';

class SyncCredentials {
  SyncCredentials(String endpoint, String token)
    : endpoint = _parseEndpoint(endpoint),
      token = _parseToken(token);

  final Uri endpoint;
  final String token;

  static Uri _parseEndpoint(String value) {
    final uri = Uri.tryParse(value.trim().replaceFirst(RegExp(r'/+$'), ''));
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.scheme != 'https' &&
            !(uri.scheme == 'http' &&
                ['localhost', '127.0.0.1', '::1'].contains(uri.host)))) {
      throw const FormatException(
        'Enter an HTTPS backend URL. HTTP is supported for localhost testing.',
      );
    }
    return uri;
  }

  static String _parseToken(String value) {
    final token = value.trim();
    if (token.length < 32 || RegExp(r'\s').hasMatch(token)) {
      throw const FormatException(
        'Enter the sync token from the backend environment.',
      );
    }
    return token;
  }
}

class SyncPage {
  const SyncPage(this.rows, this.next, this.through, this.more);
  final List<SyncRow> rows;
  final String next, through;
  final bool more;
}

abstract interface class SyncTransport {
  Future<void> verify();
  Future<List<SyncRow>> push(List<SyncRow> rows);
  Future<SyncPage> pull(String cursor, String? through);
}

class HttpSyncTransport implements SyncTransport {
  HttpSyncTransport(this.credentials, this._client);
  final SyncCredentials credentials;
  final http.Client _client;

  Uri _url(String action, [Map<String, String>? parameters]) =>
      credentials.endpoint.replace(
        path: '${credentials.endpoint.path}/v1/sync/$action',
        queryParameters: parameters,
      );

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${credentials.token}',
    'Content-Type': 'application/json',
    'X-ClassDesk-Sync-Version': '2',
  };

  Future<Map<String, dynamic>> _read(Future<http.Response> request) async {
    final response = await request.timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      final message = switch (response.statusCode) {
        401 => 'The sync token was rejected. Check Settings.',
        403 => 'The server does not allow this browser origin.',
        409 =>
          'A local record conflicts with the server. Your local edits are still saved.',
        400 || 413 =>
          'The server rejected a record. Your local edits are still saved.',
        426 => 'Update Class Desk before syncing.',
        404 => 'Check the backend URL in Settings.',
        _ => 'The sync server is unavailable. Try again.',
      };
      throw FormatException(message);
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map<String, dynamic> || data['rows'] is! List) {
      throw const FormatException('Unexpected response from the sync server.');
    }
    return data;
  }

  @override
  Future<void> verify() async {
    final status = await _read(_client.get(_url('check'), headers: _headers));
    if (status['protocol'] != 2) {
      throw const FormatException(
        'Update and restart the Class Desk backend before syncing.',
      );
    }
  }

  @override
  Future<List<SyncRow>> push(List<SyncRow> rows) async {
    final data = await _read(
      _client.post(
        _url('push'),
        headers: _headers,
        body: jsonEncode({'rows': rows.map((row) => row.toJson()).toList()}),
      ),
    );
    return (data['rows'] as List).map(SyncRow.fromJson).toList();
  }

  @override
  Future<SyncPage> pull(String cursor, String? through) async {
    final data = await _read(
      _client.get(
        _url('pull', {'after': cursor, 'through': ?through}),
        headers: _headers,
      ),
    );
    final next = data['next'];
    final ceiling = data['through'];
    final more = data['more'];
    if (next is! String || ceiling is! String || more is! bool) {
      throw const FormatException('Invalid checkpoint from the sync server.');
    }
    return SyncPage(
      (data['rows'] as List).map(SyncRow.fromJson).toList(),
      next,
      ceiling,
      more,
    );
  }
}

class ManualSync {
  ManualSync(this.store, this.transport);
  final LocalSyncStore store;
  final SyncTransport transport;

  Future<SyncCheckpoint> run(
    String endpoint,
    void Function(String) progress,
  ) async {
    await store.checkpoint(endpoint);
    await transport.verify();
    await store.bind(endpoint);
    final snapshot = await store.pendingRows();
    const size = 50;
    for (var start = 0; start < snapshot.length; start += size) {
      final end = (start + size).clamp(0, snapshot.length);
      final batch = snapshot.sublist(start, end);
      progress('Uploading ${start + 1}–$end of ${snapshot.length}');
      try {
        final rows = await transport.push(batch);
        final byKey = {for (final row in rows) (row.table, row.id): row};
        final canonical = <SyncRow>[];
        for (final row in batch) {
          final winner = byKey[(row.table, row.id)];
          if (winner == null || winner.updatedAt < row.updatedAt) {
            throw const FormatException(
              'The server did not confirm the complete upload.',
            );
          }
          canonical.add(winner);
        }
        await store.acknowledge(batch, canonical);
      } on Exception {
        await store.markFailed(batch);
        rethrow;
      }
    }

    var after = (await store.checkpoint(endpoint)).cursor;
    String? through;
    var received = 0;
    while (true) {
      progress('Downloading changes ($received received)');
      final page = await transport.pull(after, through);
      final previous = BigInt.tryParse(after);
      final next = BigInt.tryParse(page.next);
      final ceiling = BigInt.tryParse(page.through);
      if (previous == null ||
          next == null ||
          ceiling == null ||
          next < previous ||
          next > ceiling ||
          (through != null && through != page.through) ||
          (page.more && (next == previous || page.rows.isEmpty)) ||
          (!page.more && next != ceiling)) {
        throw const FormatException(
          'The server returned an invalid sync checkpoint.',
        );
      }
      await store.applyPage(
        page.rows,
        endpoint: endpoint,
        cursor: page.next,
        done: !page.more,
      );
      if (!page.more) return store.checkpoint(endpoint);
      through = page.through;
      after = page.next;
      received += page.rows.length;
    }
  }
}
