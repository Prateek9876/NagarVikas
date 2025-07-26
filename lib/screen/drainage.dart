import 'package:flutter/material.dart';
import '../components/shared_issue_form.dart';

class DrainagePage extends StatelessWidget {
  const DrainagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('drainage') ?? 'Drainage Issue'),
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SharedIssueForm(
        issueType: loc.get('drainage') ?? 'Drainage Issue',
        headingText: loc.get('drainage') != null ? '${loc.get('drainage')} issue selected' : 'Drainage issue selected',
        infoText: loc.get('infoText') ?? 'Please give accurate and correct information for a faster solution.',
        imageAsset: "assets/selected.png",
      ),
    );
  }
}
