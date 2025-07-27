import 'package:flutter/material.dart';
import '../components/shared_issue_form.dart';
import 'package:NagarVikas/localization/app_localizations.dart';


class RoadPage extends StatelessWidget {
  const RoadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get("roadIssue")),
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SharedIssueForm(
        issueType: loc.get("road"),
        headingText: loc.get("roadDamageIssueSelected"),
        infoText: loc.get("provideAccurateInfo"),
        imageAsset: "assets/selected.png",
      ),
    );
  }
}