// Keep compatibility with Flutter stable's built-in Material library.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/class_theme.dart';

class StyleGuide extends StatelessWidget {
  const StyleGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text('Style guide', style: text.headlineLarge),
                ),
                const SizedBox(height: ClassSpacing.small),
                const Text(
                  'Light and dark previews for the Class Desk fee dashboard.',
                ),
                const SizedBox(height: ClassSpacing.large),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const light = _ThemePreview(brightness: Brightness.light);
                    const dark = _ThemePreview(brightness: Brightness.dark);
                    if (constraints.maxWidth < 650) {
                      return const Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          light,
                          SizedBox(height: ClassSpacing.medium),
                          dark,
                        ],
                      );
                    }
                    return const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: light),
                        SizedBox(width: ClassSpacing.medium),
                        Expanded(child: dark),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.brightness});

  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final dark = brightness == Brightness.dark;
    final palette = dark ? ClassPalette.dark : ClassPalette.light;
    final theme = palette.theme(brightness);
    final text = theme.textTheme;
    return Theme(
      data: theme,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: palette.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(ClassSpacing.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DefaultTextStyle(
                style: text.titleLarge!.copyWith(color: palette.textPrimary),
                child: Semantics(
                  header: true,
                  child: Text(dark ? 'Dark theme' : 'Light theme'),
                ),
              ),
              const SizedBox(height: ClassSpacing.medium),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(ClassSpacing.medium),
                  child: DefaultTextStyle(
                    style: text.bodyMedium!.copyWith(
                      color: palette.onPrimaryContainer,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Collected this month (demo)'),
                        Text(
                          '₹24,500',
                          style: text.headlineLarge?.copyWith(
                            color: palette.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: ClassSpacing.medium),
              for (final item in [
                (
                  'Ananya Rao',
                  'Paid',
                  LucideIcons.circleCheck,
                  palette.success,
                ),
                (
                  'Rahul Mehta',
                  'Partial',
                  LucideIcons.circleDashed,
                  palette.accent,
                ),
                ('Ishaan Patel', 'Pending', LucideIcons.clock, palette.warning),
                (
                  'Meera Shah',
                  'Overdue',
                  LucideIcons.circleAlert,
                  palette.error,
                ),
              ])
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: ClassSpacing.small,
                  ),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: palette.border)),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: ClassSpacing.small,
                    runSpacing: ClassSpacing.small,
                    children: [
                      Text(
                        item.$1,
                        style: text.bodyLarge?.copyWith(
                          color: palette.textPrimary,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: item.$4,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                item.$3,
                                size: 16,
                                color: ClassPalette.light.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: ClassSpacing.small),
                          Text(
                            item.$2,
                            style: text.bodyMedium?.copyWith(
                              color: palette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
