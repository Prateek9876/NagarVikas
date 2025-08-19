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
      appBar: AppBar(
        title: Text('Feedback'),
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            _buildTitleText('How do you feel about the app?'),
            SizedBox(height: 20), // 📏 Space between title and stars
            _buildRatingBar(),
            SizedBox(height: 25), // 📏 Space between rating and next title
            _buildTitleText('Describe your experience:'),
            SizedBox(height: 15), // 📏 Space before feedback field
            _buildFeedbackTextField(),
            SizedBox(height: 25), // 📏 Space before checkbox
            _buildSuggestionsCheckbox(),
            SizedBox(height: 30), // 📏 Space before submit button
            _buildSubmitButton(),
          ],
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
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            Icons.star,
            color: _rating > index ? Colors.amber : Colors.grey,
            size: 35,
          ),
          onPressed: () {
            setState(() {
              _rating = index + 1.0;
            });
          },
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
        fillColor: Colors.grey[200],
        hintText: 'Share your thoughts...',
        hintStyle: TextStyle(color: Colors.black45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: EdgeInsets.symmetric(
            vertical: 15, horizontal: 15), // Adjusted padding
      ),
      style: TextStyle(color: Colors.black),
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
          activeColor: Colors.amber,
        ),
        Text(
          'Would you like to give any suggestion?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  /// 📤 Submit button to process the feedback
  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () {
        _submitFeedback(); // 🧾 Trigger submission logic
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        padding: EdgeInsets.symmetric(vertical: 18), // Adjusted padding
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      child: Text('Submit Feedback',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
