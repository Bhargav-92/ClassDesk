// Keep compatibility with Flutter stable's built-in Material library.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/class_desk_app.dart';
import 'core/database/local_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = SharedPreferencesAsync();
  var mode = ThemeMode.system;
  var leftHanded = false;
  var loadFailed = false;
  try {
    final savedMode = await preferences.getString('theme_mode');
    mode = ThemeMode.values.firstWhere(
      (option) => option.name == savedMode,
      orElse: () => ThemeMode.system,
    );
    leftHanded = await preferences.getBool('left_handed') ?? false;
  } on Exception {
    loadFailed = true;
  }

  runApp(
    ClassDeskApp(
      preferences: preferences,
      initialMode: mode,
      initialLeftHanded: leftHanded,
      loadFailed: loadFailed,
      openDatabase: LocalDatabase.open,
    ),
  );
}
