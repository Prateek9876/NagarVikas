import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatelessWidget {
final String phoneNumber = "+917307858026"; // Replace with your phone number
final String email = "support@nagarvikas.com";

const ContactUsPage({super.key}); // Replace with your support email

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: Color(0xFFF9FAFB), // Soft background
appBar: AppBar(
title: Text("Contact Us"),
backgroundColor: const Color.fromARGB(255, 4, 204, 240),
elevation: 0,
iconTheme: IconThemeData(color: Colors.black87),
titleTextStyle: TextStyle(
color: Colors.black87,
fontSize: 22,
fontWeight: FontWeight.bold,
),
),
body: Center(
child: SingleChildScrollView(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
SizedBox(height: 24),
// Top illustration/icon
Container(
decoration: BoxDecoration(
color: Color(0xFF04CCF0).withOpacity(0.12),
shape: BoxShape.circle,
),
padding: EdgeInsets.all(24),
child: Icon(Icons.support_agent_rounded, size: 56, color: Color(0xFF04CCF0)),
),
SizedBox(height: 18),
Text(
'Contact Us',
style: TextStyle(
fontSize: 26,
fontWeight: FontWeight.bold,
color: Colors.black87,
letterSpacing: 0.5,
),
),
SizedBox(height: 10),
Padding(
padding: const EdgeInsets.symmetric(horizontal: 32.0),
child: Text(
'If you have any questions or need assistance, feel free to contact us:',
textAlign: TextAlign.center,
style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500),
),
),
SizedBox(height: 30),
_buildContactTile(
icon: Icons.phone_rounded,
label: 'Call Us',
text: phoneNumber,
onTap: () => _launchPhoneDialer(),
),
SizedBox(height: 18),
_buildContactTile(
icon: Icons.email_rounded,
label: 'Email Us',
text: email,
onTap: () => _launchEmailClient(),
),
SizedBox(height: 36),
],
),
),
),
);
}

Widget _buildContactTile({required IconData icon, required String label, required String text, required Function onTap}) {
return GestureDetector(
onTap: () => onTap(),
child: Card(
color: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(18),
),
elevation: 4,
margin: EdgeInsets.symmetric(horizontal: 32, vertical: 4),
child: Padding(
padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 18.0),
child: Row(
children: [
Container(
decoration: BoxDecoration(
color: Colors.black.withOpacity(0.07),
shape: BoxShape.circle,
),
padding: EdgeInsets.all(13),
child: Icon(icon, color: Colors.black, size: 30),
),
SizedBox(width: 18),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
label,
style: TextStyle(
fontSize: 14,
color: Colors.black54,
fontWeight: FontWeight.w500,
letterSpacing: 0.1,
),
),
SizedBox(height: 2),
Text(
text,
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.w700,
color: Colors.black,
letterSpacing: 0.2,
),
),
],
),
),
],
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
