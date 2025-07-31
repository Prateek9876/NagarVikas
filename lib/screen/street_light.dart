import 'package:flutter/material.dart';
import '../components/shared_issue_form.dart';
import 'package:nagarvikas/localization/app_localizations.dart';

class StreetLightPage extends StatelessWidget {
  const StreetLightPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get("streetLightIssue")),
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SharedIssueForm(
        issueType: loc.get("streetLights"),
        headingText: loc.get("streetLightsIssueSelected"),
        infoText: loc.get("provideAccurateInfo"),
        imageAsset: "assets/selected.png",
      ),
    );
  }
}
