import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/theme_provider.dart';

class ContactUsPage extends StatelessWidget {
  final String phoneNumber = "+917307858026"; // Replace with your phone number
  final String email = "support@nagarvikas.com"; // Replace with your support email

  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Scaffold(
        backgroundColor: themeProvider.isDarkMode
            ? Colors.grey[900]
            : Color(0xFFF9FAFB), // Soft background from HEAD version
        appBar: AppBar(
          title: Text("Contact Us"),
          backgroundColor: const Color.fromARGB(255, 4, 204, 240),
          elevation: 0,
          iconTheme: IconThemeData(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
          ),
          titleTextStyle: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        body: Center(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 6,
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'If you have any questions or need assistance, feel free to contact us:',
                    style: TextStyle(
                      fontSize: 18,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 26),
                  _buildContactTile(
                    context: context,
                    icon: Icons.phone_rounded,
                    text: phoneNumber,
                    onTap: () => _launchPhoneDialer(),
                    themeProvider: themeProvider,
                  ),
                  SizedBox(height: 18),
                  _buildContactTile(
                    context: context,
                    icon: Icons.email_rounded,
                    text: email,
                    onTap: () => _launchEmailClient(),
                    themeProvider: themeProvider,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildContactTile({
    required BuildContext context,
    required IconData icon,
    required String text,
    required Function onTap,
    required ThemeProvider themeProvider,
  }) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Card(
        color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        margin: EdgeInsets.symmetric(vertical: 2),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 18.0),
          leading: Container(
            decoration: BoxDecoration(
              color: Color(0xFF04CCF0).withOpacity(0.13),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.all(8),
            child: Icon(icon, color: Color(0xFF04CCF0), size: 32),
          ),
          title: Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // Function to launch the phone dialer
  _launchPhoneDialer() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneUri';
    }
  }

  // Function to launch the email client
  _launchEmailClient() async {
    final String subject = 'Support Request - Nagar Vikas';
    final String body = 'Hi team,\n\nI need help with ';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    String emailUrl = emailLaunchUri.toString();

    // Replace + with %20 to fix space encoding for mailto
    emailUrl = emailUrl.replaceAll('+', '%20');

    try {
      final bool launched = await launchUrl(
        Uri.parse(emailUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Gmail fallback
        final fallbackUrl = Uri.parse(
          'https://mail.google.com/mail/?view=cm&fs=1'
              '&to=${Uri.encodeComponent(email)}'
              '&su=${Uri.encodeComponent(subject)}'
              '&body=${Uri.encodeComponent(body)}',
        );

        if (await canLaunchUrl(fallbackUrl)) {
          await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
        } else {
          throw 'No email app or Gmail available.';
        }
      }
    } catch (e) {
      debugPrint('Email launch error: $e');
    }
  }
}
