import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'src/screens/splash_screen.dart';
import 'src/screens/registration_screen.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/patient_home_screen.dart';
import 'src/screens/terms_screen.dart';
import 'src/screens/forgot_password_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await _initializeLocalNotifications(); // Notifications
  _listenToTokenRefresh(); // Auto token updates

  bool isLoggedIn = await checkAuthState();

  if (isLoggedIn) {
    await saveFCMTokenToFirestore(); // Save token right away
  }

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("⏰ Background message: ${message.notification?.title}");
}


// 🔒 Secure login check
Future<bool> checkAuthState() async {
  User? currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser != null) return true;

  const storage = FlutterSecureStorage();
  String? savedEmail = await storage.read(key: 'email');
  String? savedPassword = await storage.read(key: 'password');

  return (savedEmail != null && savedPassword != null);
}

// ✅ Initialize FCM and Local Notifications
Future<void> _initializeLocalNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) {
      debugPrint('Notification tapped with payload: ${response.payload}');
    },
  );

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();

  // ✅ Foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data['route'],
      );
    }
  });

  // ✅ Tapped (background)
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    debugPrint('Tapped (background): ${message.data}');
  });

  // ✅ Tapped (cold start)
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    debugPrint('Tapped (cold start): ${initialMessage.data}');
  }
}

// ✅ Save token to Firestore
Future<void> saveFCMTokenToFirestore() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fcmToken': token,
    });
  }
}

// 🔁 Token refresh handler
void _listenToTokenRefresh() {
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmToken': newToken,
      });
    }
  });
}

// 🧠 Main App
class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pentecost Clinic App',
      theme: ThemeData(
        primaryColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.green[700]),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: SplashScreen(isLoggedIn: isLoggedIn),
      routes: {
        '/register': (context) => const RegistrationScreen(),
        '/login': (context) => const LoginScreen(),
        '/patientHome': (context) => const PatientHomeScreen(),
        '/terms': (context) => const TermsScreen(),
        '/forgotPassword': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}
