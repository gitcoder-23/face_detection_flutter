import 'package:face_detection_flutter/firebase_options.dart';
import 'package:face_detection_flutter/pages/dashboard_screen.dart'; // Import the Dashboard screen
import 'package:face_detection_flutter/pages/login_screen.dart';
import 'package:face_detection_flutter/pages/register_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Check if the token is stored in SharedPreferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isTokenAvailable = prefs.getString('auth_token') != null;

  runApp(MyApp(
      isTokenAvailable:
          isTokenAvailable)); // Pass the token availability to the app
}

class MyApp extends StatelessWidget {
  final bool? isTokenAvailable;

  const MyApp({super.key, this.isTokenAvailable});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Face Authenticator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Use conditional navigation based on token availability
      home: isTokenAvailable! ? DashboardScreen() : RegisterScreen(),
    );
  }
}
