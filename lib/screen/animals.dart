import 'package:flutter/material.dart';
import '../components/shared_issue_form.dart';

class AnimalsPage extends StatelessWidget {
  const AnimalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stray Animals Issue"),
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: const SharedIssueForm(
        issueType: "Stray Animals",
        headingText: "Stray animals issue selected",
        infoText:
            "Please give accurate and correct information for a faster solution.",
        imageAsset: "assets/selected.png",
      ),
    );
  }
}
