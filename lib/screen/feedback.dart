import 'package:flutter/material.dart';

/// 📝 FeedbackPage
/// Allows users to rate the app, leave written feedback, and optionally provide suggestions.
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  // ⭐ User rating value (0.0 to 5.0)
  double _rating = 0.0;

  // 🖊️ Controller for feedback input
  final TextEditingController _feedbackController = TextEditingController();

  // ✅ Checkbox state for suggestions
  bool _suggestions = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('feedback') ?? 'Feedback'),
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            _buildTitleText(loc.get('feedbackHowFeel') ?? 'How do you feel about the app?'),
            SizedBox(height: 20),
            _buildRatingBar(),
            SizedBox(height: 25),
            _buildTitleText(loc.get('feedbackDescribe') ?? 'Describe your experience:'),
            SizedBox(height: 15),
            _buildFeedbackTextField(loc),
            SizedBox(height: 25),
            _buildSuggestionsCheckbox(loc),
            SizedBox(height: 30),
            _buildSubmitButton(loc),
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
        hintText: loc.get('feedbackHint') ?? 'Share your thoughts...',
        hintStyle: TextStyle(color: Colors.black45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
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
          loc.get('feedbackSuggestion') ?? 'Would you like to give any suggestion?',
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
        _submitFeedback(loc); // 🧾 Trigger submission logic
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        padding: EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      child: Text(loc.get('feedbackSubmit') ?? 'Submit Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  /// 🚀 Handles feedback submission and shows confirmation
  void _submitFeedback() {
    String feedback = _feedbackController.text;
    print('Rating: $_rating');
    print('Feedback: $feedback');
    print('Suggestions: $_suggestions');

    // ✅ Show a thank-you dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.get('feedbackThankYou') ?? 'Thank You!'),
          content: Text(loc.get('feedbackSubmitted') ?? 'Your feedback has been submitted.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(loc.get('close') ?? 'Close'),
            ),
          ],
        );
     },
);
}
}
