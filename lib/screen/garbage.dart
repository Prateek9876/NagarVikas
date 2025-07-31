import 'package:flutter/material.dart';
import '../components/shared_issue_form.dart';
import 'package:nagarvikas/localization/app_localizations.dart'; // Import localization

class GarbagePage extends StatelessWidget {
  const GarbagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context); // Get localization instance

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('garbageIssue')), // Localized string
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SharedIssueForm(
        issueType: loc.get('garbage'), // Localized string
        headingText: loc.get('garbageLiftingIssueSelected'), // Localized string
        infoText: loc.get('provideAccurateInfo'), // Already localized in app_localizations.dart
        imageAsset: "assets/selected.png",
      ),
    );
  }
}
