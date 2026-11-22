import 'package:class_desk/app/class_desk_app.dart';
import 'package:class_desk/core/theme/class_theme.dart';
// Keep compatibility with Flutter stable's built-in Material library.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

double contrast(Color first, Color second) {
  final values = [first.computeLuminance(), second.computeLuminance()]..sort();
  return (values.last + 0.05) / (values.first + 0.05);
}

void main() {
  test('Preview text and status icons meet WCAG AA contrast', () {
    for (final palette in [ClassPalette.light, ClassPalette.dark]) {
      for (final surface in [palette.surface, palette.background]) {
        expect(
          contrast(palette.textPrimary, surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(palette.textSecondary, surface),
          greaterThanOrEqualTo(4.5),
        );
      }
      expect(
        contrast(palette.onPrimary, palette.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(palette.onPrimaryContainer, palette.primaryContainer),
        greaterThanOrEqualTo(4.5),
      );
      for (final status in [
        palette.success,
        palette.accent,
        palette.warning,
        palette.error,
      ]) {
        expect(
          contrast(ClassPalette.light.textPrimary, status),
          greaterThanOrEqualTo(3),
        );
      }
    }
  });

  testWidgets('Shows both previews and saves appearance changes', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final preferences = SharedPreferencesAsync();
    await tester.pumpWidget(
      ClassDeskApp(
        preferences: preferences,
        initialMode: ThemeMode.system,
        initialLeftHanded: false,
        loadFailed: false,
      ),
    );
    expect(find.text('Light theme'), findsOneWidget);
    expect(find.text('Dark theme'), findsOneWidget);

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(await preferences.getString('theme_mode'), 'dark');
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );

    await tester.tap(find.text('Left-handed mode'));
    await tester.pumpAndSettle();
    expect(await preferences.getBool('left_handed'), isTrue);
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).drawer, isNotNull);
  });
}
