import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

/// LogoWidget
/// A splash/logo animation screen with fade-in and scale-up effects.
/// Includes:
/// - App icon animation
/// - Typewriter text animation for branding
/// - Circular progress indicator with a redirect message
/// - Optional redirect logic (currently simulated)

class LogoWidget extends StatefulWidget {
  const LogoWidget({super.key});

  @override
  LogoWidgetState createState() => LogoWidgetState();
}

class LogoWidgetState extends State<LogoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleUp;

  @override
  void initState() {
    super.initState();

    // 🔧 Initialize animation controller
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    // 🎨 Fade-in animation (opacity from 0 to 1)
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // 🎯 Scale-up animation (icon size from 60% to 100%)
    _scaleUp = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // ▶️ Start the animation
    _controller.forward();

    // Simulating a delay before redirection (Replace this with actual navigation)
    Future.delayed(Duration(seconds: 3), () {
      log("Redirecting to next screen...");
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NextScreen()));
    });
  }

  @override
  void dispose() {
    // ❌ Dispose the controller to avoid memory leaks
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 🖼️ Background color of splash screen
      body: Column(
        children: [
          // 📍 Center animation section
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🌟 Logo Animation: Fade + Scale
                  FadeTransition(
                    opacity: _fadeIn,
                    child: ScaleTransition(
                      scale: _scaleUp,
                      child: Image.asset(
                        'assets/app_icon.png', // 🖼️ App icon
                        width: 150,
                        height: 150,
                      ),
                    ),
                  ),
                  SizedBox(height: 50),

                  // 📝 Animated Typewriter Text
                  AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'NagarVikas',
                        textStyle: GoogleFonts.nunito(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        speed: Duration(milliseconds: 100),
                      ),
                      TypewriterAnimatedText(
                        'Welcome to the Wizarding World 🧙\nEngineered By Prateek Chourasia',
                        textStyle: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                        speed: Duration(milliseconds: 100),
                      ),
                    ],
                    totalRepeatCount: 1, // 🔁 Play animation once
                  ),
                ],
              ),
            ),
          ),

          // 🔁 Loading Indicator & Redirect Text
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: [
                CircularProgressIndicator(
                  color:  Colors.red, // 🔴 Indicator color
                ),
                SizedBox(height: 15),
                Text(
                  "Redirecting to Ministry of Complaints... 🧙‍♂️",
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
     ),
);
}
}
