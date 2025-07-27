import 'package:NagarVikas/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import '../components/shared_issue_form.dart'; 
class AnimalsPage extends StatelessWidget {
  const AnimalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).get('strayAnimalsIssueTitle')), // Localized string
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SharedIssueForm( // Removed const as it's no longer a const constructor
        issueType: AppLocalizations.of(context).get('strayAnimalsIssueType'), // Localized string
        headingText: AppLocalizations.of(context).get('strayAnimalsHeadingText'), // Localized string
        infoText: AppLocalizations.of(context).get('infoText'), // Reusing existing localized string
        imageAsset: "assets/selected.png",
      ),
    );
  }
}