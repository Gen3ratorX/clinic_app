import 'package:clinic_app/src/screens/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'src/screens/splash_screen.dart';
import 'src/screens/registration_screen.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/patient_home_screen.dart';
import 'src/screens/terms_screen.dart';
import 'src/services/notification_service.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize notifications
  await NotificationService().init();

  // Check if user is already logged in
  bool isLoggedIn = await checkAuthState();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

// Function to check if user is already authenticated
Future<bool> checkAuthState() async {
  // Check Firebase Auth state
  User? currentUser = FirebaseAuth.instance.currentUser;

  // If Firebase Auth shows a user is logged in, we can trust that
  if (currentUser != null) {
    return true;
  }

  // If no Firebase user, check secure storage for saved credentials
  const storage = FlutterSecureStorage();
  String? savedEmail = await storage.read(key: 'email');
  String? savedPassword = await storage.read(key: 'password');

  // If we have saved credentials, consider the user logged in
  return (savedEmail != null && savedPassword != null);
}

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
      home: SplashScreen(isLoggedIn: isLoggedIn), // Change here
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
