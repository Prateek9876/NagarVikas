import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatelessWidget {
  final String phoneNumber = "+917307858026";  // Replace with your phone number
  final String email = "support@nagarvikas.com";

  const ContactUsPage({super.key});  // Replace with your support email

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Contact Us"),
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If you have any questions or need assistance, feel free to contact us:',
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
            SizedBox(height: 20),
            _buildContactTile(
              icon: Icons.phone,
              text: phoneNumber,
              onTap: () => _launchPhoneDialer(),
            ),
            SizedBox(height: 20),
            _buildContactTile(
              icon: Icons.email,
              text: email,
              onTap: () => _launchEmailClient(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile({required IconData icon, required String text, required Function onTap}) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Card(
        color: Colors.amberAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(15.0),
          leading: Icon(icon, color: Colors.black, size: 30),
          title: Text(
            text,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
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
