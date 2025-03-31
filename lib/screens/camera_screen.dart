// --- Camera Screen Widget ---
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:test_showcase/main.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraInitialized = false;
  bool _isTakingPicture = false;
  int _selectedCameraIndex = 0; // Start with the first camera (usually back)
  // DeviceOrientation _currentOrientation = DeviceOrientation.portraitUp; // Track orientation

  // --- State for Sensor-based Icon Rotation ---
  double _iconRotationAngle = 0.0; // Angle in radians for icon rotation
  StreamSubscription<AccelerometerEvent>?
      _accelerometerSubscription; // Sensor subscription

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Allow all orientations initially
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // --- Initialize Accelerometer Listener ---
    _accelerometerSubscription = accelerometerEventStream(
            samplingPeriod:
                SensorInterval.uiInterval) // Use uiInterval for responsiveness
        .listen((AccelerometerEvent event) {
      if (mounted) {
        // Calculate the angle based on accelerometer values x and y
        // atan2(y, x) gives the angle relative to the positive X axis.
        // To get angle relative to the "top" of the screen (positive Y axis pointing down in portrait),
        // we can use atan2(-x, y). This calculation might need slight adjustment
        // depending on the exact sensor orientation and desired "up" direction.
        double angle = math.atan2(-event.x, event.y);

        // Optional: Smooth the angle or apply a threshold if it's too jittery
        // For simplicity, we update directly now.

        setState(() {
          _iconRotationAngle = angle;
        });
      }
    });

    // Initialize the camera with the default selection
    if (cameras.isNotEmpty) {
      _initializeCamera(cameras[_selectedCameraIndex]);
    } else {
      print("Error: No cameras available!");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Error: No cameras found on this device.')),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // --- Cancel sensor subscription ---
    _accelerometerSubscription?.cancel();
    print("Accelerometer subscription cancelled");

    // VERY IMPORTANT: Dispose the camera controller
    _controller?.dispose();
    print("Camera controller disposed");
    super.dispose();
  }

  // --- Lifecycle Listener (Handles app pause/resume) ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (cameraController.value.isInitialized) {
        cameraController.dispose();
        // --- Also pause sensor listening when inactive? Optional ---
        // _accelerometerSubscription?.pause();
        setState(() {
          _isCameraInitialized = false;
          _initializeControllerFuture = null;
        });
        print("Camera disposed due to inactivity");
      }
    } else if (state == AppLifecycleState.resumed) {
      // --- Resume sensor listening ---
      // _accelerometerSubscription?.resume();
      print("App resumed, reinitializing camera...");
      if (!_isCameraInitialized && cameras.isNotEmpty) {
        _initializeCamera(cameras[_selectedCameraIndex]);
      }
    }
  }

  // --- Initialize Camera Function ---
  Future<void> _initializeCamera(CameraDescription cameraDescription) async {
    if (_controller != null) {
      print("Disposing previous camera controller...");
      await _controller!.dispose();
      setState(() {
        _controller = null;
        _isCameraInitialized = false;
        _initializeControllerFuture = null;
      });
      await Future.delayed(const Duration(milliseconds: 100));
    }
    print("Initializing new camera: ${cameraDescription.name}");

    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller!.addListener(() {
      if (mounted) setState(() {});
      if (_controller!.value.hasError) {
        print('Camera error: ${_controller!.value.errorDescription}');
        _showErrorSnackbar(
            'Camera error: ${_controller!.value.errorDescription}');
      }
    });

    _initializeControllerFuture = _controller!.initialize().then((_) async {
      if (!mounted) return;
      
      // 锁定相机捕获方向为竖屏
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
      print("Camera orientation locked to portrait");
      
      setState(() {
        _isCameraInitialized = true;
      });
      print("Camera initialized successfully.");
    }).catchError((Object e) {
      if (e is CameraException) {
        print(
            'Error initializing camera: ${e.code}\nError Message: ${e.description}');
        _showErrorSnackbar('Error initializing camera: ${e.description}');
      } else {
        print('Unknown error initializing camera: $e');
        _showErrorSnackbar('Unknown error initializing camera: $e');
      }
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _initializeControllerFuture = null;
        });
      }
    });

    if (mounted) {
      setState(() {});
    }
  }

  // --- Take Picture Function ---
  void _onTakePictureButtonPressed() async {
    if (!_isCameraInitialized ||
        _controller == null ||
        _controller!.value.isTakingPicture ||
        _isTakingPicture) {
      print("Camera not ready or already taking picture.");
      return;
    }

    setState(() {
      _isTakingPicture = true;
    });
    print("Attempting to take picture...");

    try {
      // Optional: Lock orientation based on sensor data if needed, more complex
      // final orientation = await _getLockedOrientationFromSensors();
      // await _controller?.lockCaptureOrientation(orientation);

      final XFile imageFile = await _controller!.takePicture();

      // await _controller?.unlockCaptureOrientation();

      print("Picture taken: ${imageFile.path}");

      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PreviewScreen(imagePath: imageFile.path),
          ),
        );
      }
    } catch (e) {
      print('Error taking picture: $e');
      _showErrorSnackbar('Error taking picture: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
      print("Picture taking process finished.");
    }
  }

  // --- Switch Camera Function ---
  void _onSwitchCameraPressed() {
    if (cameras.length < 2 ||
        _isTakingPicture ||
        _controller == null ||
        _controller!.value.isTakingPicture) {
      print("Cannot switch camera now.");
      return;
    }

    print("Switching camera...");
    _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras.length;
    _initializeCamera(cameras[_selectedCameraIndex]);
  }

  // --- Helper to show snackbar errors ---
  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: Duration(seconds: 3)),
      );
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // No longer strictly need OrientationBuilder for icon rotation,
    // but it's still useful for layout adjustments if needed later.
    // We'll keep it for now.
    return OrientationBuilder(
      builder: (context, orientation) {
        // final isPortrait = orientation == Orientation.portrait;
        // _currentOrientation = isPortrait ? DeviceOrientation.portraitUp : DeviceOrientation.landscapeLeft;

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // --- Camera Preview ---
                FutureBuilder<void>(
                  future: _initializeControllerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        _isCameraInitialized &&
                        _controller != null) {
                      // 获取当前设备方向
                      final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
                      
                      // 获取相机预览尺寸
                      final previewSize = _controller!.value.previewSize!;
                      
                      // 计算相机预览的宽高比
                      final previewRatio = previewSize.height / previewSize.width;
                      
                      // 获取屏幕尺寸
                      final screenSize = MediaQuery.of(context).size;
                      final screenRatio = screenSize.width / screenSize.height;
                      
                      // 计算适合屏幕的缩放比例
                      final scale = isPortrait
                          ? screenRatio / previewRatio
                          : 1 / (screenRatio * previewRatio);
                      
                      return Center(
                        child: ClipRect(
                          child: Transform.scale(
                            scale: scale,
                            child: Center(
                              child: CameraPreview(_controller!),
                            ),
                          ),
                        ),
                      );
                    } else if (snapshot.hasError ||
                        (!_isCameraInitialized &&
                            snapshot.connectionState !=
                                ConnectionState.waiting)) {
                      // --- Error State ---
                      return Center(
                        // Simplified error display
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Error: ${snapshot.error ?? 'Failed to initialize camera.'}',
                            style: const TextStyle(
                                color: Colors.red, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    } else {
                      // --- Loading State ---
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.white));
                    }
                  },
                ),

                // --- Controls Overlay ---
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20.0, horizontal: 20.0),
                    color: Colors.black.withOpacity(0.4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        // --- Switch Camera Button (Rotated) ---
                        Transform.rotate(
                          angle: _iconRotationAngle, // Apply rotation
                          child: IconButton(
                            icon: const Icon(Icons.switch_camera, size: 30),
                            color: Colors.white,
                            tooltip: "Switch Camera",
                            onPressed: (_isTakingPicture ||
                                    cameras.length < 2 ||
                                    !_isCameraInitialized)
                                ? null
                                : _onSwitchCameraPressed,
                          ),
                        ),

                        // --- Take Picture Button (Inner part Rotated) ---
                        GestureDetector(
                          onTap: (_isTakingPicture || !_isCameraInitialized)
                              ? null
                              : _onTakePictureButtonPressed,
                          child: Container(
                            // Outer border container
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.transparent,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: Center(
                              // --- Rotate the inner circle ---
                              child: Transform.rotate(
                                angle: _iconRotationAngle, // Apply rotation
                                child: Container(
                                  // Inner white circle
                                  width: 55,
                                  height: 55,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(
                                        (_isTakingPicture ||
                                                !_isCameraInitialized)
                                            ? 0.3
                                            : 1.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Placeholder - keep symmetry
                        Transform.rotate(
                            // Rotate placeholder too if needed
                            angle: _iconRotationAngle,
                            child: const SizedBox(
                                width: 48,
                                height: 48) // Match IconButton size approx
                            ),
                      ],
                    ),
                  ),
                ),

                // --- Loading Indicator when Taking Picture ---
                if (_isTakingPicture)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                        child: CircularProgressIndicator(color: Colors.white)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PreviewScreen extends StatelessWidget {
  final String imagePath;

  const PreviewScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white, // Make AppBar icons/text white
      ),
      backgroundColor: Colors.black,
      body: Center(
          // Display the image from the file path.
          // Image.file handles loading the image from the device storage.
          // It might automatically handle EXIF orientation on some platforms.
          child: InteractiveViewer(
        // Allow zooming and panning
        panEnabled: false, // Optional: disable panning
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.file(
          File(imagePath),
          fit: BoxFit.contain, // Ensure the whole image is visible
          errorBuilder: (context, error, stackTrace) {
            return const Center(
                child: Text('Error loading image',
                    style: TextStyle(color: Colors.red)));
          },
        ),
      )),
    );
  }
}
