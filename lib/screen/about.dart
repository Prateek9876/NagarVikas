import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/theme_provider.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Scaffold(
        backgroundColor:
            themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
        appBar: AppBar(
          title: Text('About the App'),
          backgroundColor: const Color.fromARGB(255, 4, 204, 240),
        ),
        body: Padding(
          padding: EdgeInsets.all(20.0),
          child: ListView(
            children: [
              _buildQuestionTile(
                'What is NagarVikas?',
                'NagarVikas is a civic issue complaint application designed to bridge the gap between citizens and municipal authorities. It allows citizens to easily report and track the resolution of civic issues like garbage disposal, potholes, water supply issues, and more.',
              ),
              _buildQuestionTile(
                'What do we do?',
                'We provide an easy and convenient platform for reporting civic issues, enabling the authorities to act on them promptly. Our mission is to make urban living cleaner and more efficient by empowering citizens to take action on the problems they encounter.',
              ),
              _buildQuestionTile(
                'What do we offer?',
                'Our app offers a variety of services, including issue reporting, live status tracking, and automated notifications. You can submit complaints about various civic problems, track the progress, and receive updates on the resolution.',
              ),
              _buildQuestionTile(
                'What are the features of NagarVikas?',
                '• Easy complaint submission\n• Track complaint status in real time\n• Notifications and reminders for pending issues\n• User-friendly interface\n• Fast and reliable issue resolution system',
              ),
              _buildQuestionTile(
                'Who developed NagarVikas?',
                'nagarvikas was developed by a passionate team aiming to improve civic engagement and urban infrastructure. We believe technology can solve problems more efficiently and make a positive impact on the community.',
              ),
              _buildQuestionTile(
                'How can I contact you?',
                'For more information or support, feel free to reach out to us at support@nagarvikas.com. We value your feedback and are always here to help.',
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildQuestionTile(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: _ExpandableTile(
        question: question,
        answer: answer,
      ),
    );
  }
}

class _ExpandableTile extends StatefulWidget {
  final String question;
  final String answer;

  const _ExpandableTile({
    required this.question,
    required this.answer,
  });

  @override
  State<_ExpandableTile> createState() => _ExpandableTileState();
}

class _ExpandableTileState extends State<_ExpandableTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: themeProvider.isDarkMode
                  ? Colors.black26
                  : Colors.grey.withAlpha((0.2 * 255).toInt()),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          title: Text(
            widget.question,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          trailing: AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0.0,
            duration: Duration(milliseconds: 300),
            child: Icon(
              Icons.arrow_drop_down,
              color: Colors.black87,
              size: 30,
            ),
          ),
          children: [
            AnimatedSize(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  widget.answer,
                  style: TextStyle(
                    fontSize: 16,
                    color: themeProvider.isDarkMode
                        ? Colors.white70
                        : Colors.black54,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
