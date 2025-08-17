import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/shared_issue_form.dart';
import '../theme/theme_provider.dart';

class DrainagePage extends StatelessWidget {
  const DrainagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Scaffold(
        backgroundColor:
            themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
        appBar: AppBar(
          title: const Text("Drainage Issue"),
          backgroundColor: const Color.fromARGB(255, 4, 204, 240),
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        body: const SharedIssueForm(
          issueType: "Drainage Issue",
          headingText: "Drainage issue selected",
          infoText:
              "Please give accurate and correct information for a faster solution.",
          imageAsset: "assets/selected.png",
        ),
      );
    });
  }
}
