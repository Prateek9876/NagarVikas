import 'package:nagarvikas/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import '../components/shared_issue_form.dart';

class NewEntryPage extends StatelessWidget {
  const NewEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context); // Get localization instance
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get("newEntry") ?? "New Entry"), // Localized string
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SharedIssueForm(
        issueType: loc.get("newIssue") ?? "New Issue",
        headingText: loc.get("enterNewIssue") ?? "Enter new issue",
        infoText: loc.get("provideAccurateInfo") ??
            "Please give accurate and correct information for a faster solution.",
        imageAsset: "assets/selected.png",
      ),
    );
  }
}
