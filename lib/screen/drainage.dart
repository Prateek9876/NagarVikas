import 'package:nagarvikas/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import '../components/shared_issue_form.dart';

class DrainagePage extends StatelessWidget {
  const DrainagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('drainageIssue')), // Localized string
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SharedIssueForm(
        issueType: loc.get('drainageIssueType'), // Localized string
        headingText: loc.get('drainageIssueSelected'), // Localized string
        infoText: loc.get('infoText'), // Already localized
        imageAsset: "assets/selected.png",
      ),
    );
  }
}
