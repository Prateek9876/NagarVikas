// admin_only_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';

class AdminOnlyManager {
  static final DatabaseReference _settingsRef =
      FirebaseDatabase.instance.ref("forum_settings/");
  static final DatabaseReference _usersRef =
      FirebaseDatabase.instance.ref("users/");

  /// Check if current user is a government admin (has .gov email)
  static Future<bool> checkGovAdminStatus(String? userId, bool isAdmin) async {
    if (userId == null || !isAdmin) return false;

    // Allow any admin to toggle admin-only mode
    // Keep the original .gov check as well for backwards compatibility
    try {
      final userSnapshot = await _usersRef.child(userId).once();
      if (userSnapshot.snapshot.exists) {
        final userData =
            Map<String, dynamic>.from(userSnapshot.snapshot.value as Map);
        final email = userData['email'] ?? '';

        // MODIFIED: Allow .gov admins OR any regular admin
        return email.toLowerCase().contains('.gov') || isAdmin;
        // This will return true for:
        // 1. Government admins (.gov email + admin status)
        // 2. Any other admin (regardless of email domain)
      }
    } catch (e) {
      print('Error checking gov admin status: $e');
    }

    // Fallback: if database check fails but user is admin, allow it
    return isAdmin;
  }

  /// Listen to admin-only mode changes
  static StreamSubscription<DatabaseEvent> listenToAdminOnlyMode(
      Function(bool) onModeChanged) {
    return _settingsRef.child("admin_only_mode").onValue.listen((event) {
      final isAdminOnly =
          event.snapshot.exists ? event.snapshot.value as bool : false;
      onModeChanged(isAdminOnly);
    });
  }

  /// Toggle admin-only mode (only for gov admins)
  static void showToggleAdminOnlyDialog({
    required BuildContext context,
    required bool isGovAdmin,
    required bool currentAdminOnlyMode,
    required String? currentUserName,
  }) {
    if (!isGovAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.security, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Only government admins (.gov email) can toggle admin-only mode'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return AlertDialog(
            backgroundColor:
                themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  currentAdminOnlyMode ? Icons.lock_open : Icons.lock,
                  color: currentAdminOnlyMode
                      ? Color(0xFF4CAF50)
                      : Color(0xFFFF9800),
                  size: 24,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentAdminOnlyMode
                        ? 'Disable Admin-Only Mode'
                        : 'Enable Admin-Only Mode',
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentAdminOnlyMode
                      ? 'Are you sure you want to allow all users to send messages again?'
                      : 'Are you sure you want to restrict messaging to admins only? Regular users will not be able to send messages, polls, or media.',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white70
                        : Colors.black87,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (currentAdminOnlyMode
                            ? Color(0xFF4CAF50)
                            : Color(0xFFFF9800))
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (currentAdminOnlyMode
                              ? Color(0xFF4CAF50)
                              : Color(0xFFFF9800))
                          .withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        currentAdminOnlyMode
                            ? Icons.info_outline
                            : Icons.warning_outlined,
                        color: currentAdminOnlyMode
                            ? Color(0xFF4CAF50)
                            : Color(0xFFFF9800),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentAdminOnlyMode
                              ? 'This will restore normal forum functionality for all users.'
                              : 'This will restrict the forum to admin-only communication.',
                          style: TextStyle(
                            color: currentAdminOnlyMode
                                ? Color(0xFF4CAF50)
                                : Color(0xFFFF9800),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _toggleAdminOnlyMode(!currentAdminOnlyMode, currentUserName);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentAdminOnlyMode
                      ? Color(0xFF4CAF50)
                      : Color(0xFFFF9800),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  currentAdminOnlyMode
                      ? 'Allow All Users'
                      : 'Restrict to Admins',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Internal method to toggle admin-only mode in Firebase
  static Future<void> _toggleAdminOnlyMode(
      bool enableAdminOnly, String? adminName) async {
    try {
      await _settingsRef.child("admin_only_mode").set(enableAdminOnly);

      // Log the change for audit purposes
      await _settingsRef.child("admin_only_history").push().set({
        "enabled": enableAdminOnly,
        "changedBy": adminName ?? 'Unknown Admin',
        "timestamp": ServerValue.timestamp,
        "changeType": enableAdminOnly ? "enabled" : "disabled",
      });

      print(
          'Admin-only mode ${enableAdminOnly ? "enabled" : "disabled"} by $adminName');
    } catch (e) {
      print('Error toggling admin-only mode: $e');
    }
  }

  /// Check if user can send messages based on admin-only mode
  static bool canUserSendMessage({
    required bool isAdminOnlyMode,
    required bool isAdmin,
    required bool isUserBanned,
  }) {
    if (isUserBanned) return false;
    if (!isAdminOnlyMode) return true;
    return isAdmin;
  }

  /// Get appropriate message for banned state
  static String getBannedMessage({
    required bool isAdminOnlyMode,
    required bool isAdmin,
    required bool isUserBanned,
  }) {
    if (isUserBanned) {
      return 'You are banned from sending messages';
    } else if (isAdminOnlyMode && !isAdmin) {
      return 'Only admins can send messages in admin-only mode';
    }
    return '';
  }

  /// Get appropriate icon for banned state
  static IconData getBannedIcon({
    required bool isAdminOnlyMode,
    required bool isAdmin,
    required bool isUserBanned,
  }) {
    if (isUserBanned) {
      return Icons.block;
    } else if (isAdminOnlyMode && !isAdmin) {
      return Icons.admin_panel_settings;
    }
    return Icons.block;
  }

  /// Build admin-only mode indicator widget
  static Widget buildAdminOnlyIndicator({
    required BuildContext context,
    required bool isAdminOnlyMode,
    required ThemeProvider themeProvider,
  }) {
    if (!isAdminOnlyMode) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFFFF9800).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFFF9800),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.admin_panel_settings,
            color: Color(0xFFFF9800),
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Admin-Only Mode Active - Only admins can send messages',
              style: TextStyle(
                color: Color(0xFFFF9800),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
