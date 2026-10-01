import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

class ThemeActionButton extends ConsumerWidget {
  const ThemeActionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeNotifierProvider);

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Giao diện',
      icon: Icon(switch (mode) {
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
        ThemeMode.system => Icons.brightness_auto_outlined,
      }),
      onSelected: (value) {
        ref.read(themeNotifierProvider.notifier).setTheme(value);
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: ThemeMode.system,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.brightness_auto_outlined),
            title: Text('Theo hệ thống'),
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.light,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.light_mode_outlined),
            title: Text('Sáng'),
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.dark_mode_outlined),
            title: Text('Tối'),
          ),
        ),
      ],
    );
  }
}
