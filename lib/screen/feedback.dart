import 'dart:developer';

import 'package:flutter/material.dart';

/// 📝 FeedbackPage
/// Allows users to rate the app, leave written feedback, and optionally provide suggestions.
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  FeedbackPageState createState() => FeedbackPageState();
}

class FeedbackPageState extends State<FeedbackPage> {
  // ⭐ User rating value (0.0 to 5.0)
  double _rating = 0.0;

  // 🖊️ Controller for feedback input
  final TextEditingController _feedbackController = TextEditingController();

  // ✅ Checkbox state for suggestions
  bool _suggestions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB), // Soft background
      appBar: AppBar(
        title: Text('Feedback'),
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
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 6,
          margin: EdgeInsets.symmetric(horizontal: 0, vertical: 24),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28),
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildTitleText('How do you feel about the app?'),
                SizedBox(height: 18),
                _buildRatingBar(),
                SizedBox(height: 28),
                _buildTitleText('Describe your experience:'),
                SizedBox(height: 12),
                _buildFeedbackTextField(),
                SizedBox(height: 20),
                _buildSuggestionsCheckbox(),
                SizedBox(height: 28),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🧾 Returns a styled title text widget
  Widget _buildTitleText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  /// ⭐ Builds a custom star rating bar (1–5)
  Widget _buildRatingBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.5),
          child: IconButton(
            icon: Icon(
              _rating > index ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _rating > index ? Colors.amber[700] : Colors.grey[400],
              size: 36,
            ),
            splashRadius: 24,
            onPressed: () {
              setState(() {
                _rating = index + 1.0;
              });
            },
          ),
        );
      }),
    );
  }

  /// 📝 Multiline text field for user feedback input
  Widget _buildFeedbackTextField() {
    return TextField(
      controller: _feedbackController,
      maxLines: 5,
      decoration: InputDecoration(
        filled: true,
        fillColor: Color(0xFFF5F6FA),
        hintText: 'Share your thoughts...',
        hintStyle: TextStyle(color: Colors.black38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Color(0xFF04CCF0), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Color(0xFF04CCF0), width: 1.6),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      ),
      style: TextStyle(color: Colors.black87, fontSize: 16),
    );
  }

  /// ✅ Checkbox for user to indicate if they have suggestions
  Widget _buildSuggestionsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _suggestions,
          onChanged: (bool? value) {
            setState(() {
              _suggestions = value ?? false;
            });
          },
          activeColor: Color(0xFF04CCF0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        Flexible(
          child: Text(
            'Would you like to give any suggestion?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  /// 📤 Submit button to process the feedback
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _submitFeedback();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        child: Text('Submit Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  /// 🚀 Handles feedback submission and shows confirmation
  void _submitFeedback() {
    String feedback = _feedbackController.text;

    log('Rating: $_rating');
    log('Feedback: $feedback');
    log('Suggestions: $_suggestions');

    // ✅ Show a thank-you dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Thank You!'),
          content: Text('Your feedback has been submitted.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close'),
            ),
          ],
        );
     },
);
}
}
