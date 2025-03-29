import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

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

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  String apiUrl = 'https://5f9a-197-35-213-152.ngrok-free.app/detect'; // Default URL

  @override
  void initState() {
    super.initState();
    _fetchApiUrl(); // Fetch the API URL from Firebase with validation
    _initializeCamera();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (!kIsWeb) {
      HttpOverrides.global = MyHttpOverrides();
    }
  }

  Future<void> _fetchApiUrl() async {
    try {
      // Reference to the Firestore document
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('AI Model') // Replace with your collection name
          .doc('8mIxxO0s8Ce6mGbELy9D') // Document ID
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final fetchedUrl = data['url'] as String?;

        // Assert that the URL exists and is not null
        assert(fetchedUrl != null, 'Firebase document must contain a "url" field');
        assert(fetchedUrl!.isNotEmpty, 'Firebase URL cannot be empty');

        // Validate the URL
        final uri = Uri.tryParse(fetchedUrl!);
        assert(uri != null, 'Invalid URL format fetched from Firebase: $fetchedUrl');
        assert(uri!.hasScheme, 'URL must have a scheme (e.g., http or https): $fetchedUrl');
        // Construct the full API URL
        final validatedUrl = '$fetchedUrl/detect';
        final validatedUri = Uri.parse(validatedUrl); // Ensure the final URL is valid
        assert(validatedUri.isAbsolute, 'Final API URL must be absolute: $validatedUrl');

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
      ResolutionPreset.max,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
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
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

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
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras!.length;
    });
    await _switchCamera(_availableCameras![_selectedCameraIndex]);
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

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
            'image': await MultipartFile.fromFile(image.path, filename: image.name),
          });
        }
      }

      var response = await _dio.post(
        apiUrl,
        data: await createFormData(),
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == null || response.statusCode! >= 500) {
        print("Retrying due to initial failure (status: ${response.statusCode})");
        response = await _dio.post(
          apiUrl,
          data: await createFormData(),
          options: Options(validateStatus: (status) => true),
        );
      }

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final jsonResponse = response.data is String ? jsonDecode(response.data) : response.data;
        _showScanResultsBottomSheet(image, jsonResponse);
      } else {
        _showErrorSnackbar(message: 'API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error sending image to API: $e");
      _showErrorSnackbar(message: 'Failed to connect to the server: $e');
    }
  }

  void _showScanResultsBottomSheet(XFile image, Map<String, dynamic> apiResponse) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ScanResultsScreen(
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
            if (_isCameraInitialized)
              CameraPreview(_cameraController!)
            else
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE67E5E)),
                ),
              ),
            _buildScanOverlay(),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildHeader(context),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomControls(context),
            ),
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
          colors: [
            Colors.black.withOpacity(0.5),
            Colors.transparent,
          ],
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
                    Icon(
                      Iconsax.scan,
                      color: Color(0xFFE67E5E),
                      size: 48,
                    ),
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
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
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
                border: Border.all(
                  color: const Color(0xFFE67E5E),
                  width: 4,
                ),
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
    final annotatedImageBase64 = widget.apiResponse['annotated_image'] as String?;

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
                child: annotatedImageBase64 != null
                    ? Image.memory(
                  base64Decode(annotatedImageBase64),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text(
                        'Image Load Failed',
                        style: TextStyle(color: Colors.redAccent, fontSize: 16),
                      ),
                    );
                  },
                )
                    : (_imageBytes != null
                    ? Image.memory(
                  _imageBytes!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text(
                        'Image Load Failed',
                        style: TextStyle(color: Colors.redAccent, fontSize: 16),
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
                    detections.isNotEmpty
                        ? Column(
                      children: detections.map((detection) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            '${detection['predicted_class']}: ${(detection['confidence'] * 100).toStringAsFixed(2)}% confidence',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                        );
                      }).toList(),
                    )
                        : Text(
                      'No detections found.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.deepOrange[800],
                      ),
                    ),
                  ],
                ),
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
                        Icon(Iconsax.lifebuoy, color: Color(0xFFE67E5E), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Recommended Solution',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    detections.isNotEmpty
                        ? Column(
                      children: detections.map((detection) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            detection['recommendation'] ?? 'No recommendation provided.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                        );
                      }).toList(),
                    )
                        : Text(
                      'No recommendations available.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ElevatedButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Iconsax.refresh, size: 20, color: Colors.white),
                label: const Text(
                  'Retry Scan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E5E),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFFE67E5E).withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}