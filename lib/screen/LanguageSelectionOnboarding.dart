import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class LanguageSelectionOnboarding extends StatelessWidget {
  final Function(Locale) onLanguageSelected;
  const LanguageSelectionOnboarding({super.key, required this.onLanguageSelected});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('selectLanguage') ?? 'Select Language'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              loc.get('chooseLanguageOnboarding') ?? 'Please choose your preferred language:',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            LanguageButton(
              label: 'English',
              onTap: () => onLanguageSelected(const Locale('en')),
            ),
            const SizedBox(height: 16),
            LanguageButton(
              label: 'हिन्दी',
              onTap: () => onLanguageSelected(const Locale('hi')),
            ),
          ],
        ),
      ),
    );
  }
}

class LanguageButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const LanguageButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}
