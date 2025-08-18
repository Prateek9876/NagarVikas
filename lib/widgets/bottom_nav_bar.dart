import 'package:nagarvikas/screen/profile_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:nagarvikas/screen/issue_selection.dart';
import 'package:nagarvikas/screen/my_complaints.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<Widget> _pages = [
    IssueSelectionPage(),
    MyComplaintsScreen(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeInQuart,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getPrimaryColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF00E5FF) : const Color(0xFF00ACC1);
  }

  Color _getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1E1E1E) : Colors.white;
  }

  Color _getSurfaceColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8F9FA);
  }

  Color _getTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFE0E0E0) : const Color(0xFF2E3440);
  }

  Color _getInactiveIconColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF888888) : const Color(0xFF6B7280);
  }

  List<BoxShadow> _getNavBarShadows(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 25,
          offset: const Offset(0, -2),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: _getPrimaryColor(context).withOpacity(0.1),
          blurRadius: 15,
          offset: const Offset(0, -1),
          spreadRadius: 0,
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: const Color(0xFF000000).withOpacity(0.08),
          blurRadius: 28,
          offset: const Offset(0, -4),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: const Color(0xFF000000).withOpacity(0.12),
          blurRadius: 12,
          offset: const Offset(0, -2),
          spreadRadius: 0,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getPrimaryColor(context);
    final backgroundColor = _getBackgroundColor(context);
    final surfaceColor = _getSurfaceColor(context);
    final textColor = _getTextColor(context);
    final inactiveIconColor = _getInactiveIconColor(context);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages.map((page) => 
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: page,
              );
            },
          ),
        ).toList(),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor.withOpacity(0.85),
                borderRadius: BorderRadius.circular(28),
                boxShadow: _getNavBarShadows(context),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  width: 0.5,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: GNav(
                    rippleColor: primaryColor.withOpacity(0.1),
                    hoverColor: primaryColor.withOpacity(0.05),
                    gap: 8,
                    activeColor: primaryColor,
                    iconSize: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    tabBackgroundColor: primaryColor.withOpacity(0.12),
                    color: inactiveIconColor,
                    textStyle: GoogleFonts.urbanist(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: primaryColor,
                      letterSpacing: 0.2,
                      height: 1.0,
                    ),
                    tabBorderRadius: 20,
                    tabMargin: const EdgeInsets.all(0),
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    tabs: [
                      GButton(
                        icon: CupertinoIcons.house_fill,
                        text: 'Home',
                        iconActiveColor: primaryColor,
                        iconColor: inactiveIconColor,
                        textColor: primaryColor,
                        textSize: 15,
                        iconSize: 26,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      GButton(
                        icon: CupertinoIcons.doc_text_fill,
                        text: 'Records',
                        iconActiveColor: primaryColor,
                        iconColor: inactiveIconColor,
                        textColor: primaryColor,
                        textSize: 15,
                        iconSize: 26,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      GButton(
                        icon: CupertinoIcons.person_circle_fill,
                        text: 'Profile',
                        iconActiveColor: primaryColor,
                        iconColor: inactiveIconColor,
                        textColor: primaryColor,
                        textSize: 15,
                        iconSize: 26,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ],
                    selectedIndex: _selectedIndex,
                    onTabChange: (index) {
                      if (index != _selectedIndex) {
                        // Haptic feedback
                        HapticFeedback.selectionClick();
                        
                        // Quick animation
                        _animationController.forward().then((_) {
                          setState(() {
                            _selectedIndex = index;
                          });
                          _animationController.reverse();
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Optional: Add this extension for additional theme colors
extension ThemeExtension on ThemeData {
  Color get navBarBackground => brightness == Brightness.dark 
      ? const Color(0xFF1E1E1E) 
      : Colors.white;
      
  Color get navBarSurface => brightness == Brightness.dark 
      ? const Color(0xFF2D2D2D) 
      : const Color(0xFFF8F9FA);
      
  Color get primaryAccent => brightness == Brightness.dark 
      ? const Color(0xFF00E5FF) 
      : const Color(0xFF00ACC1);
}