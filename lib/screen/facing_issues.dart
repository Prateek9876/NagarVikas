import 'package:flutter/material.dart';
import 'package:nagarvikas/localization/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class FacingIssuesPage extends StatelessWidget {
  const FacingIssuesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('facingIssues')), // Localized string
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: ListView(
          children: [
            _buildSectionTitle(loc.get('commonIssues')), // Localized string
            _buildIssueTile(
              loc.get('appNotOpening'), // Localized string
              loc.get('appNotOpeningDescription'), // Localized string
            ),
            _buildIssueTile(
              loc.get('loginIssues'), // Localized string
              loc.get('loginIssuesDescription'), // Localized string
            ),
            _buildIssueTile(
              loc.get('errorSubmittingComplaint'), // Localized string
              loc.get(
                  'errorSubmittingComplaintDescription'), // Localized string
            ),
            SizedBox(height: 20),
            _buildSectionTitle(
                loc.get('troubleshootingSteps')), // Localized string
            _buildStepTile(
              loc.get('step1RestartApp'), // Localized string
              loc.get('step1RestartAppDescription'), // Localized string
            ),
            _buildStepTile(
              loc.get('step2CheckInternet'), // Localized string
              loc.get('step2CheckInternetDescription'), // Localized string
            ),
            _buildStepTile(
              loc.get('step3ClearCache'), // Localized string
              loc.get('step3ClearCacheDescription'), // Localized string
            ),
            SizedBox(height: 20),
            _buildContactTile(
                context), // Pass context to access AppLocalizations
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildIssueTile(String issue, String solution) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(vertical: 10.0),
      margin: EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.2 * 255).toInt()),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          issue,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        trailing: AnimatedRotation(
          turns: 1.5, // Rotation on click
          duration: Duration(milliseconds: 300),
          child: Icon(
            Icons.arrow_drop_down,
            color: Colors.black87,
            size: 30,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              solution,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile(String step, String description) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(vertical: 10.0),
      margin: EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.2 * 255).toInt()),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          step,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
          textAlign: TextAlign.justify,
        ),
        leading: Icon(
          Icons.check_circle,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildContactTile(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Card(
      color: Colors.amberAccent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(15.0),
        title: Text(
          loc.get('contactSupport'), // Localized string
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          loc.get('contactSupportMessage'), // Localized string
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.black,
        ),
        onTap: () async {
          final String email = "support@nagarvikas.com";
          final String subject =
              loc.get('supportRequestNagarVikas'); // Localized string
          final String body = loc.get('emailBody'); // Localized string

          final Uri emailLaunchUri = Uri(
            scheme: 'mailto',
            path: email,
            queryParameters: {
              'subject': subject,
              'body': body,
            },
          );

          String emailUrl = emailLaunchUri.toString();
          emailUrl =
              emailUrl.replaceAll('+', '%20'); // Fix space encoding for mailto

          try {
            final bool launched = await launchUrl(
              Uri.parse(emailUrl),
              mode: LaunchMode.externalApplication,
            );

            if (!launched) {
              // Fallback to Gmail if direct launch fails
              final fallbackUrl = Uri.parse(
                'https://mail.google.com/mail/?view=cm&fs=1'
                '&to=${Uri.encodeComponent(email)}'
                '&su=${Uri.encodeComponent(subject)}'
                '&body=${Uri.encodeComponent(body)}',
              );

              if (await canLaunchUrl(fallbackUrl)) {
                await launchUrl(fallbackUrl,
                    mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(loc.get(
                          'noEmailAppOrGmailAvailable'))), // Localized string
                );
              }
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      '${loc.get('couldNotLaunch')}$e')), // Localized string
            );
          }
        },
      ),
    );
  }
}
