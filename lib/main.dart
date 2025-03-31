import 'package:flutter/material.dart';

import 'screens/splash_page.dart';
import 'package:camera/camera.dart';

List<CameraDescription> cameras = []; // List to store available cameras

// --- Main Function ---
Future<void> main() async {
  // Ensure Flutter bindings are initialized before using plugins
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Get the list of available cameras
    cameras = await availableCameras();
    print("Available cameras: ${cameras.length}");
  } on CameraException catch (e) {
    print(
        'Error initializing cameras: ${e.code}\nError Message: ${e.description}');
    // Handle the error appropriately if no cameras are found or permissions denied
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}
