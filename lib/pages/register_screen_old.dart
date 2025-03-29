import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class RegisterScreenOld extends StatefulWidget {
  @override
  _RegisterScreenOldState createState() => _RegisterScreenOldState();
}

class _RegisterScreenOldState extends State<RegisterScreenOld> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

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
      // Create user using Firebase Authentication
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Process the face data
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final faceDetector = GoogleMlKit.vision.faceDetector();
      final faces = await faceDetector.processImage(inputImage);
      if (faces.isNotEmpty) {
        // Store face data (e.g., base64 encoded image or facial features)
        String faceData = await _encodeFaceImage(imageFile);

        // Save user data and face data to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': email,
          'faceData': faceData, // Storing face data
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error during registration: $e");
    }
  }

  Future<String> _encodeFaceImage(XFile imageFile) async {
    // Encode the image to base64 or store it as a file URL
    // Here, we assume we encode the image into base64.
    // For simplicity, use a package like `image` to encode the image
    // into base64 and store it as face data.
    return "base64EncodedImageString"; // This should be the actual base64 encoded string
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register Face')),
      body: Column(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _initializeControllerFuture;
                final image = await _controller.takePicture();
                // Proceed with registration after face detection
                _registerUser('user@example.com', 'password123', image);
              } catch (e) {
                print(e);
              }
            },
            child: Text('Capture and Register Face'),
          ),
        ],
      ),
    );
  }
}
