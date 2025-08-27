// admin_drawer.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../theme/theme_provider.dart';
import 'discussion/banned_users_dashboard.dart';
import 'discussion/discussion.dart';
import 'favourites.dart';
import 'login_page.dart';
import 'package:nagarvikas/screen/analytics_dashboard.dart';

import 'message_reports_dashboard.dart';

class AdminDrawer extends StatefulWidget {
  final List<Map<String, dynamic>> favoriteComplaints;
  final Function(Map<String, dynamic>) onRemoveFavorite;

  const AdminDrawer({
    super.key,
    required this.favoriteComplaints,
    required this.onRemoveFavorite,
  });

  @override
  AdminDrawerState createState() => AdminDrawerState();
}

class AdminDrawerState extends State<AdminDrawer> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final List<DrawerItem> _menuItems = [
    DrawerItem(
      icon: Icons.analytics_rounded,
      title: 'Analytics',
      color: const Color(0xFF00BCD4),
    ),
    DrawerItem(
      icon: Icons.forum_rounded,
      title: 'Discussion Forum',
      color: const Color(0xFF2196F3),
    ),
    DrawerItem(
      icon: Icons.report,
      title: 'Message Reports',
      color: const Color(0xFF2196F3),
    ),
    DrawerItem(
      icon: Icons.block_rounded,
      title: 'Banned Users',
      color: const Color(0xFFFF9800),
    ),
    DrawerItem(
      icon: Icons.favorite_rounded,
      title: 'Favorites',
      color: const Color(0xFFE91E63),
    ),
    DrawerItem(
      icon: Icons.logout_rounded,
      title: 'Logout',
      color: const Color(0xFFFF6B6B),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
  }

  void _startAnimations() {
    _slideController.forward();
    Timer(const Duration(milliseconds: 200), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = themeProvider.isDarkMode;

        return SlideTransition(
          position: _slideAnimation,
          child: Drawer(
            backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
            child: Column(
              children: [
                _buildHeader(isDarkMode),
                const SizedBox(height: 20),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildMenuItems(isDarkMode, themeProvider),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.only(top: 50, bottom: 30),
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 800),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: Color(0xFF00BCD4),
                size: 35,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Admin Panel',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'amritsar.gov@gmail.com',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItems(bool isDarkMode, ThemeProvider themeProvider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        final isLogout = index == _menuItems.length - 1;

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 80)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(20 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 22,
                ),
              ),
              title: Text(
                item.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              trailing: Icon(
                isLogout ? Icons.power_settings_new_rounded : Icons.arrow_forward_ios_rounded,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                size: isLogout ? 20 : 16,
              ),
              onTap: () => _handleMenuTap(index, themeProvider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleMenuTap(int index, ThemeProvider themeProvider) {
    switch (index) {
      case 0: // Analytics
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const AnalyticsDashboard(),
        ));
        break;
      case 1: // Discussion Forum
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const DiscussionForum(isAdmin: true),
        ));
        break;
      case 2: // Message Reports
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const MessageReportsDashboard(),
        ));
        break;
      case 3: // Banned Users
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const BannedUsersDashboard(),
        ));
        break;
      case 4: // Favorites
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => FavoritesPage(
            favoriteComplaints: widget.favoriteComplaints,
            onRemoveFavorite: widget.onRemoveFavorite,
          ),
        ));
        break;
      case 5: // Logout
        _showLogoutDialog(themeProvider);
        break;
    }
  }

  void _showLogoutDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[850] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFFF6B6B),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Logout",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to logout from your admin account?",
          style: TextStyle(
            fontSize: 15,
            color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _handleLogout(themeProvider),
            child: const Text(
              "Logout",
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(ThemeProvider themeProvider) async {
    Navigator.of(context).pop();

    // Show simple loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[850] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF00BCD4)),
            const SizedBox(height: 16),
            Text(
              "Signing out...",
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;

      Navigator.of(context).pop(); // Close loading dialog
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to logout. Please try again."),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}

class DrawerItem {
  final IconData icon;
  final String title;
  final Color color;

  DrawerItem({
    required this.icon,
    required this.title,
    required this.color,
  });
}
