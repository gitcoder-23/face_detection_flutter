import 'package:face_detection_flutter/pages/dashboard_screen.dart';
import 'package:face_detection_flutter/pages/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _controller = CameraController(firstCamera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
    setState(() {});
  }

  Future<void> _registerUser(
      String email, String password, XFile imageFile) async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final inputImage = InputImage.fromFilePath(imageFile.path);
      final faceDetector = GoogleMlKit.vision.faceDetector();
      final faces = await faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        String faceData = await _encodeFaceImage(imageFile);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': email,
          'faceData': faceData,
          'created_at': FieldValue.serverTimestamp(),
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No face detected. Please try again.')),
        );
      }

      await faceDetector.close(); // Important: Close the detector
    } catch (e) {
      print("Error during registration: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    }
  }

  Future<String> _encodeFaceImage(XFile imageFile) async {
    try {
      final File file = File(imageFile.path);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      return base64Image;
    } catch (e) {
      print("Error encoding image: $e");
      return "";
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register Face')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: CameraPreview(_controller),
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
            SizedBox(height: 16),
            IconButton(
              icon: Icon(Icons.camera_alt),
              onPressed: () async {
                try {
                  await _initializeControllerFuture;
                  final image = await _controller.takePicture();
                  _capturedImage = image; // Store the captured image
                } catch (e) {
                  print(e);
                }
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (_emailController.text.isNotEmpty &&
                    _passwordController.text.isNotEmpty &&
                    _capturedImage != null) {
                  _registerUser(_emailController.text, _passwordController.text,
                      _capturedImage!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Please enter all fields and capture a face.')),
                  );
                }
              },
              child: Text('Register'),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text("Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:face_detection_flutter/pages/dashboard_screen.dart';
// import 'package:face_detection_flutter/pages/login_screen.dart'; // Import LoginScreen
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';

// class RegisterScreen extends StatefulWidget {
//   @override
//   _RegisterScreenState createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   late CameraController _controller;
//   late Future<void> _initializeControllerFuture;
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

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

//   Future<void> _registerUser(
//       String email, String password, XFile imageFile) async {
//     try {
//       // Create user using Firebase Authentication
//       final UserCredential userCredential = await FirebaseAuth.instance
//           .createUserWithEmailAndPassword(email: email, password: password);

//       // Process the face data
//       final inputImage = InputImage.fromFilePath(imageFile.path);
//       final faceDetector = GoogleMlKit.vision.faceDetector();
//       final faces = await faceDetector.processImage(inputImage);
//       if (faces.isNotEmpty) {
//         // Store face data (e.g., base64 encoded image or facial features)
//         String faceData = await _encodeFaceImage(imageFile);

//         // Save user data and face data to Firestore
//         await FirebaseFirestore.instance
//             .collection('users')
//             .doc(userCredential.user!.uid)
//             .set({
//           'email': email,
//           'faceData': faceData, // Storing face data
//           'created_at': FieldValue.serverTimestamp(),
//         });

//         // Navigate to the next screen (e.g., dashboard)
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => DashboardScreen()),
//         );
//       }
//     } catch (e) {
//       print("Error during registration: $e");
//     }
//   }

//   Future<String> _encodeFaceImage(XFile imageFile) async {
//     // Encode the image to base64 or store it as a file URL
//     // Here, we assume we encode the image into base64.
//     // For simplicity, use a package like `image` to encode the image
//     // into base64 and store it as face data.
//     return "base64EncodedImageString"; // This should be the actual base64 encoded string
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Register Face')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             // Email Text Field
//             TextField(
//               controller: _emailController,
//               decoration: InputDecoration(
//                 labelText: 'Email',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             SizedBox(height: 16),

//             // Password Text Field
//             TextField(
//               controller: _passwordController,
//               obscureText: true,
//               decoration: InputDecoration(
//                 labelText: 'Password',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             SizedBox(height: 16),

//             // Camera Preview
//             FutureBuilder<void>(
//               future: _initializeControllerFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.done) {
//                   return CameraPreview(_controller);
//                 } else {
//                   return Center(child: CircularProgressIndicator());
//                 }
//               },
//             ),
//             SizedBox(height: 16),

//             // Take Picture Button (Camera Icon)
//             IconButton(
//               icon: Icon(Icons.camera_alt),
//               onPressed: () async {
//                 try {
//                   await _initializeControllerFuture;
//                   final image = await _controller.takePicture();
//                   // Proceed with registration after face detection
//                   _registerUser(
//                       _emailController.text, _passwordController.text, image);
//                 } catch (e) {
//                   print(e);
//                 }
//               },
//             ),
//             SizedBox(height: 16),

//             // Register Button
//             ElevatedButton(
//               onPressed: () async {
//                 try {
//                   if (_emailController.text.isNotEmpty &&
//                       _passwordController.text.isNotEmpty) {
//                     // Proceed with registration after face detection
//                     final image = await _controller.takePicture();
//                     _registerUser(
//                         _emailController.text, _passwordController.text, image);
//                   } else {
//                     // Handle validation or show an error message
//                     print('Please enter both email and password');
//                   }
//                 } catch (e) {
//                   print(e);
//                 }
//               },
//               child: Text('Register'),
//             ),
//             SizedBox(height: 16),

//             // Text below the Register Button to navigate to Login
//             TextButton(
//               onPressed: () {
//                 // Navigate to the login screen when clicked
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (context) => LoginScreen()),
//                 );
//               },
//               child: Text("Already have an account? Login"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'package:face_detection_flutter/pages/dashboard_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';

// class RegisterScreen extends StatefulWidget {
//   @override
//   _RegisterScreenState createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   late CameraController _controller;
//   late Future<void> _initializeControllerFuture;
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

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

//   Future<void> _registerUser(
//       String email, String password, XFile imageFile) async {
//     try {
//       // Create user using Firebase Authentication
//       final UserCredential userCredential = await FirebaseAuth.instance
//           .createUserWithEmailAndPassword(email: email, password: password);

//       // Process the face data
//       final inputImage = InputImage.fromFilePath(imageFile.path);
//       final faceDetector = GoogleMlKit.vision.faceDetector();
//       final faces = await faceDetector.processImage(inputImage);
//       if (faces.isNotEmpty) {
//         // Store face data (e.g., base64 encoded image or facial features)
//         String faceData = await _encodeFaceImage(imageFile);

//         // Save user data and face data to Firestore
//         await FirebaseFirestore.instance
//             .collection('users')
//             .doc(userCredential.user!.uid)
//             .set({
//           'email': email,
//           'faceData': faceData, // Storing face data
//           'created_at': FieldValue.serverTimestamp(),
//         });

//         // Navigate to the next screen (e.g., dashboard)
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => DashboardScreen()),
//         );
//       }
//     } catch (e) {
//       print("Error during registration: $e");
//     }
//   }

//   Future<String> _encodeFaceImage(XFile imageFile) async {
//     // Encode the image to base64 or store it as a file URL
//     // Here, we assume we encode the image into base64.
//     // For simplicity, use a package like `image` to encode the image
//     // into base64 and store it as face data.
//     return "base64EncodedImageString"; // This should be the actual base64 encoded string
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Register Face')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             // Email Text Field
//             TextField(
//               controller: _emailController,
//               decoration: InputDecoration(
//                 labelText: 'Email',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             SizedBox(height: 16),

//             // Password Text Field
//             TextField(
//               controller: _passwordController,
//               obscureText: true,
//               decoration: InputDecoration(
//                 labelText: 'Password',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             SizedBox(height: 16),

//             // Camera Preview
//             FutureBuilder<void>(
//               future: _initializeControllerFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.done) {
//                   return CameraPreview(_controller);
//                 } else {
//                   return Center(child: CircularProgressIndicator());
//                 }
//               },
//             ),
//             SizedBox(height: 16),

//             // Take Picture Button (Camera Icon)
//             IconButton(
//               icon: Icon(Icons.camera_alt),
//               onPressed: () async {
//                 try {
//                   await _initializeControllerFuture;
//                   final image = await _controller.takePicture();
//                   // Proceed with registration after face detection
//                   _registerUser(
//                       _emailController.text, _passwordController.text, image);
//                 } catch (e) {
//                   print(e);
//                 }
//               },
//             ),
//             SizedBox(height: 16),

//             // Register Button
//             ElevatedButton(
//               onPressed: () async {
//                 try {
//                   if (_emailController.text.isNotEmpty &&
//                       _passwordController.text.isNotEmpty) {
//                     // Proceed with registration after face detection
//                     final image = await _controller.takePicture();
//                     _registerUser(
//                         _emailController.text, _passwordController.text, image);
//                   } else {
//                     // Handle validation or show an error message
//                     print('Please enter both email and password');
//                   }
//                 } catch (e) {
//                   print(e);
//                 }
//               },
//               child: Text('Register'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
