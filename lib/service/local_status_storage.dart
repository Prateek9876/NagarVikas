import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStatusStorage {
  static const String _notificationKey = 'user_notifications';
  static const String _adminNotificationKey = 'admin_notifications';

  /// Save a new notification for the user
  static Future<void> saveNotification(Map<String, dynamic> notification) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList(_notificationKey) ?? [];
    notifications.add(jsonEncode(notification));
    await prefs.setStringList(_notificationKey, notifications);
  }

  /// Retrieve all notifications for the user
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList(_notificationKey) ?? [];
    return notifications.map((n) => jsonDecode(n) as Map<String, dynamic>).toList();
  }

  /// Clear all notifications after showing them
  static Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationKey);
  }

  /// Save a new notification for the admin
  static Future<void> saveAdminNotification(Map<String, dynamic> notification) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList(_adminNotificationKey) ?? [];
    notifications.add(jsonEncode(notification));
    await prefs.setStringList(_adminNotificationKey, notifications);
  }

  /// Retrieve all notifications for the admin
  static Future<List<Map<String, dynamic>>> getAdminNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList(_adminNotificationKey) ?? [];
    return notifications.map((n) => jsonDecode(n) as Map<String, dynamic>).toList();
  }

  /// Clear all notifications for the admin
  static Future<void> clearAdminNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adminNotificationKey);
  }
}
