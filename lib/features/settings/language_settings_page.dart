import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import 'providers/settings_provider.dart';

class LanguageSettingsPage extends ConsumerWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor =
        theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF));
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFEAE5DD);
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final mutedText = isDark ? Colors.white70 : const Color(0xFF6F6F72);
    final primaryColor = theme.colorScheme.primary;

    final currentLanguage = ref.watch(settingsProvider).language;
    final settingsNotifier = ref.read(settingsProvider.notifier);

    final languages = [
      {'name': 'English', 'code': 'en'},
      {'name': 'Hindi', 'code': 'hi'},
      {'name': 'Gujarati', 'code': 'gu'},
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(context.l10n.language),
        centerTitle: false,
        backgroundColor: backgroundColor,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              context.l10n.selectAppLanguage,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: mutedText,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: languages.asMap().entries.map((entry) {
                final index = entry.key;
                final lang = entry.value;
                final isSelected = currentLanguage == lang['name'];

                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        // Persist the selected language and dynamically rebuild app tree
                        settingsNotifier.setLanguage(lang['name']!);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                lang['name']!,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? primaryColor : mutedText.withValues(alpha: 0.5),
                                  width: isSelected ? 6 : 2,
                                ),
                                color: backgroundColor, // Transparent center when unselected
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (index < languages.length - 1)
                      Divider(height: 1, color: borderColor, indent: 16, endIndent: 16),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              context.l10n.languageSubtext,
              style: theme.textTheme.bodySmall?.copyWith(
                color: mutedText,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
