import 'package:flutter/material.dart';
import '../components/shared_issue_form.dart';

class StreetLightPage extends StatelessWidget {
  const StreetLightPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Street Lights Issue"),
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: const SharedIssueForm(
        issueType: "Street Lights",
        headingText: "Street Lights issue selected",
        infoText:
            "Please give accurate and correct information for a faster solution.",
        imageAsset: "assets/selected.png",
      ),
    );
  }
}
