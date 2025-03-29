import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart'; // Import RegisterScreen

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  // Initialize the camera when the camera icon is clicked
  void _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }
      final firstCamera = cameras.first;
      _controller = CameraController(firstCamera, ResolutionPreset.medium);
      _initializeControllerFuture = _controller.initialize();
      await _initializeControllerFuture;
      setState(() {
        _isCameraInitialized = true; // Mark the camera as initialized
      });
    } catch (e) {
      print('Error initializing camera: $e');
      // Handle the error by notifying the user or showing an error message
    }
  }

  Future<void> _loginUser(String email, String password) async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // After login, proceed to face detection
      _verifyFace(userCredential);
    } catch (e) {
      print("Error during login: $e");
    }
  }

  Future<void> _verifyFace(UserCredential userCredential) async {
    // Fetch the registered face data from Firestore
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();
    String registeredFaceData = userDoc['faceData'];

    // Capture the face again using the camera
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();

      final inputImage = InputImage.fromFilePath(image.path);
      final faceDetector = GoogleMlKit.vision.faceDetector();
      final faces = await faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        // Compare the captured face with the stored face data
        bool isAuthenticated = await _compareFaces(registeredFaceData, image);
        if (isAuthenticated) {
          // Store the Firebase authentication token in SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String? token = await userCredential.user!.getIdToken();
          await prefs.setString('auth_token', token!);

          // Navigate to the dashboard screen if faces match
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          );
        } else {
          // Show an error if faces don't match
          print("Face verification failed.");
        }
      }
    } catch (e) {
      print("Error during face verification: $e");
    }
  }

  Future<bool> _compareFaces(String registeredFaceData, XFile imageFile) async {
    // Here, you would compare the captured face with the stored face data (e.g., via face recognition API)
    // For simplicity, this is a placeholder function.
    // You can use a custom method to match faces or use APIs like AWS Rekognition or Firebase ML.
    return registeredFaceData ==
        "base64EncodedCapturedImage"; // Implement real comparison logic
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _loginUser(
                    _emailController.text, _passwordController.text);
              },
              child: Text('Login'),
            ),
            SizedBox(height: 16),

            // Camera Icon Button - Initialize camera when clicked
            IconButton(
              icon: Icon(Icons.camera_alt),
              onPressed: () async {
                if (!_isCameraInitialized) {
                  // Initialize the camera if it's not already initialized
                  _initializeCamera();
                } else {
                  // You can add your face detection logic here after the camera is initialized
                  print("Camera initialized, ready for face detection");
                }
              },
            ),
            SizedBox(height: 16),

            // Text below the Login Button to navigate to Register
            TextButton(
              onPressed: () {
                // Navigate to the register screen when clicked
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: Text("Do not have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dashboard_screen.dart';
// import 'register_screen.dart'; // Import RegisterScreen

// class LoginScreen extends StatefulWidget {
//   @override
//   _LoginScreenState createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   late CameraController _controller;
//   late Future<void> _initializeControllerFuture;

//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//   }

//   void _initializeCamera() async {
//     try {
//       final cameras = await availableCameras();
//       if (cameras.isEmpty) {
//         throw Exception('No cameras available');
//       }
//       final firstCamera = cameras.first;
//       _controller = CameraController(firstCamera, ResolutionPreset.medium);
//       _initializeControllerFuture = _controller.initialize();
//       setState(() {});
//     } catch (e) {
//       print('Error initializing camera: $e');
//       // Handle the error by notifying the user or showing an error message
//     }
//   }

//   Future<void> _loginUser(String email, String password) async {
//     try {
//       final UserCredential userCredential = await FirebaseAuth.instance
//           .signInWithEmailAndPassword(email: email, password: password);

//       // After login, proceed to face detection
//       _verifyFace(userCredential);
//     } catch (e) {
//       print("Error during login: $e");
//     }
//   }

//   Future<void> _verifyFace(UserCredential userCredential) async {
//     // Fetch the registered face data from Firestore
//     DocumentSnapshot userDoc = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(userCredential.user!.uid)
//         .get();
//     String registeredFaceData = userDoc['faceData'];

//     // Capture the face again using the camera
//     try {
//       await _initializeControllerFuture;
//       final image = await _controller.takePicture();

//       final inputImage = InputImage.fromFilePath(image.path);
//       final faceDetector = GoogleMlKit.vision.faceDetector();
//       final faces = await faceDetector.processImage(inputImage);

//       if (faces.isNotEmpty) {
//         // Compare the captured face with the stored face data
//         bool isAuthenticated = await _compareFaces(registeredFaceData, image);
//         if (isAuthenticated) {
//           // Store the Firebase authentication token in SharedPreferences
//           SharedPreferences prefs = await SharedPreferences.getInstance();
//           String? token = await userCredential.user!.getIdToken();
//           await prefs.setString('auth_token', token!);

//           // Navigate to the dashboard screen if faces match
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => DashboardScreen()),
//           );
//         } else {
//           // Show an error if faces don't match
//           print("Face verification failed.");
//         }
//       }
//     } catch (e) {
//       print("Error during face verification: $e");
//     }
//   }

//   Future<bool> _compareFaces(String registeredFaceData, XFile imageFile) async {
//     // Here, you would compare the captured face with the stored face data (e.g., via face recognition API)
//     // For simplicity, this is a placeholder function.
//     // You can use a custom method to match faces or use APIs like AWS Rekognition or Firebase ML.
//     return registeredFaceData ==
//         "base64EncodedCapturedImage"; // Implement real comparison logic
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Login')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: _emailController,
//               decoration: InputDecoration(labelText: 'Email'),
//             ),
//             TextField(
//               controller: _passwordController,
//               obscureText: true,
//               decoration: InputDecoration(labelText: 'Password'),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 await _loginUser(
//                     _emailController.text, _passwordController.text);
//               },
//               child: Text('Login'),
//             ),
//             SizedBox(height: 16),

//             // Text below the Login Button to navigate to Register
//             TextButton(
//               onPressed: () {
//                 // Navigate to the register screen when clicked
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => RegisterScreen()),
//                 );
//               },
//               child: Text("Do not have an account? Register"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dashboard_screen.dart';
// import 'register_screen.dart'; // Import the RegisterScreen

// class LoginScreen extends StatefulWidget {
//   @override
//   _LoginScreenState createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   late CameraController _controller;
//   late Future<void> _initializeControllerFuture;

//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//   }

//   void _initializeCamera() async {
//     final cameras = await availableCameras();
//     final firstCamera = cameras.first;
//     _controller = CameraController(firstCamera, ResolutionPreset.medium);
//     _initializeControllerFuture = _controller.initialize();
//     setState(() {});
//   }

//   Future<void> _loginUser(String email, String password) async {
//     try {
//       final UserCredential userCredential = await FirebaseAuth.instance
//           .signInWithEmailAndPassword(email: email, password: password);

//       // After login, proceed to face detection
//       _verifyFace(userCredential);
//     } catch (e) {
//       print("Error during login: $e");
//     }
//   }

//   Future<void> _verifyFace(UserCredential userCredential) async {
//     // Fetch the registered face data from Firestore
//     DocumentSnapshot userDoc = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(userCredential.user!.uid)
//         .get();
//     String registeredFaceData = userDoc['faceData'];

//     // Capture the face again using the camera
//     try {
//       await _initializeControllerFuture;
//       final image = await _controller.takePicture();

//       final inputImage = InputImage.fromFilePath(image.path);
//       final faceDetector = GoogleMlKit.vision.faceDetector();
//       final faces = await faceDetector.processImage(inputImage);

//       if (faces.isNotEmpty) {
//         // Compare the captured face with the stored face data
//         bool isAuthenticated = await _compareFaces(registeredFaceData, image);
//         if (isAuthenticated) {
//           // Store the Firebase authentication token in SharedPreferences
//           SharedPreferences prefs = await SharedPreferences.getInstance();
//           String? token = await userCredential.user!.getIdToken();
//           await prefs.setString('auth_token', token!);

//           // Navigate to the dashboard screen if faces match
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => DashboardScreen()),
//           );
//         } else {
//           // Show an error if faces don't match
//           print("Face verification failed.");
//         }
//       }
//     } catch (e) {
//       print("Error during face verification: $e");
//     }
//   }

