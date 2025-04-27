import 'package:flutter/foundation.dart'; // 👈 for kIsWeb
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  if (kIsWeb) {
    print("🔔 Notifications not initialized on Web.");
    return;
  }

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  print("🔔 Notifications initialized successfully on Mobile.");
}

Future<void> checkAndNotifyLowStock() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print("User is not logged in. Cannot check materials.");
    return;
  }

  final materialsRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('materials');

  final materialsSnapshot = await materialsRef.get();

  for (var doc in materialsSnapshot.docs) {
    final data = doc.data();
    final quantity = data['quantity'] ?? 0;
    final threshold = data['threshold'] ?? 0;
    final name = data['name'] ?? 'Unknown Material';

    if (quantity < threshold) {
      if (!kIsWeb) { // 👈 Only show notification if not Web
        print("🔔 Showing notification for $name");
        await flutterLocalNotificationsPlugin.show(
          doc.hashCode,
          'Low Stock Alert',
          '$name is below the threshold. Tap to place an order.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'low_stock_channel',
              'Low Stock Alerts',
              channelDescription: 'Notifies when material is below threshold',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      } else {
        print("⚡ Web platform detected - skipping local notification for $name");
      }
    }
  }
}
