import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
  ];

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Nagar Vikas',
      'welcome': 'Welcome',
      'about': 'About',
      'adminDashboard': 'Admin Dashboard',
      'analyticsDashboard': 'Analytics Dashboard',
      'animals': 'Animals',
      'complaintDetail': 'Complaint Detail',
      'contact': 'Contact',
      'discussion': 'Discussion',
      'done': 'Done',
      'drainage': 'Drainage',
      'facingIssues': 'Facing Issues',
      'feedback': 'Feedback',
      'funGame': 'Fun Game',
      'garbage': 'Garbage',
      'issueSelection': 'Issue Selection',
      'login': 'Login',
      'logo': 'Logo',
      'myComplaints': 'My Complaints',
      'newEntry': 'New Entry',
      'profile': 'Profile',
      'referearn': 'Refer & Earn',
      'register': 'Register',
      'road': 'Road',
      'streetLight': 'Street Light',
      'water': 'Water',
    },
    'hi': {
      'appTitle': 'नगर विकास',
      'welcome': 'स्वागत है',
      'about': 'के बारे में',
      'adminDashboard': 'प्रशासन डैशबोर्ड',
      'analyticsDashboard': 'विश्लेषण डैशबोर्ड',
      'animals': 'जानवर',
      'complaintDetail': 'शिकायत विवरण',
      'contact': 'संपर्क करें',
      'discussion': 'चर्चा',
      'done': 'पूर्ण',
      'drainage': 'जल निकासी',
      'facingIssues': 'समस्याओं का सामना',
      'feedback': 'प्रतिक्रिया',
      'funGame': 'मज़ेदार खेल',
      'garbage': 'कचरा',
      'issueSelection': 'मुद्दा चयन',
      'login': 'लॉगिन',
      'logo': 'लोगो',
      'myComplaints': 'मेरी शिकायतें',
      'newEntry': 'नई प्रविष्टि',
      'profile': 'प्रोफ़ाइल',
      'referearn': 'रेफर और कमाएँ',
      'register': 'रजिस्टर',
      'road': 'सड़क',
      'streetLight': 'स्ट्रीट लाइट',
      'water': 'पानी',
    },
  };

  String? get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']?[key];
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