//   Future<bool> _compareFaces(String registeredFaceData, XFile imageFile) async {
//     // Here, you would compare the captured face with the stored face data (e.g., via face recognition API)
//     // For simplicity, this is a placeholder function.
//     // You can use a custom method to match faces or use APIs like AWS Rekognition or Firebase ML.
//     return registeredFaceData ==
//         "base64EncodedCapturedImage"; // Implement real comparison logic
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Login')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: _emailController,
//               decoration: InputDecoration(labelText: 'Email'),
//             ),
//             TextField(
//               controller: _passwordController,
//               obscureText: true,
//               decoration: InputDecoration(labelText: 'Password'),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 await _loginUser(
//                     _emailController.text, _passwordController.text);
//               },
//               child: Text('Login'),
//             ),
//             SizedBox(height: 16),

//             // Text below the Login Button to navigate to Register
//             TextButton(
//               onPressed: () {
//                 // Navigate to the register screen when clicked
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => RegisterScreen()),
//                 );
//               },
//               child: Text("Do not have an account? Register"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dashboard_screen.dart';

// class LoginScreen extends StatefulWidget {
//   @override
//   _LoginScreenState createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   late CameraController _controller;
//   late Future<void> _initializeControllerFuture;

//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//   }

//   void _initializeCamera() async {
//     final cameras = await availableCameras();
//     final firstCamera = cameras.first;
//     _controller = CameraController(firstCamera, ResolutionPreset.medium);
//     _initializeControllerFuture = _controller.initialize();
//     setState(() {});
//   }

