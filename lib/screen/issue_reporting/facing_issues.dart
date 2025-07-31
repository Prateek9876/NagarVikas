import 'package:flutter/material.dart';

class FacingIssuesPage extends StatelessWidget {
  const FacingIssuesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Facing Issues?'),
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: ListView(
          children: [
            _buildSectionTitle('Common Issues'),
            _buildIssueTile(
              'App not opening',
              'If the app is not opening, try restarting your phone or reinstalling the app. Ensure you have a stable internet connection.',
            ),
            _buildIssueTile(
              'Login issues',
              'If you’re facing issues with logging in, make sure your internet connection is stable and you are using the correct login credentials. If you forgot your password, use the "Forgot Password" option.',
            ),
            _buildIssueTile(
              'Error in submitting complaint',
              'If the complaint submission fails, please check your internet connection and ensure all required fields are filled. Try restarting the app and submitting again.',
            ),
            SizedBox(height: 20),
            _buildSectionTitle('Troubleshooting Steps'),
            _buildStepTile(
              'Step 1: Restart the app',
              'Close the app completely and reopen it. This can resolve most of the temporary issues.',
            ),
            _buildStepTile(
              'Step 2: Check your internet connection',
              'Ensure you are connected to a stable internet connection (WiFi or mobile data) to avoid connectivity-related issues.',
            ),
            _buildStepTile(
              'Step 3: Clear app cache',
              'Sometimes clearing the app’s cache can solve performance issues. Go to your phone’s settings, find the app, and clear the cache.',
            ),
            SizedBox(height: 20),
            _buildSectionTitle('Need Help?'),
            _buildContactTile(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
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

  Widget _buildContactTile() {
    return Card(
      color: Colors.amberAccent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(15.0),
        title: Text(
          'Contact Support',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          'If the issue persists, please contact our support team for further assistance.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward,
          color: Colors.black,
        ),
        onTap: () {
          // Open contact support page (or email)
        },
     ),
);
}
}
