import 'package:flutter/material.dart';
import '../components/shared_issue_form.dart';

class WaterPage extends StatelessWidget {
  const WaterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('water') ?? 'Water Issue'),
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SharedIssueForm(
        issueType: loc.get('water') ?? 'Water',
        headingText: loc.get('water') != null ? '${loc.get('water')} supply issue selected' : 'Water supply issue selected',
        infoText: loc.get('infoText') ?? 'Please give accurate and correct information for a faster solution.',
        imageAsset: "assets/selected.png",
      ),
    );
  }
}
