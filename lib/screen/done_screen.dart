import 'package:flutter/material.dart';

class DoneScreen extends StatefulWidget {
  const DoneScreen({super.key});

  @override
  State<DoneScreen> createState() => _DoneScreenState();
}

class _DoneScreenState extends State<DoneScreen> with TickerProviderStateMixin {
  late AnimationController _overlayController;
  late AnimationController _checkmarkController;
  late Animation<double> _overlayAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkmarkAnimation;
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();

    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _overlayAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _overlayController,
      curve: Curves.elasticOut,
    ));

    _checkmarkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkmarkController,
      curve: Curves.easeInOut,
    ));


    // Then show animation popup after delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showOverlay = true;
        });
        _overlayController.forward();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _checkmarkController.forward();
          }
        });
      }
    });
  }


  void _dismissOverlay() {
    _overlayController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showOverlay = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _overlayController.dispose();
    _checkmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Original Scaffold content
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(backgroundColor: Colors.transparent),
          body: Stack(
            children: [
              // Original content
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/done.png', width: 350, height: 350),
                      const SizedBox(height: 20),
                      const Text(
                        "Done!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "We will get in touch with you if more information is required.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Please note that the estimated time for your issue to be resolved will be 10 to 12 hours. And if you placed complaint between 12PM-8AM then resolving time will start from the next morning ie. After 8AM.\n"
                            "You can check your issue status in the My Complaints tab.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Google Pay style overlay - covers entire screen
        if (_showOverlay)
          AnimatedBuilder(
            animation: _overlayController,
            builder: (context, child) {
              return Container(
                color: Colors.black.withOpacity(0.4 * _overlayAnimation.value),
                child: Center(
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _overlayAnimation.value,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFFFFE),
                              Color(0xFFF8FFFE),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 32,
                              spreadRadius: 0,
                              offset: const Offset(0, 16),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Enhanced animated checkmark circle with gradient
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF4CAF50),
                                    Color(0xFF45A049),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                                    blurRadius: 16,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: AnimatedBuilder(
                                animation: _checkmarkAnimation,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: CheckmarkPainter(_checkmarkAnimation.value),
                                    size: const Size(64, 64),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Clean title typography matching the image
                            const Text(
                              "Complaint Submitted!",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4CAF50),
                                decoration: TextDecoration.none,
                                letterSpacing: -0.2,
                                height: 1.3,
                                fontFamily: 'SF Pro Display', // iOS system font
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Clean body text matching the image style
                            const Text(
                              "Your complaint has been successfully registered. Our team will review it shortly. Thank you for contributing to a better community!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF666666),
                                height: 1.5,
                                decoration: TextDecoration.none,
                                letterSpacing: 0.4,
                                fontFamily: 'SF Pro Text', // iOS system font for body text
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Enhanced button with modern design
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF4CAF50),
                                      Color(0xFF45A049),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4CAF50).withOpacity(0.25),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _dismissOverlay,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: const Text(
                                        "Dismiss",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          decoration: TextDecoration.none,
                                          letterSpacing: 0,
                                          fontFamily: 'SF Pro Text',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class CheckmarkPainter extends CustomPainter {
  final double progress;

  CheckmarkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final checkmarkPath = Path();

    // Define checkmark points
    final startPoint = Offset(center.dx - 10, center.dy);
    final middlePoint = Offset(center.dx - 3, center.dy + 7);
    final endPoint = Offset(center.dx + 10, center.dy - 7);

    if (progress > 0) {
      checkmarkPath.moveTo(startPoint.dx, startPoint.dy);

      if (progress <= 0.5) {
        // First half of checkmark (start to middle)
        final currentPoint = Offset.lerp(
          startPoint,
          middlePoint,
          progress * 2,
        )!;
        checkmarkPath.lineTo(currentPoint.dx, currentPoint.dy);
      } else {
        // Complete first half, then second half
        checkmarkPath.lineTo(middlePoint.dx, middlePoint.dy);
        final currentPoint = Offset.lerp(
          middlePoint,
          endPoint,
          (progress - 0.5) * 2,
        )!;
        checkmarkPath.lineTo(currentPoint.dx, currentPoint.dy);
      }

      canvas.drawPath(checkmarkPath, paint);
    }
  }

  @override
  bool shouldRepaint(CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
