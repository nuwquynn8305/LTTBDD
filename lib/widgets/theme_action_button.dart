import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import '../models/app_currency.dart';
import '../providers/currency_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';

class ThemeActionButton extends ConsumerWidget {
  const ThemeActionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);
    final currency = ref.watch(currencyNotifierProvider);
    final strings = AppStrings.fromLocale(locale);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quick Language Switch button
        IconButton(
          tooltip: strings.language,
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              locale.languageCode == 'vi' ? '🇻🇳 VI' : '🇬🇧 EN',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          onPressed: () {
            ref.read(localeNotifierProvider.notifier).toggleLocale();
          },
        ),

        // Quick Settings Popup: Currency, Theme, Language
        PopupMenuButton<String>(
          tooltip: strings.quickSettings,
          icon: Icon(switch (mode) {
            ThemeMode.light => Icons.light_mode_outlined,
            ThemeMode.dark => Icons.dark_mode_outlined,
            ThemeMode.system => Icons.settings_suggest_outlined,
          }),
          itemBuilder: (context) => [
            // Currency section header
            PopupMenuItem<String>(
              enabled: false,
              child: Text(
                '💱 ${strings.currency}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...AppCurrency.supportedCurrencies.map((c) {
              final isSelected = c.code == currency.code;
              return PopupMenuItem<String>(
                value: 'curr_${c.code}',
                child: Row(
                  children: [
                    Text(
                      c.symbol,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(c.name)),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              );
            }),
            const PopupMenuDivider(),

            // Theme section header
            PopupMenuItem<String>(
              enabled: false,
              child: Text(
                '🌓 ${strings.theme}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            PopupMenuItem<String>(
              value: 'theme_system',
              child: Row(
                children: [
                  const Icon(Icons.brightness_auto_outlined, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(strings.themeSystem)),
                  if (mode == ThemeMode.system)
                    Icon(
                      Icons.check,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'theme_light',
              child: Row(
                children: [
                  const Icon(Icons.light_mode_outlined, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(strings.themeLight)),
                  if (mode == ThemeMode.light)
                    Icon(
                      Icons.check,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'theme_dark',
              child: Row(
                children: [
                  const Icon(Icons.dark_mode_outlined, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(strings.themeDark)),
                  if (mode == ThemeMode.dark)
                    Icon(
                      Icons.check,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value.startsWith('curr_')) {
              final code = value.replaceFirst('curr_', '');
              ref.read(currencyNotifierProvider.notifier).setCurrencyByCode(code);
            } else if (value == 'theme_system') {
              ref.read(themeNotifierProvider.notifier).setTheme(ThemeMode.system);
            } else if (value == 'theme_light') {
              ref.read(themeNotifierProvider.notifier).setTheme(ThemeMode.light);
            } else if (value == 'theme_dark') {
              ref.read(themeNotifierProvider.notifier).setTheme(ThemeMode.dark);
            }
          },
        ),
      ],
    );
  }
}
