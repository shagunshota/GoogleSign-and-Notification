import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart'; // Import SQLite helper

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<String> notificationMessages = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final int maxNotifications = 20; // Max number of notifications stored

  @override
  void initState() {
    super.initState();
    _loadNotifications(); // Load stored notifications when the app starts

    FirebaseMessaging.instance.requestPermission();

    FirebaseMessaging.instance.getToken().then((token) {
      print("FCM Token: $token");
    });

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a foreground notification: ${message.notification?.title}');
      String notification = _getNotificationText(message);
      if (notification.isNotEmpty) {
        _addNotification(notification);
      }
    });

    // Handle background and terminated state notifications
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked! ${message.notification?.title}');
      String notification = _getNotificationText(message);
      if (notification.isNotEmpty) {
        _addNotification(notification);
      }
    });
  }

  // Extract notification title and body
  String _getNotificationText(RemoteMessage message) {
    String title = message.notification?.title ?? 'No title';
    String body = message.notification?.body ?? 'No body';
    return "$title\n$body";
  }

  // Load notifications from SQLite
  _loadNotifications() async {
    List<String> storedNotifications = await DatabaseHelper.instance.getNotifications();
    setState(() {
      notificationMessages = storedNotifications.reversed.toList(); // Show newest first
    });
  }

  // Add new notification to SQLite
  _addNotification(String notification) async {
    int count = await DatabaseHelper.instance.getNotificationCount();

    if (count >= maxNotifications) {
      await DatabaseHelper.instance.deleteOldestNotification();
    }

    await DatabaseHelper.instance.insertNotification(notification);
    _loadNotifications(); // Refresh UI
  }

  // Handle background notifications
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling a background message: ${message.notification?.title}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications", style: TextStyle(color: Colors.white, fontSize: 22)),
        backgroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: notificationMessages.isEmpty
                  ? Center(
                child: Text(
                  "No notifications yet.",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: notificationMessages.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: ListTile(
                      leading: Icon(Icons.notifications, color: Colors.blue, size: 28),
                      title: Text(
                        notificationMessages[index],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
