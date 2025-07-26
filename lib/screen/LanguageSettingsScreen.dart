import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  Locale? _selectedLocale;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('app_language') ?? 'en';
    setState(() {
      _selectedLocale = Locale(langCode);
    });
  }

  Future<void> _changeLanguage(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', locale.languageCode);
    setState(() {
      _selectedLocale = locale;
    });
    // Optionally, you can trigger a rebuild or notify the app to update locale
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('languageSettings') ?? 'Language Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              loc.get('chooseLanguageSettings') ?? 'Select your app language:',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            LanguageRadio(
              label: 'English',
              value: const Locale('en'),
              groupValue: _selectedLocale ?? const Locale('en'),
              onChanged: _changeLanguage,
            ),
            const SizedBox(height: 16),
            LanguageRadio(
              label: 'हिन्दी',
              value: const Locale('hi'),
              groupValue: _selectedLocale ?? const Locale('en'),
              onChanged: _changeLanguage,
            ),
          ],
        ),
      ),
    );
  }
}

class LanguageRadio extends StatelessWidget {
  final String label;
  final Locale value;
  final Locale groupValue;
  final Function(Locale) onChanged;
  const LanguageRadio({super.key, required this.label, required this.value, required this.groupValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return RadioListTile<Locale>(
      title: Text(label),
      value: value,
      groupValue: groupValue,
      onChanged: (locale) {
        if (locale != null) onChanged(locale);
      },
    );
  }
}
