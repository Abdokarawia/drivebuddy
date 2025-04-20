import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({Key? key}) : super(key: key);

  @override
  _CameraScanScreenState createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _availableCameras;
  int _selectedCameraIndex = 0;
  bool _isFlashOn = false;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  String apiUrl =
      'https://5f9a-197-35-213-152.ngrok-free.app/detect'; // Default URL

  @override
  void initState() {
    super.initState();
    _fetchApiUrl(); // Fetch the API URL from Firebase with validation
    _initializeCamera();
    _initializeNotifications();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (!kIsWeb) {
      HttpOverrides.global = MyHttpOverrides();
    }
  }

  Future<void> _initializeNotifications() async {
    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission for notifications');

      // Handle Firebase Cloud Messaging for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print(
            'Message also contained a notification: ${message.notification}',
          );

          // Show in-app notification with SnackBar
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  message.notification?.body ?? 'New scan notification',
                ),
                backgroundColor: const Color(0xFFE67E5E),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'View',
                  textColor: Colors.white,
                  onPressed: () {
                    // Navigate to scan history or details if needed
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => ScanHistoryScreen()));
                  },
                ),
              ),
            );
          }
        }
      });

      // Handle when notification opens the app from terminated state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('A new onMessageOpenedApp event was published!');
        // Navigate to appropriate screen based on notification data
        if (message.data.containsKey('scanId')) {
          // Handle navigation to scan details
          // Navigator.push(context, MaterialPageRoute(builder: (context) => ScanDetailScreen(scanId: message.data['scanId'])));
        }
      });

      // Get FCM token
      String? token = await _messaging.getToken();
      print('FCM Token: $token');

      // Save the token to Firestore for the current user
      if (token != null && _auth.currentUser != null) {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }
    }
  }

  Future<void> _fetchApiUrl() async {
    try {
      // Reference to the Firestore document
      DocumentSnapshot doc =
      await FirebaseFirestore.instance
          .collection('AI Model') // Replace with your collection name
          .doc('8mIxxO0s8Ce6mGbELy9D') // Document ID
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final fetchedUrl = data['url'] as String?;

        // Assert that the URL exists and is not null
        assert(
        fetchedUrl != null,
        'Firebase document must contain a "url" field',
        );
        assert(fetchedUrl!.isNotEmpty, 'Firebase URL cannot be empty');

        // Validate the URL
        final uri = Uri.tryParse(fetchedUrl!);
        assert(
        uri != null,
        'Invalid URL format fetched from Firebase: $fetchedUrl',
        );
        assert(
        uri!.hasScheme,
        'URL must have a scheme (e.g., http or https): $fetchedUrl',
        );
        // Construct the full API URL
        final validatedUrl = '$fetchedUrl/detect';
        final validatedUri = Uri.parse(
          validatedUrl,
        ); // Ensure the final URL is valid
        assert(
        validatedUri.isAbsolute,
        'Final API URL must be absolute: $validatedUrl',
        );

        setState(() {
          apiUrl = validatedUrl;
        });
        print('Fetched and validated API URL from Firebase: $apiUrl');
      } else {
        print('Document does not exist, using default API URL: $apiUrl');
      }
    } catch (e) {
      print('Error fetching or validating API URL from Firebase: $e');
      // Fallback to default URL if fetch or validation fails
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras == null || _availableCameras!.isEmpty) {
        print("No cameras available");
        setState(() => _isCameraInitialized = false);
        return;
      }
      await _switchCamera(_availableCameras![_selectedCameraIndex]);
    } catch (e) {
      print("Error initializing camera: $e");
      setState(() => _isCameraInitialized = false);
    }
  }

  Future<void> _switchCamera(CameraDescription cameraDescription) async {
    setState(() => _isCameraInitialized = false);
    _cameraController?.dispose();

    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      await _cameraController!.lockCaptureOrientation(DeviceOrientation.landscapeRight);

      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      print("Error switching camera: $e");
      setState(() => _isCameraInitialized = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _animationController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    await _cameraController!.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
  }

  Future<void> _toggleCamera() async {
    if (_availableCameras == null || _availableCameras!.length < 2) return;

    setState(() {
      _selectedCameraIndex =
          (_selectedCameraIndex + 1) % _availableCameras!.length;
    });
    await _switchCamera(_availableCameras![_selectedCameraIndex]);
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    setState(() => _isProcessing = true);
    try {
      final image = await _cameraController!.takePicture();
      await _sendImageToApi(image);
    } catch (e) {
      print("Error capturing image: $e");
      _showErrorSnackbar();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _openGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isProcessing = true);
      try {
        await _sendImageToApi(pickedFile); // Send gallery image to API
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  Future<void> _sendImageToApi(XFile image) async {
    try {
      print('Sending request to $apiUrl');

      Future<FormData> createFormData() async {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          return FormData.fromMap({
            'image': MultipartFile.fromBytes(bytes, filename: image.name),
          });
        } else {
          return FormData.fromMap({
            'image': await MultipartFile.fromFile(
              image.path,
              filename: image.name,
            ),
          });
        }
      }

      var response = await _dio.post(
        apiUrl,
        data: await createFormData(),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == null || response.statusCode! >= 500) {
        print(
          "Retrying due to initial failure (status: ${response.statusCode})",
        );
        response = await _dio.post(
          apiUrl,
          data: await createFormData(),
          options: Options(validateStatus: (status) => true),
        );
      }

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final jsonResponse =
        response.data is String ? jsonDecode(response.data) : response.data;

        // Save scan result to Firestore history
        await _saveScanToHistory(image, jsonResponse);

        // Create notification in Firestore
        await _createScanNotification(jsonResponse);

        _showScanResultsBottomSheet(image, jsonResponse);
      } else {
        _showErrorSnackbar(
          message: 'API request failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print("Error sending image to API: $e");
      _showErrorSnackbar(message: 'Failed to connect to the server: $e');
    }
  }

  Future<void> _saveScanToHistory(
      XFile image,
      Map<String, dynamic> apiResponse,
      ) async {
    try {
      final FirebaseAuth _auth = FirebaseAuth.instance;
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      if (_auth.currentUser == null) {
        print('No user is signed in, cannot save scan history');
        return;
      }

      final userId = _auth.currentUser!.uid;
      final timestamp = FieldValue.serverTimestamp();

      // Get detections from API response
      final detections = apiResponse['detections'] as List<dynamic>? ?? [];

      // Create notification message based on all detections
      String notificationTitle = 'Dashboard Scan Complete';
      String notificationBody = 'Your dashboard scan has been processed.';

      if (detections.isNotEmpty) {
        // Summarize all detections for the notification
        final detectionSummaries = detections.map((detection) {
          final detectedClass = detection['predicted_class'] as String? ?? 'Unknown';
          final confidence = detection['confidence'] as double? ?? 0.0;
          return '$detectedClass (${(confidence * 100).toStringAsFixed(0)}% confidence)';
        }).join(', ');

        notificationTitle = 'Dashboard Scan: Issues Detected';
        notificationBody = 'Detected: $detectionSummaries. Check results for details.';
      } else {
        notificationBody = 'No issues detected in the dashboard scan.';
      }

      // Create scan history document
      final historyRef = await _firestore.collection('history').add({
        'userId': userId,
        'timestamp': timestamp,
        'imagePath': image.path, // Store path instead of base64
        'title': notificationTitle,
        'body': notificationBody,
        'read': false,
        'type': 'scan_result',
        'data': {
          'detections': detections, // Store all detections
          'scanType': 'dashboard',
        },
        'deviceInfo': {
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
          'isWeb': kIsWeb,
        },
      });

      print('Scan saved to history with ID: ${historyRef.id}');

      // Update user's scan history reference
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('scanHistory')
          .doc(historyRef.id)
          .set({
        'historyRef': historyRef.id,
        'timestamp': timestamp,
        'scanType': 'dashboard',
        'title': notificationTitle,
        'body': notificationBody,
        'read': false,
      });
    } catch (e) {
      print('Error saving scan to history: $e');
    }
  }


  Future<void> _createScanNotification(Map<String, dynamic> apiResponse) async {
    try {
      if (_auth.currentUser == null) {
        print('No user is signed in, cannot create notification');
        return;
      }

      final userId = _auth.currentUser!.uid;
      final timestamp = FieldValue.serverTimestamp();

      // Get detections from API response
      final detections = apiResponse['detections'] as List<dynamic>? ?? [];

      // Create notification message based on detections
      String notificationTitle = 'Dashboard Scan Complete';
      String notificationBody = 'Your dashboard scan has been processed.';

      if (detections.isNotEmpty) {
        final firstDetection = detections.first;
        final detectedClass =
            firstDetection['predicted_class'] as String? ?? 'Unknown';
        final confidence = firstDetection['confidence'] as double? ?? 0.0;

        notificationTitle = 'Dashboard Scan: $detectedClass Detected';
        notificationBody =
        'Detected with ${(confidence * 100).toStringAsFixed(0)}% confidence. Check results for details.';
      }

      // Create notification in Firestore
      final notificationRef = await _firestore.collection('notifications').add({
        'userId': userId,
        'timestamp': timestamp,
        'title': notificationTitle,
        'body': notificationBody,
        'read': false,
        'type': 'scan_result',
        'data': {'detections': detections, 'scanType': 'dashboard'},
      });

      print('Notification created with ID: ${notificationRef.id}');
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  void _showScanResultsBottomSheet(
      XFile image,
      Map<String, dynamic> apiResponse,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder:
            (context, scrollController) => ScanResultsScreen(
          image: image,
          apiResponse: apiResponse,
          onRetry: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showErrorSnackbar({String? message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message ?? 'Failed to capture image. Please try again.',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full screen camera preview
            if (_isCameraInitialized)
              CameraPreview(_cameraController!)
            else
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE67E5E)),
                ),
              ),
            // Scan overlay
            _buildScanOverlay(),
            // Header controls
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildHeader(context),
            ),
            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomControls(context),
            ),
            // Processing indicator
            if (_isProcessing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE67E5E)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Processing...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.5), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black38,
              shape: const CircleBorder(),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Iconsax.scan, color: Color(0xFFE67E5E), size: 16),
                SizedBox(width: 8),
                Text(
                  'Scan Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _toggleFlash,
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
              size: 28,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black38,
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Center(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.width * 0.85,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFE67E5E).withOpacity(0.7),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE67E5E).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.scan, color: Color(0xFFE67E5E), size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Position Dashboard Within Frame',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isProcessing ? null : _openGallery,
              icon: const Icon(Iconsax.gallery, color: Colors.white, size: 28),
            ),
          ),
          GestureDetector(
            onTap: _isProcessing ? null : _captureImage,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE67E5E), width: 4),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE67E5E).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE67E5E),
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isProcessing ? null : _toggleCamera,
              icon: const Icon(Iconsax.refresh, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class ScanResultsScreen extends StatefulWidget {
  final XFile image;
  final Map<String, dynamic> apiResponse;
  final VoidCallback onRetry;

  const ScanResultsScreen({
    Key? key,
    required this.image,
    required this.apiResponse,
    required this.onRetry,
  }) : super(key: key);

  @override
  _ScanResultsScreenState createState() => _ScanResultsScreenState();
}

class _ScanResultsScreenState extends State<ScanResultsScreen>
    with SingleTickerProviderStateMixin {
  Uint8List? _imageBytes;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadImageBytes();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  Future<void> _loadImageBytes() async {
    try {
      final bytes = await widget.image.readAsBytes();
      if (mounted) {
        setState(() => _imageBytes = bytes);
      }
    } catch (e) {
      print("Error loading image bytes: $e");
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detections = widget.apiResponse['detections'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: ScrollController(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 6,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Scan Results',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              height: 260,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child:
                (_imageBytes != null
                    ? Image.memory(
                  _imageBytes!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text(
                        'Image Load Failed',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                )
                    : const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFE67E5E),
                  ),
                )),
              ),
            ),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Iconsax.map, color: Color(0xFFE67E5E), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'AI Analysis',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (detections.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: detections.length,
                        itemBuilder: (context, index) {
                          final detection = detections[index];
                          final detectedClass =
                              detection['predicted_class'] as String? ??
                                  'Unknown';
                          final confidence =
                              detection['confidence'] as double? ?? 0.0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFE67E5E,
                                    ).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Iconsax.warning_2,
                                    color: Color(0xFFE67E5E),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        detectedClass,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Iconsax.clipboard_close,
                              size: 28,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No issues detected',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your dashboard scan appears normal',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Iconsax.scan, size: 18),
                  label: const Text('Scan Again'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFFE67E5E),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to History screen if available
                    // Navigator.pushNamed(context, '/history');
                  },
                  icon: const Icon(Iconsax.save_2, size: 18),
                  label: const Text('View History'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (detections.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Iconsax.message,
                          color: Color(0xFFE67E5E),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Recommended Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: detections.length,
                      itemBuilder: (context, index) {
                        final detection = detections[index];
                        final detectedClass =
                            detection['predicted_class'] as String? ??
                                'Unknown';

                        // Generate recommendations based on detected class
                        String recommendation = _getRecommendation(
                          detectedClass,
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue[100]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'For $detectedClass:',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                recommendation,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }


  String _getRecommendation(String detectedClass) {
    // Map of detected dashboard issues to a list of possible recommendations
    final recommendations = {
      'check engine': [
        'Visit a mechanic to diagnose the engine issue. This could indicate problems with emissions, fuel system, or engine performance.',
        'Run an OBD-II scan to identify specific error codes and consult a professional for repairs.',
        'Check for loose or damaged gas cap, as it can trigger this light. Tighten or replace if necessary.',
      ],
      'oil pressure': [
        'Stop driving immediately and check oil levels. Low oil pressure can cause severe engine damage if ignored.',
        'Inspect for oil leaks under the vehicle and have a mechanic address any issues found.',
        'Ensure the oil pump is functioning correctly; a faulty pump may require replacement.',
      ],
      'battery warning': [
        'Check battery connections and have the charging system tested. Your battery or alternator may need replacement.',
        'Clean battery terminals to ensure a good connection and test the battery’s charge.',
        'Inspect the alternator belt for wear or looseness, as it could affect charging.',
      ],
      'abs warning': [
        "Have your Anti-lock Braking System inspected. This affects your vehicle's ability to brake safely, especially in emergency situations.",
        'Check wheel speed sensors for dirt or damage, as they can trigger ABS issues.',
        'Ensure ABS module and pump are functioning; a professional diagnostic is recommended.',
      ],
      'brake system': [
        'Check brake fluid levels and have your brake system inspected immediately. Do not drive if brakes feel unresponsive.',
        'Inspect brake pads and rotors for wear; replace if they are below recommended thickness.',
        'Look for leaks in the brake lines or master cylinder, and have them repaired promptly.',
      ],
      'airbag warning': [
        'Have your airbag system diagnosed. In an accident, airbags may not deploy properly with this warning active.',
        'Check the airbag system’s fuse and connections for issues; replace or repair as needed.',
        'Ensure the supplemental restraint system (SRS) module is functioning; professional repair may be required.',
      ],
      'temperature warning': [
        'Safely pull over and let your engine cool down. Check coolant levels when safe. Continuing to drive may cause engine damage.',
        'Inspect the radiator for blockages or damage and clear any debris.',
        'Check the thermostat and water pump; a failure in either can cause overheating.',
      ],
      'tire pressure': [
        'Check all tire pressures and inflate to the recommended levels. Inspect tires for damage or punctures.',
        'Rotate tires if uneven wear is detected and check alignment to prevent future issues.',
        'Consider replacing tires if tread depth is low or damage is irreparable.',
      ],
      'traction control': [
        'Have the traction control system inspected, as it may affect vehicle stability in slippery conditions.',
        'Check wheel speed sensors, as they are often linked to traction control issues.',
        'Ensure the traction control module is functioning; a diagnostic scan is recommended.',
      ],
      'fuel system': [
        'Inspect the fuel pump and filter; a clogged filter or failing pump may need replacement.',
        'Check for contaminated fuel; drain and replace if necessary.',
        'Have a mechanic diagnose fuel injectors, as issues here can trigger warnings.',
      ],
    };

    // Convert detectedClass to lowercase for case-insensitive matching
    String key = detectedClass.toLowerCase();

    // If the detected class exists in the map, select a random recommendation
    if (recommendations.containsKey(key)) {
      final random = Random();
      final recommendationList = recommendations[key]!;
      return recommendationList[random.nextInt(recommendationList.length)];
    }

    // Default response for unrecognized issues
    return 'Have a professional mechanic inspect this warning light to determine the exact issue and recommended repairs.';
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}