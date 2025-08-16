import 'dart:developer';

import 'package:flutter/material.dart';

/// 📝 FeedbackPage
/// Allows users to rate the app, leave written feedback, and optionally provide suggestions.
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  FeedbackPageState createState() => FeedbackPageState();
}

class FeedbackPageState extends State<FeedbackPage> with TickerProviderStateMixin {
  // ⭐ User rating value (0.0 to 5.0)
  double _rating = 0.0;

  // 🖊️ Controller for feedback input
  final TextEditingController _feedbackController = TextEditingController();

  // ✅ Checkbox state for suggestions
  bool _suggestions = false;

  // Animation controllers for smooth interactions
  late AnimationController _submitAnimationController;
  late AnimationController _ratingAnimationController;

  @override
  void initState() {
    super.initState();
    _submitAnimationController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _ratingAnimationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _submitAnimationController.dispose();
    _ratingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Feedback'),
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
      ),
      body: Column(
        children: [
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section with emoji and title
                    _buildHeaderSection(),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                    // Rating section
                    _buildRatingSection(),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.025),

                    // Feedback section
                    _buildFeedbackSection(),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                    // Suggestions section
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Fixed submit button at bottom
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: _buildSubmitButton(),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Header section with welcoming design
  Widget _buildHeaderSection() {
    final screenHeight = MediaQuery.of(context).size.height;
    final dynamicPadding = screenHeight * 0.02;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(dynamicPadding.clamp(16.0, 24.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(screenHeight * 0.015),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 4, 204, 240).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              '💬',
              style: TextStyle(fontSize: screenHeight * 0.035),
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          Text(
            'We value your opinion',
            style: TextStyle(
              fontSize: screenHeight * 0.026,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: screenHeight * 0.008),
          Text(
            'Help us improve by sharing your experience',
            style: TextStyle(
              fontSize: screenHeight * 0.018,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// ⭐ Modern rating section
  Widget _buildRatingSection() {
    final screenHeight = MediaQuery.of(context).size.height;
    final dynamicPadding = screenHeight * 0.02;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(dynamicPadding.clamp(16.0, 24.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate your experience',
            style: TextStyle(
              fontSize: screenHeight * 0.02,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          _buildModernRatingBar(),
          if (_rating > 0) ...[
            SizedBox(height: screenHeight * 0.015),
            _buildRatingFeedbackText(),
          ],
        ],
      ),
    );
  }

  /// ⭐ Enhanced star rating with animations
  Widget _buildModernRatingBar() {
    final screenHeight = MediaQuery.of(context).size.height;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        bool isSelected = _rating > index;
        return GestureDetector(
          onTap: () {
            setState(() {
              _rating = index + 1.0;
            });
            _ratingAnimationController.forward().then((_) {
              _ratingAnimationController.reverse();
            });
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.amber.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSelected ? Icons.star : Icons.star_border,
              color: isSelected ? Colors.amber[600] : Colors.grey[400],
              size: screenHeight * 0.035,
            ),
          ),
        );
      }),
    );
  }

  /// 💬 Rating feedback text
  Widget _buildRatingFeedbackText() {
    String feedbackText = '';
    Color textColor = Colors.grey[600]!;

    if (_rating >= 4) {
      feedbackText = 'Awesome! 🎉';
      textColor = Colors.green[600]!;
    } else if (_rating >= 3) {
      feedbackText = 'Good! 👍';
      textColor = Colors.blue[600]!;
    } else if (_rating >= 2) {
      feedbackText = 'Okay 😐';
      textColor = Colors.orange[600]!;
    } else {
      feedbackText = 'We can do better 😔';
      textColor = Colors.red[400]!;
    }

    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: _rating > 0 ? 1.0 : 0.0,
      child: Center(
        child: Text(
          feedbackText,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }

  /// 📝 Modern feedback input section
  Widget _buildFeedbackSection() {
    final screenHeight = MediaQuery.of(context).size.height;
    final dynamicPadding = screenHeight * 0.02;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(dynamicPadding.clamp(16.0, 24.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us more',
            style: TextStyle(
              fontSize: screenHeight * 0.02,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          TextField(
            controller: _feedbackController,
            maxLines: (screenHeight * 0.005).round().clamp(3, 5),
            decoration: InputDecoration(
              hintText: 'Share your thoughts, suggestions, or report issues...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: screenHeight * 0.017,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: const Color.fromARGB(255, 4, 204, 240), width: 2),
              ),
              contentPadding: EdgeInsets.all(screenHeight * 0.02),
            ),
            style: TextStyle(
              color: Colors.black87,
              fontSize: screenHeight * 0.017,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }


  /// 📤 Modern submit button with animation
  Widget _buildSubmitButton() {
    return GestureDetector(
      onTapDown: (_) => _submitAnimationController.forward(),
      onTapUp: (_) => _submitAnimationController.reverse(),
      onTapCancel: () => _submitAnimationController.reverse(),
      onTap: _submitFeedback,
      child: AnimatedBuilder(
        animation: _submitAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_submitAnimationController.value * 0.05),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromARGB(255, 4, 204, 240),
                    const Color.fromARGB(255, 4, 204, 240).withOpacity(0.8)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 4, 204, 240).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                'Submit Feedback',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 🚀 Enhanced feedback submission with modern dialog
  void _submitFeedback() {
    String feedback = _feedbackController.text;
    log('Rating: $_rating');
    log('Feedback: $feedback');
    log('Suggestions: $_suggestions');

    // ✅ Show a modern thank-you dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green[500],
                    size: 48,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Thank You!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Your feedback helps us improve and create a better experience for everyone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context); // Go back to previous screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 4, 204, 240),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
