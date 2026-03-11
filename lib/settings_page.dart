import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'notification_service.dart';
import 'theme_notifier.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);

  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      final hour = prefs.getInt('notification_hour') ?? 9;
      final minute = prefs.getInt('notification_minute') ?? 0;
      _notificationTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = value;
    });
    await prefs.setBool('notifications_enabled', value);
    if (value) {
      await _notificationService.scheduleDailyBreadNotification();
    } else {
      await _notificationService.flutterLocalNotificationsPlugin.cancelAll();
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    Provider.of<ThemeNotifier>(context, listen: false).setDarkMode(value);
  }

  Future<void> _selectNotificationTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (picked != null && picked != _notificationTime) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationTime = picked;
      });

      await prefs.setInt('notification_hour', picked.hour);
      await prefs.setInt('notification_minute', picked.minute);

      if (_notificationsEnabled) {
        await _notificationService.scheduleDailyBreadNotification();
      }
    }
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bread_history');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bread history cleared'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkModeEnabled = themeNotifier.themeMode == ThemeMode.dark;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Notifications', style: textTheme.bodyMedium),
            subtitle: Text('Get daily bread notifications',
                style: textTheme.bodySmall),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              activeColor: colorScheme.primary,
            ),
          ),
          ListTile(
            title: Text('Notification Time', style: textTheme.bodyMedium),
            subtitle: Text(
              'Daily at ${_notificationTime.format(context)}',
              style: textTheme.bodySmall,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            enabled: _notificationsEnabled,
            onTap: _notificationsEnabled ? _selectNotificationTime : null,
          ),
          const Divider(),
          ListTile(
            title: Text('Dark Mode', style: textTheme.bodyMedium),
            subtitle: Text('Switch to dark theme', style: textTheme.bodySmall),
            trailing: Switch(
              value: isDarkModeEnabled,
              onChanged: _toggleDarkMode,
              activeColor: colorScheme.primary,
            ),
          ),
          const Divider(),
          ListTile(
            title: Text('Clear Bread History',
                style:
                    textTheme.bodyMedium?.copyWith(color: colorScheme.error)),
            subtitle:
                Text('Remove all saved bread data', style: textTheme.bodySmall),
            trailing: Icon(Icons.delete_outline, color: colorScheme.error),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear History?'),
                  content: const Text(
                    'This will clear all your saved bread history. This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () {
                        _clearHistory();
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                      ),
                      child: const Text('CLEAR'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: Text('About Breadify', style: textTheme.bodyMedium),
            subtitle: Text('Version 1.0.0', style: textTheme.bodySmall),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Breadify',
                applicationVersion: '1.0.0',
                applicationIcon: Image.asset(
                  'assets/icons/app_icon.png',
                  height: 50,
                  width: 50,
                ),
                applicationLegalese: '© 2025 Breadify Inc.',
                children: const [
                  SizedBox(height: 16),
                  Text(
                    'Breadify is your daily companion for discovering the wonderful world of bread! Learn about different types of bread from around the world, their history, ingredients, and fun facts.',
                  ),
                ],
              );
            },
          ),
          const Divider(),
          ListTile(
            title: Text('Send Test Notification', style: textTheme.bodyMedium),
            subtitle: Text('Send a test notification now',
                style: textTheme.bodySmall),
            trailing: Icon(Icons.notifications, color: colorScheme.primary),
            onTap: () async {
              await _notificationService.sendTestNotificationNow();
            },
          ),
        ],
      ),
    );
  }
}
