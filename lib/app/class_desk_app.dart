// Keep compatibility with Flutter stable's built-in Material library.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/database/local_database.dart';
import '../core/theme/class_theme.dart';
import '../features/workspace/class_workspace.dart';
import '../features/style_guide/style_guide.dart';

class ClassDeskApp extends StatefulWidget {
  const ClassDeskApp({
    super.key,
    required this.preferences,
    required this.initialMode,
    required this.initialLeftHanded,
    required this.loadFailed,
    this.openDatabase,
  });

  final SharedPreferencesAsync preferences;
  final ThemeMode initialMode;
  final bool initialLeftHanded;
  final bool loadFailed;
  final Future<LocalDatabase> Function()? openDatabase;

  @override
  State<ClassDeskApp> createState() => _ClassDeskAppState();
}

class _ClassDeskAppState extends State<ClassDeskApp> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  late ThemeMode _mode = widget.initialMode;
  late bool _leftHanded = widget.initialLeftHanded;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.loadFailed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notify('Saved preferences could not be loaded. Defaults are active.');
      });
    }
  }

  void _notify(String message) {
    _messenger.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save(
    Future<void> Function() persist,
    VoidCallback apply,
  ) async {
    setState(() => _saving = true);
    try {
      await persist();
      if (mounted) setState(apply);
    } on Exception {
      _notify('Could not save your preference. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Class Desk',
      theme: ClassPalette.light.theme(Brightness.light),
      darkTheme: ClassPalette.dark.theme(Brightness.dark),
      themeMode: _mode,
      themeAnimationDuration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 180),
      scaffoldMessengerKey: _messenger,
      home: widget.openDatabase != null
          ? ClassWorkspace(
              openDatabase: widget.openDatabase!,
              settings: (openSync, reminders) =>
                  _settings(onSync: openSync, reminders: reminders),
              leftHanded: _leftHanded,
            )
          : Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: const Text('Class Desk'),
                actions: const [SizedBox.shrink()],
              ),
              drawer: _leftHanded ? _settings() : null,
              endDrawer: _leftHanded ? null : _settings(),
              body: const StyleGuide(),
              bottomNavigationBar: Builder(
                builder: (context) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(ClassSpacing.medium),
                    child: Align(
                      heightFactor: 1,
                      alignment: _leftHanded
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: FilledButton.icon(
                        icon: const Icon(LucideIcons.settings),
                        label: const Text('Appearance'),
                        onPressed: () {
                          final scaffold = Scaffold.of(context);
                          if (_leftHanded) {
                            scaffold.openDrawer();
                          } else {
                            scaffold.openEndDrawer();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _settings({VoidCallback? onSync, Widget? reminders}) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ClassSpacing.large),
          children: [
            const Text(
              'Appearance',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: ClassSpacing.large),
            const Text('App theme'),
            const SizedBox(height: ClassSpacing.small),
            for (final mode in ThemeMode.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(switch (mode) {
                  ThemeMode.system => 'Use system setting',
                  ThemeMode.light => 'Light',
                  ThemeMode.dark => 'Dark',
                }),
                trailing: Icon(
                  _mode == mode ? LucideIcons.circleCheck : LucideIcons.circle,
                ),
                selected: _mode == mode,
                onTap: _saving || _mode == mode
                    ? null
                    : () => _save(
                        () => widget.preferences.setString(
                          'theme_mode',
                          mode.name,
                        ),
                        () => _mode = mode,
                      ),
              ),
            const Divider(),
            ?reminders,
            if (onSync != null)
              ListTile(
                leading: const Icon(LucideIcons.refreshCw),
                title: const Text('Sync'),
                onTap: onSync,
              ),
            if (widget.openDatabase != null)
              Builder(
                builder: (context) => ListTile(
                  leading: const Icon(LucideIcons.palette),
                  title: const Text('Style guide'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => Scaffold(
                          appBar: AppBar(title: const Text('Class Desk')),
                          body: const StyleGuide(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Left-handed mode'),
              value: _leftHanded,
              onChanged: _saving
                  ? null
                  : (value) => _save(
                      () => widget.preferences.setBool('left_handed', value),
                      () => _leftHanded = value,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
