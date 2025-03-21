import 'package:drivebuddy/Core/Utils/App%20Colors.dart';
import 'package:drivebuddy/Features/Login/presenation/view/login_view.dart';
import 'package:drivebuddy/Features/Sign_up/presenation/sign_up_view.dart';
import 'package:flutter/material.dart';
import '../../../../core/Utils/Shared Methods.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> with SingleTickerProviderStateMixin {
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const AnimatedBackground(),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    width: size.width,
                    child: buildLogo(),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildCreateAccountButton(),
                        const SizedBox(height: 16),
                        _buildLoginPrompt(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'DriveBuddy',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColorsData.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Unlock the mystery behind every dashboard alert\n'
              'Drive smarter and safer with us!',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => navigateTo(context,  SignUpView()),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsData.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: const Text(
          'CREATE ACCOUNT',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        TextButton(
          onPressed: () => navigateTo(context, const LoginView()),
          child: Text(
            "Log in",
            style: TextStyle(
              fontSize: 14,
              color: AppColorsData.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class WaveBorderPainter extends CustomPainter {
  final double animationValue;

  WaveBorderPainter({this.animationValue = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColorsData.primaryColor.withOpacity(0.95)
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [
          AppColorsData.primaryColor,
          AppColorsData.primaryColor.withOpacity(0.7),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..lineTo(0, size.height * 0.9)
      ..quadraticBezierTo(
          size.width * 0.25,
          size.height * (0.99 + 0.05 * animationValue),
          size.width * 0.5,
          size.height * 0.8)
      ..quadraticBezierTo(
          size.width * 0.75,
          size.height * (0.6 - 0.05 * animationValue),
          size.width,
          size.height * 0.8)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawShadow(path, Colors.black.withOpacity(0.2), 3.0, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WaveBorderPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.6, // Increased height for better visual balance
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: WaveBorderPainter(animationValue: _animation.value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildLogo() {
  return Container(
    width:  170,
    height: 170,
    child: Center(
      child: Image.asset(
        "assets/images/logo.png",
        width: ( 170) * 0.7,
        height: ( 170) * 0.7,
      ),
    ),
  );
}
