import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:provider/provider.dart';

import '../theme/theme_provider.dart';

/// LogoWidget
/// Enhanced splash screen with realistic animated trees in background
/// Perfect for NagarVikas - a civic complaint app for community development

class LogoWidget extends StatefulWidget {
  const LogoWidget({super.key});

  @override
  LogoWidgetState createState() => LogoWidgetState();
}

class LogoWidgetState extends State<LogoWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _treeController;
  late AnimationController _windController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleUp;
  late Animation<double> _pulse;
  late Animation<double> _slideUp;
  late Animation<double> _progressRotation;
  late Animation<double> _treeSwayAnimation;
  late Animation<double> _windAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _controller = AnimationController(
      duration: Duration(milliseconds: 1800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: Duration(milliseconds: 3000),
      vsync: this,
    );

    // Tree swaying animation (gentle wind effect)
    _treeController = AnimationController(
      duration: Duration(milliseconds: 4000),
      vsync: this,
    );

    // Wind effect for leaves
    _windController = AnimationController(
      duration: Duration(milliseconds: 6000),
      vsync: this,
    );

    // Initialize animations
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _scaleUp = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _slideUp = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _pulse = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _progressRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.linear,
      ),
    );

    // Tree swaying animation - gentle back and forth movement
    _treeSwayAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _treeController,
        curve: Curves.easeInOut,
      ),
    );

    // Wind effect animation
    _windAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _windController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    _controller.forward();

    Future.delayed(Duration(milliseconds: 1500), () {
      _pulseController.repeat(reverse: true);
    });

    Future.delayed(Duration(milliseconds: 2000), () {
      _progressController.repeat();
    });

    // Start tree animations with slight delay for natural effect
    Future.delayed(Duration(milliseconds: 500), () {
      _treeController.repeat(reverse: true);
      _windController.repeat(reverse: true);
    });

    // Simulate redirection
    Future.delayed(Duration(seconds: 3), () {
      log("Redirecting to next screen...");
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NextScreen()));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _treeController.dispose();
    _windController.dispose();
    super.dispose();
  }

  // Create realistic tree with branches and leaves
  Widget _buildRealisticTree({
    required double x,
    required double y,
    required double scale,
    required double swayAmount,
    required int treeType,
  }) {
    return Positioned(
      left: x,
      bottom: y,
      child: Transform.rotate(
        angle: swayAmount * 0.1, // Gentle swaying
        child: Opacity(
          opacity: 0.15 + (scale * 0.1),
          child: CustomPaint(
            size: Size(120 * scale, 200 * scale),
            painter: TreePainter(
              scale: scale,
              windAnimation: _windAnimation.value,
              treeType: treeType,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: context.watch<ThemeProvider>().isDarkMode ? Colors.grey[900] : Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _controller, _pulseController, _progressController,
          _treeController, _windController
        ]),
        builder: (context, child) {
          return Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: context.watch<ThemeProvider>().isDarkMode
                        ? [
                      Colors.grey[900]!,
                      Colors.grey[850]!,
                      Colors.grey[800]!,
                    ]
                        : [
                      const Color(0xFFF8FFFE),
                      const Color(0xFFF0FDF4),
                      Colors.white,
                    ],
                  ),
                ),
              ),

              // Animated trees in background
              ...List.generate(12, (index) {
                final double treeX = (index * (screenWidth * 0.12)) - 80 +
                    (index % 3) * 40;
                final double treeY = -20 + (index % 4) * 15;
                final double treeScale = 0.4 + (index % 3) * 0.2;
                final double swayOffset = (index * 0.3) % 1.0;
                final double swayAmount = _treeSwayAnimation.value *
                    (1.0 + swayOffset) * (0.5 + (index % 3) * 0.3);

                return _buildRealisticTree(
                  x: treeX,
                  y: treeY,
                  scale: treeScale,
                  swayAmount: swayAmount,
                  treeType: index % 3,
                );
              }),

              // Floating leaves particles
              ...List.generate(20, (index) {
                final double leafX = (index * (screenWidth * 0.05)) +
                    (_windAnimation.value * 100) * (index.isEven ? 1 : -1);
                final double leafY = 100 + (index * 25) +
                    (_windAnimation.value * 50) * math.sin(index * 0.5);

                return Positioned(
                  left: leafX,
                  top: leafY,
                  child: Transform.rotate(
                    angle: _windAnimation.value * 6.28 + (index * 0.5),
                    child: Opacity(
                      opacity: 0.3 + (_windAnimation.value * 0.2),
                      child: Container(
                        width: 4 + (index % 3),
                        height: 6 + (index % 3),
                        decoration: BoxDecoration(
                          color: [
                            Colors.green.shade300,
                            Colors.green.shade400,
                            Colors.lightGreen.shade300,
                            Colors.teal.shade200,
                          ][index % 4].withOpacity(0.6),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(3),
                            topRight: Radius.circular(1),
                            bottomLeft: Radius.circular(1),
                            bottomRight: Radius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // Main content
              Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo Animation
                          Transform.translate(
                            offset: Offset(0, _slideUp.value),
                            child: FadeTransition(
                              opacity: _fadeIn,
                              child: ScaleTransition(
                                scale: _scaleUp,
                                child: Transform.scale(
                                  scale: _pulse.value,
                                  child: Container(
                                    width: 170,
                                    height: 170,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.2),
                                          blurRadius: 20,
                                          offset: Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(25),
                                      child: Image.asset(
                                        'assets/app_icon.png',
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 60),

                          // Animated Text
                          Transform.translate(
                            offset: Offset(0, _slideUp.value * 0.5),
                            child: FadeTransition(
                              opacity: _fadeIn,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: AnimatedTextKit(
                                  animatedTexts: [
                                    TypewriterAnimatedText(
                                      'NagarVikas',
                                      textStyle: GoogleFonts.nunito(
                                        fontSize: 35,
                                        fontWeight: FontWeight.bold,
                                        color: context.watch<ThemeProvider>().isDarkMode ? Colors.white : Colors.black87,
                                        letterSpacing: 1.2,
                                      ),
                                      textAlign: TextAlign.center,
                                      speed: Duration(milliseconds: 80),
                                    ),
                                    TypewriterAnimatedText(
                                      'Building Greener Communities 🌱\nEngineered By Prateek Chourasia',
                                      textStyle: GoogleFonts.nunito(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: context.watch<ThemeProvider>().isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                      speed: Duration(milliseconds: 60),
                                    ),
                                  ],
                                  totalRepeatCount: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Loading Indicator
                  Padding(
                    padding: const EdgeInsets.only(bottom: 50),
                    child: Transform.translate(
                      offset: Offset(0, -_slideUp.value * 0.3),
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Transform.rotate(
                                angle: _progressRotation.value * 6.28,
                                child: CircularProgressIndicator(
                                  color: Colors.green,
                                  strokeWidth: 3,
                                  backgroundColor: Colors.green.withOpacity(0.1),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              decoration: BoxDecoration(
                                color: context.watch<ThemeProvider>().isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: context.watch<ThemeProvider>().isDarkMode ? Colors.grey[600]! : Colors.green.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                "Connecting you to better communities... 🌍",
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.watch<ThemeProvider>().isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// Custom painter for realistic trees
class TreePainter extends CustomPainter {
  final double scale;
  final double windAnimation;
  final int treeType;

  TreePainter({
    required this.scale,
    required this.windAnimation,
    required this.treeType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint trunkPaint = Paint()
      ..color = Colors.brown.shade600.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final Paint leavesPaint = Paint()
      ..color = [
        Colors.green.shade400,
        Colors.green.shade500,
        Colors.teal.shade400,
      ][treeType % 3].withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final double centerX = size.width / 2;
    final double baseY = size.height;

    // Draw trunk
    final Rect trunkRect = Rect.fromCenter(
      center: Offset(centerX, baseY - 40 * scale),
      width: 12 * scale,
      height: 80 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(trunkRect, Radius.circular(6 * scale)),
      trunkPaint,
    );

    // Draw main branches with wind effect
    _drawBranch(canvas, centerX, baseY - 80 * scale, -30 * scale, 60 * scale,
        6 * scale, trunkPaint, windAnimation * 0.1);
    _drawBranch(canvas, centerX, baseY - 70 * scale, 25 * scale, 55 * scale,
        5 * scale, trunkPaint, -windAnimation * 0.08);
    _drawBranch(canvas, centerX, baseY - 60 * scale, -20 * scale, 50 * scale,
        4 * scale, trunkPaint, windAnimation * 0.12);

    // Draw tree crown with multiple layers
    final double crownCenterY = baseY - 120 * scale;

    // Back layer
    canvas.drawCircle(
      Offset(centerX + (windAnimation * 8), crownCenterY),
      45 * scale,
      leavesPaint,
    );

    // Middle layer
    canvas.drawCircle(
      Offset(centerX - 15 * scale + (windAnimation * 6), crownCenterY - 10 * scale),
      35 * scale,
      Paint()..color = leavesPaint.color.withOpacity(0.4),
    );

    canvas.drawCircle(
      Offset(centerX + 15 * scale + (windAnimation * 6), crownCenterY - 5 * scale),
      30 * scale,
      Paint()..color = leavesPaint.color.withOpacity(0.4),
    );

    // Front layer
    canvas.drawCircle(
      Offset(centerX + (windAnimation * 5), crownCenterY + 5 * scale),
      40 * scale,
      Paint()..color = leavesPaint.color.withOpacity(0.5),
    );

    // Small leaf clusters
    for (int i = 0; i < 8; i++) {
      final double angle = (i * math.pi / 4) + (windAnimation * 0.5);
      final double radius = 50 * scale;
      final double clusterX = centerX + math.cos(angle) * radius +
          (windAnimation * 3 * (i.isEven ? 1 : -1));
      final double clusterY = crownCenterY + math.sin(angle) * (radius * 0.6);

      canvas.drawCircle(
        Offset(clusterX, clusterY),
        8 * scale + (windAnimation * 2).abs(),
        Paint()..color = leavesPaint.color.withOpacity(0.2),
      );
    }
  }

  void _drawBranch(Canvas canvas, double startX, double startY,
      double endOffsetX, double length, double thickness,
      Paint paint, double windEffect) {
    final Path branchPath = Path();
    branchPath.moveTo(startX, startY);

    // Add wind effect to branch end position
    final double endX = startX + endOffsetX + (windEffect * 10);
    final double endY = startY - length;

    branchPath.quadraticBezierTo(
      startX + (endOffsetX * 0.5),
      startY - (length * 0.3),
      endX,
      endY,
    );

    canvas.drawPath(
      branchPath,
      Paint()
        ..color = paint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(TreePainter oldDelegate) {
    return oldDelegate.windAnimation != windAnimation ||
        oldDelegate.scale != scale;
  }
}
