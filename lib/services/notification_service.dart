import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final ValueNotifier<List<Map<String, dynamic>>> notifications = ValueNotifier([]);

  static Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email");
    if (email == null) return;
    
    final notifStr = prefs.getString("notif_$email");
    if (notifStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(notifStr);
        notifications.value = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {
        notifications.value = [];
      }
    } else {
      notifications.value = [];
    }
  }

  static Future<void> saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email");
    if (email == null) return;
    
    await prefs.setString("notif_$email", jsonEncode(notifications.value));
  }

  static void addNotification(String title, String message) {
    final current = List<Map<String, dynamic>>.from(notifications.value);
    
    current.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'message': message,
      'date': DateTime.now().toIso8601String(),
    });
    
    notifications.value = current;
    saveNotifications();
  }

  static void clearNotifications({bool save = true}) {
    notifications.value = [];
    if (save) saveNotifications();
  }
}
