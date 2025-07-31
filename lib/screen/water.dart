import 'package:nagarvikas/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import '../components/shared_issue_form.dart';

class WaterPage extends StatelessWidget {
  const WaterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('waterIssue')),
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SharedIssueForm(
        issueType: loc.get('water'),
        headingText: loc.get('waterSupplyIssueSelected'),
        infoText: loc.get('provideAccurateInfo'),
        imageAsset: "assets/selected.png",
      ),
    );
  }
}
