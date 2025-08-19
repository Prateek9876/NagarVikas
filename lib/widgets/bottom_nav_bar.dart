import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:nagarvikas/screen/issue_selection.dart';
import 'package:nagarvikas/screen/my_complaints.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nagarvikas/screen/profile_screen.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    IssueSelectionPage(),
    MyComplaintsScreen(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final activeColor = Colors.tealAccent;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withAlpha((0.5 * 255).toInt())
                  : Colors.grey.withAlpha((0.2 * 255).toInt()),
              blurRadius: 20,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: activeColor,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: activeColor.withAlpha((0.15 * 255).toInt()),
              color: textColor,
              textStyle: GoogleFonts.urbanist(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: textColor,
              ),
              tabs: const [
                GButton(
                  icon: CupertinoIcons.home,
                  text: 'Home',
                ),
                GButton(
                  icon: CupertinoIcons.doc_text,
                  text: 'Spell Records',
                ),
                GButton(
                  icon: CupertinoIcons.profile_circled,
                  text: 'About',
                ),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
