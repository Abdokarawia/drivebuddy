import 'dart:io';
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

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  String apiUrl =
      'https://5f9a-197-35-213-152.ngrok-free.app/detect'; // Default URL

  // Confidence threshold for filtering detections
  final double _confidenceThreshold = 0.5; // 50%

  @override
  void initState() {
    super.initState();
    _fetchApiUrl(); // Fetch the API URL with validation
    _initializeCamera();

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
      await _cameraController!.lockCaptureOrientation(
        DeviceOrientation.landscapeRight,
      );

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

        // Process and filter detections
        final processedResponse = _processApiResponse(jsonResponse);

        _showScanResultsBottomSheet(image, processedResponse);
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

  // Process API response to filter and enhance detections
  Map<String, dynamic> _processApiResponse(Map<String, dynamic> apiResponse) {
    final allDetections = apiResponse['detections'] as List<dynamic>? ?? [];

    // Filter detections based on confidence threshold
    final filteredDetections =
        allDetections
            .where(
              (detection) =>
                  (detection['confidence'] as double? ?? 0.0) >=
                  _confidenceThreshold,
            )
            .toList();

    // Group detections by class name and keep only the highest confidence detection for each class
    final Map<String, dynamic> highestConfidenceByClass = {};

    for (var detection in filteredDetections) {
      final className = detection['predicted_class'] as String;

      if (!highestConfidenceByClass.containsKey(className) ||
          (detection['confidence'] as double) >
              (highestConfidenceByClass[className]['confidence'] as double)) {
        // Create a copy of the detection with descriptive details
        final enhancedDetection = {
          ...detection,
          'description': _getDetectionDescription(detection),
          'severity': _getSeverityLevel(detection),
          'recommendations': _getRecommendations(detection),
          'solutions': _getSolutions(detection),
        };

        highestConfidenceByClass[className] = enhancedDetection;
      }
    }

    // Convert map back to list, sorted by confidence
    final bestDetections =
        highestConfidenceByClass.values.toList()..sort(
          (a, b) =>
              (b['confidence'] as double).compareTo(a['confidence'] as double),
        );

    print("----");
    print("Best detections per class: $bestDetections");
    print("----");

    // Create a new response with filtered and enhanced detections
    return {
      ...apiResponse,
      'detections': bestDetections,
      'original_detection_count': allDetections.length,
      'filtered_detection_count': filteredDetections.length,
      'unique_classes_count': bestDetections.length,
    };
  }

  // Helper method to categorize detections by vehicle systems
  List<String> _getDetectedSystems(List<dynamic> detections) {
    Set<String> systems = {};

    for (var detection in detections) {
      final className = detection['predicted_class'] as String;

      switch (className.toLowerCase()) {
        case 'check engine':
          systems.add('engine');
          systems.add('Emissions');
          break;
        case 'airbag warning':
          systems.add('Safety');
          break;
        case 'battery warning':
          systems.add('Electrical');
          break;
        case 'oil pressure':
          systems.add('engine');
          systems.add('Lubrication');
          break;
        case 'abs warning':
          systems.add('Braking');
          systems.add('Safety');
          break;
        case 'tire pressure':
          systems.add('Tires');
          systems.add('Safety');
          break;
        case 'temperature warning':
          systems.add('Cooling');
          systems.add('engine');
          break;
        case 'low fuel':
          systems.add('Fuel');
          break;
        default:
          systems.add('General');
      }
    }

    return systems.toList();
  }

  // Get description for a detection based on its class
  String _getDetectionDescription(Map<String, dynamic> detection) {
    final className = detection['predicted_class'] as String;

    // Define descriptions for common detection classes
    switch (className.toLowerCase()) {
      case 'check engine':
        return 'The check engine light indicates a potential problem with your engine or emissions system.';
      case 'low fuel':
        return 'Your vehicle is running low on fuel and should be refilled soon.';
      case 'airbag warning':
        return 'The airbag warning light indicates a potential issue with your vehicle\'s safety system.';
      case 'battery warning':
        return 'The battery warning light indicates your vehicle\'s charging system may not be functioning properly.';
      case 'oil pressure':
        return 'The oil pressure warning light indicates potential issues with your engine\'s oil system.';
      case 'abs warning':
        return 'The abs warning light indicates a potential issue with your anti-lock braking system.';
      case 'tire pressure':
        return 'The tire pressure warning light indicates one or more tires may be under-inflated.';
      case 'temperature warning':
        return 'The temperature warning light indicates your engine is overheating.';
      default:
        return 'A $className indicator has been detected on your dashboard.';
    }
  }

  // Get severity level based on detection class
  String _getSeverityLevel(Map<String, dynamic> detection) {
    final className = detection['predicted_class'] as String;
    final confidence = detection['confidence'] as double;

    // High severity warnings
    if ([
      'check engine',
      'airbag warning',
      'oil pressure',
      'temperature warning',
    ].contains(className.toLowerCase())) {
      return 'High';
    }
    // Medium severity warnings
    else if ([
      'abs warning',
      'battery warning',
      'tire pressure',
    ].contains(className.toLowerCase())) {
      return 'Medium';
    }
    // Low severity warnings
    else {
      return 'Low';
    }
  }

  // Get recommendations based on detection class
  List<String> _getRecommendations(Map<String, dynamic> detection) {
    final className = detection['predicted_class'] as String;

    switch (className.toLowerCase()) {
      case 'check engine':
        return [
          'Have your vehicle diagnosed by a professional mechanic',
          'Check for loose gas cap or other simple issues',
          'Monitor for changes in vehicle performance',
        ];
      case 'low fuel':
        return ['Refill your fuel tank as soon as possible'];
      case 'airbag warning':
        return [
          'Have your airbag system inspected immediately',
          'Avoid using the vehicle until inspection',
        ];
      case 'battery warning':
        return [
          'Check battery connections for corrosion',
          'Test the battery and alternator',
          'Be prepared for potential starting issues',
        ];
      case 'oil pressure':
        return [
          'Stop driving immediately if possible',
          'Check oil level and add oil if needed',
          'Have the oil system inspected by a professional',
        ];
      case 'abs warning':
        return [
          'Have the abs system diagnosed',
          'Drive cautiously, especially in wet conditions',
          'Allow for increased braking distance',
        ];
      case 'tire pressure':
        return [
          'Check tire pressure in all tires',
          'Inflate tires to recommended pressure',
          'Inspect tires for damage or leaks',
        ];
      case 'temperature warning':
        return [
          'Pull over safely and turn off the engine',
          'Let the engine cool down before checking coolant',
          'Check coolant level (when cool) and for leaks',
        ];
      default:
        return ['Have the warning light inspected by a professional'];
    }
  }

  // Get detailed solutions based on detection class
  Map<String, dynamic> _getSolutions(Map<String, dynamic> detection) {
    final className = detection['predicted_class'] as String;

    switch (className.toLowerCase()) {
      case 'check engine':
        return {
          'immediate_action': 'Use an OBD-II scanner to read the error code',
          'diy_solution':
              'Check and tighten gas cap, replace air filter, or check spark plug connections',
          'professional_solution':
              'Visit a mechanic for comprehensive diagnostic testing',
          'possible_causes': [
            'Loose gas cap',
            'Faulty oxygen sensor',
            'Catalytic converter issues',
            'Mass airflow sensor problems',
            'Spark plug or ignition coil failure',
          ],
          'estimated_repair_cost': '\$50 - \$500 depending on the cause',
        };
      case 'low fuel':
        return {
          'immediate_action': 'Find the nearest gas station',
          'diy_solution': 'Refill with appropriate fuel type',
          'professional_solution': 'N/A',
          'possible_causes': ['Low fuel level', 'Faulty fuel gauge sensor'],
          'estimated_repair_cost': '\$0 - \$200 if sensor replacement needed',
        };
      case 'airbag warning':
        return {
          'immediate_action': 'Schedule service appointment immediately',
          'diy_solution': 'Not recommended for safety systems',
          'professional_solution':
              'Dealer diagnostic and repair of airbag system',
          'possible_causes': [
            'Seat belt sensor malfunction',
            'Airbag control module failure',
            'Wiring issues',
            'Recent accident affecting sensors',
          ],
          'estimated_repair_cost': '\$100 - \$1,500 depending on the issue',
        };
      case 'battery warning':
        return {
          'immediate_action':
              'Test battery voltage with multimeter if available',
          'diy_solution': 'Clean battery terminals, ensure tight connections',
          'professional_solution': 'Alternator and charging system diagnostic',
          'possible_causes': [
            'Loose or corroded battery connections',
            'Aging battery',
            'Faulty alternator',
            'Damaged drive belt',
          ],
          'estimated_repair_cost':
              '\$20 - \$500 depending on required replacement',
        };
      case 'oil pressure':
        return {
          'immediate_action': 'Stop vehicle and check oil level when safe',
          'diy_solution': 'Add appropriate oil to proper level if low',
          'professional_solution':
              'Oil pressure sensor replacement or engine inspection',
          'possible_causes': [
            'Low oil level',
            'Oil pressure sensor failure',
            'Oil pump malfunction',
            'engine bearing wear',
            'Clogged oil filter',
          ],
          'estimated_repair_cost': '\$20 - \$2,000 depending on severity',
        };
      case 'abs warning':
        return {
          'immediate_action':
              'Drive cautiously - regular brakes still function',
          'diy_solution': 'Check brake fluid level',
          'professional_solution': 'abs sensor diagnostic and replacement',
          'possible_causes': [
            'abs sensor failure',
            'Low brake fluid',
            'abs module malfunction',
            'Damaged tone ring',
            'Electrical issues',
          ],
          'estimated_repair_cost': '\$100 - \$800 depending on required parts',
        };
      case 'tire pressure':
        return {
          'immediate_action': 'Check pressure in all tires with gauge',
          'diy_solution':
              'Add air to recommended PSI listed on driver door jamb',
          'professional_solution': 'TPMS sensor reset or replacement',
          'possible_causes': [
            'Under-inflated tires',
            'Temperature changes affecting pressure',
            'Slow leak or tire damage',
            'TPMS sensor malfunction',
          ],
          'estimated_repair_cost': '\$0 - \$350 depending on required service',
        };
      case 'temperature warning':
        return {
          'immediate_action': 'Pull over safely and turn off engine',
          'diy_solution': 'Add coolant when engine is cool (if low)',
          'professional_solution':
              'Cooling system pressure test and inspection',
          'possible_causes': [
            'Low coolant level',
            'Coolant leak',
            'Faulty radiator cap',
            'Thermostat failure',
            'Water pump malfunction',
            'Fan not operating properly',
          ],
          'estimated_repair_cost': '\$20 - \$800 depending on the component',
        };
      default:
        return {
          'immediate_action': 'Consult owner\'s manual for specific warning',
          'diy_solution': 'Basic visual inspection',
          'professional_solution': 'Diagnostic scan at service center',
          'possible_causes': ['Various system issues'],
          'estimated_repair_cost': 'Varies based on issue',
        };
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
                  apiResponse: apiResponse,
                  onRetry: () {
                    Navigator.pop(context);
                  },
                  onExit: () {
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
            Positioned(top: 0, left: 0, right: 0, child: _buildHeader(context)),
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFE67E5E),
                        ),
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
  final Map<String, dynamic> apiResponse;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  const ScanResultsScreen({
    Key? key,
    required this.apiResponse,
    required this.onRetry,
    required this.onExit,
  }) : super(key: key);

  @override
  _ScanResultsScreenState createState() => _ScanResultsScreenState();
}

class _ScanResultsScreenState extends State<ScanResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int? _currentDetectionIndex;
  bool _showAllDetections = false;
  Map<int, bool> _savedIssues = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final detections = widget.apiResponse['detections'] as List<dynamic>? ?? [];
    if (detections.isNotEmpty) {
      _currentDetectionIndex = null;
    }

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

  String _getImageAssetPath(String detectionType) {
    final Map<String, String> imageMap = {
      'abs': 'assets/images/abs.png',
      'airbag': 'assets/images/airbag.png',
      'dipped beam': 'assets/images/dipped beam.png',
      'power steering': 'assets/images/power steer.png',
      'hand brake': 'assets/images/hand brake.png',
      'engine': 'assets/images/engine.png',
      'warning': 'assets/images/warning.png',
      'tire pressure': 'assets/images/tire pressure.png',
      'stability control': 'assets/images/stability control.png',
      'seatbelt': 'assets/images/seatbelt.png',
    };

    return imageMap[detectionType] ?? 'assets/images/warning.png';
  }

  Future<void> saveIssue(int index) async {
    if (_isSaving || _savedIssues[index] == true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final detections =
          widget.apiResponse['detections'] as List<dynamic>? ?? [];
      if (index >= detections.length) return;

      final detection = detections[index];
      final title = detection['predicted_class'] as String? ?? 'Unknown Issue';
      final confidence = detection['confidence'] as double? ?? 0.5;

      final historyQuery =
          await FirebaseFirestore.instance
              .collection('history')
              .where('title', isEqualTo: title)
              .where(
                'userId',
                isEqualTo: FirebaseAuth.instance.currentUser?.uid,
              )
              .get();

      final count = historyQuery.docs.length + 1;
      final technicalInfo = _getTechnicalInfo(title);
      final solution = _getSolution(title);

      final description = '''
        Vehicle Issue Detection Report
        Issue: $title
        Occurrence Number: #$count
        ${technicalInfo}
        Recommended Solution: ${solution}
        
        Note: Please address this issue promptly to ensure vehicle safety and reliability.
        ''';

      _savedIssues.clear();

      // Only save to notifications if count is >= 3
      if (count >= 3) {
        String warningMessage =
            "$title: This issue has occurred $count times. Immediate attention required.";

        await FirebaseFirestore.instance.collection('notifications').add({
          'title': title,
          'description': description,
          'confidence': confidence,
          'imageAsset': _getImageAssetPath(title),
          'warningMessage': warningMessage,
          'timestamp': FieldValue.serverTimestamp(),
          'userId': FirebaseAuth.instance.currentUser?.uid,
        });
      }

      bool isShow = count <= 1;
      await FirebaseFirestore.instance.collection('history').add({
        'title': title,
        'description': description,
        'confidence': confidence,
        'imageAsset': _getImageAssetPath(title),
        'count': count,
        'isShow': isShow,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
      });

      setState(() {
        _savedIssues[index] = true;
      });

      if (count > 3) {
        _showWarningDialog(title, count);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Issue saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving issue: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  String _getTechnicalInfo(String detectedClass) {
    final Map<String, String> technicalInfo = {
      'abs':
          'The Anti-lock Braking System (abs) warning indicates a potential malfunction in the system designed to prevent wheels from locking during braking. This critical safety feature maintains steering control during emergency stops by pulsing brake pressure automatically.',
      'airbag':
          'The airbag warning light indicates a potential issue with the Supplemental Restraint System (SRS). This could affect deployment of airbags during a collision, compromising occupant safety in the event of an accident.',
      'dipped beam':
          'The dipped beam warning indicates a problem with your vehicle\'s low beam headlights. This affects visibility during night driving and may result in insufficient illumination of the road ahead.',
      'power steering':
          'The power steering warning indicates a malfunction in the power steering system. This can result in significantly increased steering effort, making the vehicle more difficult to maneuver, especially at low speeds.',
      'hand brake':
          'The hand brake (parking brake) warning indicates either that the parking brake is engaged while driving or there is a malfunction in the parking brake system. This can cause premature brake wear and reduced braking effectiveness.',
      'engine':
          'The engine warning light (Check engine) indicates the onboard diagnostics system has detected an issue with the engine, emission control system, or related components. This could affect performance, fuel economy, and emissions.',
      'tire pressure':
          'The tire pressure Monitoring System (TPMS) warning indicates one or more tires are significantly under or over-inflated. Improper tire pressure can lead to reduced handling, decreased fuel efficiency, and increased risk of blowouts.',
      'stability control':
          'The Electronic stability control (ESC) warning indicates a potential issue with the system designed to improve vehicle stability. This affects the vehicle\'s ability to detect and reduce skidding during cornering or emergency maneuvers.',
      'seatbelt':
          'The seatbelt warning indicates that one or more occupants are not wearing their seatbelts. seatbelts are a critical safety feature that significantly reduces the risk of injury in the event of a collision.',
    };

    return technicalInfo[detectedClass] ??
        'This warning light indicates a potential issue with your vehicle that requires attention. It affects vehicle operation and may pose safety concerns if left unaddressed.';
  }

  String _getSolution(String detectedClass) {
    final Map<String, String> solutions = {
      'abs':
          'Visit a qualified mechanic to diagnose the abs system. They will scan for specific fault codes and inspect the abs sensors, control module, and wiring for damage. Depending on the diagnosis, repairs may involve replacing sensors, the abs module, or repairing wiring.',
      'airbag':
          'Have the SRS system professionally diagnosed immediately. A technician will retrieve stored fault codes and inspect the airbag sensors, control module, clock spring, and wiring. Do not attempt to repair this safety-critical system yourself.',
      'dipped beam':
          'Check for burned-out bulbs and replace if necessary. Inspect for damaged wiring, faulty switches, or issues with the light control module. If bulb replacement doesn\'t resolve the issue, professional diagnosis is recommended.',
      'power steering':
          'Check the power steering fluid level and condition. If low, refill and inspect for leaks. If the fluid is at the proper level, professional diagnosis is needed to check the power steering pump, electronic power steering system, or steering rack.',
      'hand brake':
          'If the warning appears while driving, ensure the parking brake is fully released. If the issue persists, have the parking brake system inspected for proper adjustment, cable tension, or problems with the electronic parking brake system.',
      'engine':
          'Have the engine computer scanned for diagnostic trouble codes (DTCs). The specific codes will indicate the affected systems, which could include fuel delivery, ignition system, emissions controls, or engine sensors. Professional diagnosis is recommended.',
      'tire pressure':
          'Check the pressure in all tires including the spare using a reliable tire pressure gauge. Adjust to the manufacturer\'s recommended pressures listed in your owner\'s manual or driver\'s door jamb. Inspect tires for damage or slow leaks.',
      'stability control':
          'Have the stability control system professionally diagnosed. Issues may relate to wheel speed sensors, steering angle sensors, or the stability control module. The system often requires professional-grade diagnostic equipment.',
      'seatbelt':
          'Ensure all vehicle occupants are properly wearing their seatbelts. If the warning persists with seatbelts fastened, check for objects interfering with the seatbelt buckle or sensor. Professional inspection may be needed if the issue continues.',
    };

    return solutions[detectedClass] ??
        'Have a qualified mechanic inspect this warning light to determine the exact issue and recommended repairs. Continuing to drive without addressing this issue may lead to more severe problems and safety concerns.';
  }

  void _showWarningDialog(String issueType, int count) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.red[700]!, width: 2),
          ),
          title: Row(
            children: [
              Icon(Iconsax.danger, color: Colors.red[700], size: 28),
              const SizedBox(width: 10),
              Text(
                'CRITICAL ALERT',
                style: TextStyle(
                  color: Colors.red[900],
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.warning_2, color: Colors.red[800], size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is a serious recurring issue!',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red[900],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your $issueType issue has been detected $count times.',
                style: const TextStyle(
                  height: 1.4,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Continuing to drive with this issue may cause:',
                style: TextStyle(
                  height: 1.4,
                  fontSize: 15,
                  color: Colors.red[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.red[800]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vehicle damage requiring costly repairs',
                            style: TextStyle(color: Colors.red[800]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.red[800]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Safety risks to you and other road users',
                            style: TextStyle(color: Colors.red[800]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.red[800]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vehicle breakdown in potentially unsafe locations',
                            style: TextStyle(color: Colors.red[800]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[400]!),
                ),
                child: Text(
                  'IMMEDIATE PROFESSIONAL INSPECTION RECOMMENDED',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Dismiss', style: TextStyle(color: Colors.red[700])),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        );
      },
    );
  }

  Widget _buildDetectionList() {
    final detections = widget.apiResponse['detections'] as List<dynamic>? ?? [];
    if (detections.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.clipboard_close, size: 28, color: Colors.grey),
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
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Detected Issues (${detections.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: detections.length,
          itemBuilder: (context, index) {
            final detection = detections[index];
            final isSelected = index == _currentDetectionIndex;
            final isSaved = _savedIssues[index] == true;
            final detectedClass =
                detection['predicted_class'] as String? ?? 'Unknown';
            final confidence = detection['confidence'] as double? ?? 0.5;
            print("----****----");
            print(detectedClass);
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentDetectionIndex = isSelected ? null : index;
                  if (!isSelected) {
                    _fadeController.reset();
                    _fadeController.forward();
                    saveIssue(index);
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? const Color(0xFFE67E5E).withOpacity(0.1)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isSelected
                            ? const Color(0xFFE67E5E)
                            : Colors.grey[200]!,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: const Color(0xFFE67E5E).withOpacity(0.2),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ]
                          : null,
                ),
                child: Row(
                  children: [
                    if (detectedClass != 'Unknown')
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Image.asset(
                          _getImageAssetPath(detectedClass),
                          width: 60,
                          height: 60,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                detectedClass,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isSelected
                                          ? const Color(0xFFE67E5E)
                                          : Colors.black87,
                                ),
                              ),
                              if (isSaved)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Saved',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSeverityIndicator(double confidence) {
    Color severityColor;
    String severityText;

    if (confidence >= 0.9) {
      severityColor = Colors.red;
      severityText = 'Critical';
    } else if (confidence >= 0.7) {
      severityColor = Colors.orange;
      severityText = 'High';
    } else if (confidence >= 0.5) {
      severityColor = Colors.amber;
      severityText = 'Medium';
    } else {
      severityColor = Colors.green;
      severityText = 'Low';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: severityColor, size: 14),
          const SizedBox(width: 4),
          Text(
            severityText,
            style: TextStyle(
              color: severityColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getRecommendation(String detectedClass) {
    final Map<String, String> recommendations = {
      'abs':
          'Have your abs system diagnosed by a certified mechanic immediately. Do not ignore this warning as it affects braking performance.',
      'airbag':
          'Schedule an inspection of your airbag system as soon as possible. This is a critical safety feature that requires professional attention.',
      'dipped beam':
          'Check your headlight bulbs and connections. Consider replacing worn bulbs and have an electrician inspect the system if problems persist.',
      'power steering':
          'Check power steering fluid levels and have the system inspected by a professional mechanic. Driving with faulty power steering can be difficult and potentially unsafe.',
      'hand brake':
          'Ensure your parking brake is fully released. If the warning persists, have your braking system inspected as continued driving may cause damage.',
      'engine':
          'Schedule a diagnostic scan to identify the specific engine issue. Continuing to drive may cause further damage to your engine or emissions system.',
      'tire pressure':
          'Check and adjust the pressure in all tires according to the manufacturer\'s specifications. Inspect tires for damage and leaks.',
      'stability control':
          'Have your vehicle\'s stability control system professionally diagnosed. This system helps maintain control during challenging driving conditions.',
      'seatbelt':
          'Ensure all passengers are wearing seatbelts properly. If the warning persists with all belts fastened, have the seatbelt sensors checked.',
    };

    return recommendations[detectedClass] ??
        "Have a professional mechanic inspect this warning light to determine the exact issue and recommended repairs.";
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
      child: Column(
        children: [
          Center(
            child: Container(
              width: 50,
              height: 6,
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 36),
                const Text(
                  'Scan Results',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onExit,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: ScrollController(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
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
                              Iconsax.map,
                              color: Color(0xFFE67E5E),
                              size: 20,
                            ),
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
                        const SizedBox(height: 16),
                        _buildDetectionList(),
                      ],
                    ),
                  ),
                  if (detections.isNotEmpty && _currentDetectionIndex != null)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      'Issue Details',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                if (detections[_currentDetectionIndex!]['confidence'] !=
                                    null)
                                  _buildSeverityIndicator(
                                    detections[_currentDetectionIndex!]['confidence']
                                            as double? ??
                                        0.5,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Container(
                                width: 80,
                                height: 80,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  _getImageAssetPath(
                                    detections[_currentDetectionIndex!]['predicted_class']
                                            as String? ??
                                        'Unknown',
                                  ),
                                  width: 60,
                                  height: 60,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
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
                                  Row(
                                    children: [
                                      Icon(
                                        Iconsax.calendar,
                                        size: 20,
                                        color: Colors.grey[700],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Detected now',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Iconsax.chart,
                                        size: 20,
                                        color: Colors.grey[700],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Confidence: ${((detections[_currentDetectionIndex!]['confidence'] as double? ?? 0.5) * 100).toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Technical Information:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getTechnicalInfo(
                                      detections[_currentDetectionIndex!]['predicted_class']
                                              as String? ??
                                          'Unknown',
                                    ),
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Recommended Action:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getRecommendation(
                                      detections[_currentDetectionIndex!]['predicted_class']
                                              as String? ??
                                          'Unknown',
                                    ),
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (detections.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Iconsax.tick_circle,
                            color: Colors.green[600],
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'All Clear!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No dashboard warning lights detected in this scan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.onRetry,
                          icon: const Icon(Iconsax.refresh, size: 18),
                          label: const Text(
                            'New Scan',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
