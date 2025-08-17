import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/theme_provider.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  FeedbackPageState createState() => FeedbackPageState();
}

class FeedbackPageState extends State<FeedbackPage> {
  double _rating = 0.0;

  final TextEditingController _feedbackController = TextEditingController();

  bool _suggestions = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Scaffold(
        backgroundColor:
            themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
        appBar: AppBar(
          title: Text('Feedback'),
          backgroundColor: const Color.fromARGB(255, 4, 204, 240),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            children: [
              _buildTitleText('How do you feel about the app?'),
              SizedBox(height: 20),
              _buildRatingBar(),
              SizedBox(height: 25),
              _buildTitleText('Describe your experience: '),
              SizedBox(height: 15),
              _buildFeedbackTextField(),
              SizedBox(height: 25),
              _buildSuggestionsCheckbox(),
              SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTitleText(String text) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
        ),
      );
    });
  }

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

  Widget _buildFeedbackTextField() {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return TextField(
        controller: _feedbackController,
        maxLines: 5,
        decoration: InputDecoration(
          filled: true,
          fillColor:
              themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[200],
          hintText: 'Share your thoughts...',
          hintStyle: TextStyle(
              color:
                  themeProvider.isDarkMode ? Colors.white70 : Colors.black45),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: EdgeInsets.symmetric(
              vertical: 15, horizontal: 15), // Adjusted padding
        ),
        style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black),
      );
    });
  }

  Widget _buildSuggestionsCheckbox() {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
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
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSubmitButton() {
    return Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
    return ElevatedButton(
      onPressed: () {
        _submitFeedback();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        padding: EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      child: Text('Submit Feedback',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: themeProvider.isDarkMode ? Colors.white : Colors.black87)),
    );});
  }

  void _submitFeedback() {
    String feedback = _feedbackController.text;
    log('Rating: $_rating');
    log('Feedback: $feedback');
    log('Suggestions: $_suggestions');

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