//   Future<void> _loginUser(String email, String password) async {
//     try {
//       final UserCredential userCredential = await FirebaseAuth.instance
//           .signInWithEmailAndPassword(email: email, password: password);

//       // After login, proceed to face detection
//       _verifyFace(userCredential);
//     } catch (e) {
//       print("Error during login: $e");
//     }
//   }

//   Future<void> _verifyFace(UserCredential userCredential) async {
//     // Fetch the registered face data from Firestore
//     DocumentSnapshot userDoc = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(userCredential.user!.uid)
//         .get();
//     String registeredFaceData = userDoc['faceData'];

//     // Capture the face again using the camera
//     try {
//       await _initializeControllerFuture;
//       final image = await _controller.takePicture();

//       final inputImage = InputImage.fromFilePath(image.path);
//       final faceDetector = GoogleMlKit.vision.faceDetector();
//       final faces = await faceDetector.processImage(inputImage);

//       if (faces.isNotEmpty) {
//         // Compare the captured face with the stored face data
//         bool isAuthenticated = await _compareFaces(registeredFaceData, image);
//         if (isAuthenticated) {
//           // Store the Firebase authentication token in SharedPreferences
//           SharedPreferences prefs = await SharedPreferences.getInstance();
//           String? token = await userCredential.user!.getIdToken();
//           await prefs.setString('auth_token', token!);

//           // Navigate to the dashboard screen if faces match
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => DashboardScreen()),
//           );
//         } else {
//           // Show an error if faces don't match
//           print("Face verification failed.");
//         }
//       }
//     } catch (e) {
//       print("Error during face verification: $e");
//     }
//   }

//   Future<bool> _compareFaces(String registeredFaceData, XFile imageFile) async {
//     // Here, you would compare the captured face with the stored face data (e.g., via face recognition API)
//     // For simplicity, this is a placeholder function.
//     // You can use a custom method to match faces or use APIs like AWS Rekognition or Firebase ML.
//     return registeredFaceData ==
//         "base64EncodedCapturedImage"; // Implement real comparison logic
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Login')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: _emailController,
//               decoration: InputDecoration(labelText: 'Email'),
//             ),
//             TextField(
//               controller: _passwordController,
//               obscureText: true,
//               decoration: InputDecoration(labelText: 'Password'),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 await _loginUser(
//                     _emailController.text, _passwordController.text);
//               },
//               child: Text('Login'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
