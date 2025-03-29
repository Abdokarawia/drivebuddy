import 'package:flutter/material.dart';
import '../../../../Core/Utils/App Colors.dart';
import '../../../../core/Utils/Shared Methods.dart';
import '../../../Login/presenation/view/login_view.dart';
import '../../../Sign_up/presenation/sign_up_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600; // Define breakpoint for larger screens

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              const Positioned.fill(
                child: OnboardingBackground(),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: constraints.maxHeight * 0.6, // 50% of screen height
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.06, // 6% of screen width
                      vertical: size.height * 0.02, // 2% of screen height
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildHeader(isLargeScreen: isLargeScreen),
                        SizedBox(height: size.height * 0.04), // 4% of screen height
                        _buildGetStartedButton(constraints),
                        SizedBox(height: size.height * 0.02), // 2% of screen height
                        _buildLoginPrompt(isLargeScreen: isLargeScreen),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader({required bool isLargeScreen}) {
    return Column(
      children: [
        Text(
          'DriveBuddy',
          style: TextStyle(
            fontSize: isLargeScreen ? 40 : 32,
            fontWeight: FontWeight.bold,
            color: AppColorsData.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Your smart companion for understanding\nvehicle diagnostics and maintenance',
          style: TextStyle(
            fontSize: isLargeScreen ? 18 : 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGetStartedButton(BoxConstraints constraints) {
    return SizedBox(
      width: constraints.maxWidth * 0.8, // 80% of available width
      child: ElevatedButton(
        onPressed: () => navigateTo(context, SignUpView()),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsData.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: constraints.maxHeight * 0.025, // Responsive padding
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: const Text(
          'GET STARTED',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt({required bool isLargeScreen}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: TextStyle(
            fontSize: isLargeScreen ? 16 : 14,
            color: Colors.grey[600],
          ),
        ),
        TextButton(
          onPressed: () => navigateTo(context, const LoginView()),
          child: Text(
            "Log in",
            style: TextStyle(
              fontSize: isLargeScreen ? 16 : 14,
              color: AppColorsData.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class OnboardingBackground extends StatelessWidget {
  const OnboardingBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: CustomPaint(painter: LoginWavePainter()),
          ),
        ),
        Positioned(
          top: size.height * 0.22, // 15% from top
          right: size.width * 0.05, // 5% from right
          child: SizedBox(
            width: size.width * 0.25, // 30% of screen width
            height: size.width * 0.25, // Keep it square
            child: buildLogo(),
          ),
        ),
      ],
    );
  }
}

class LoginWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = AppColorsData.primaryColor
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.lineTo(0, size.height * 0.26);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.36,
      size.width * 0.5,
      size.height * 0.26,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.15,
      size.width,
      size.height * 0.19,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget buildLogo() {
  return Container(
    child: Center(
      child: Image.asset(
        "assets/images/logo.png",
        width: 200, // Will respect parent constraints
        height: 200,
        fit: BoxFit.contain, // Maintain aspect ratio
      ),
    ),
  );
}