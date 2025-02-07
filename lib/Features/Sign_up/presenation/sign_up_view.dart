import 'package:drivebuddy/Core/Utils/App%20Colors.dart';
import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'dart:ui' as ui;
import '../../../core/Utils/Core Components.dart';
import '../../../core/Utils/Shared Methods.dart';
import '../../Home/view/presentation/home_view.dart';
import '../../Login/presenation/login_view.dart';

class SignUpView extends StatelessWidget {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SignUpBackground(),
          SingleChildScrollView( // Wrap this in a SingleChildScrollView
            child: Column(
              children: [
                Stack(
                  children: [
                    CustomPaint(
                      size: Size(size.width, size.height * 0.18), // Smaller wave height
                      painter: SignUpWavePainter(),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: SizedBox(
                        width: size.width,
                        height: size.height * 0.31, // Reduced height for logo area
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [AnimatedLogo()],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16), // Reduced horizontal padding
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInText(
                        text: 'Create an Account!',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 28, // Reduced font size
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        delay: 500,
                      ),
                      SizedBox(height: 4),
                      FadeInText(
                        textAlign: TextAlign.start,
                        text: 'Sign up to get started with DriveBuddy',
                        style: TextStyle(fontSize: 14, color: Colors.black54), // Reduced font size
                        delay: 700,
                      ),
                      SizedBox(height: 24), // Reduced spacing
                      Column(
                        children: [
                          const SizedBox(height: 12), // Reduced spacing
                          TextFieldTemplate(
                            name: 'Username',
                            label: 'Enter your Username',
                            leadingIcon: Icons.person,
                            boolleadingIcon: true,
                            leadingIconColor: AppColorsData.primaryColor,
                            enableFocusBorder: false,
                            titel: "Username",
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                            ]),
                          ),
                          const SizedBox(height: 12), // Reduced spacing
                          TextFieldTemplate(
                            titel: "Email",
                            name: 'Email',
                            label: 'Enter your Email',
                            inputType: TextInputType.emailAddress,
                            leadingIconColor: AppColorsData.primaryColor,
                            enableFocusBorder: false,
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.email(),
                            ]),
                          ),
                          const SizedBox(height: 12), // Reduced spacing
                          TextFieldTemplate(
                            titel: "Phone Number",
                            name: 'PhoneNumber',
                            label: 'Enter your Phone Number',
                            inputType: TextInputType.phone,
                            leadingIconColor: AppColorsData.primaryColor,
                            enableFocusBorder: false,
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                            ]),
                          ),
                          const SizedBox(height: 12), // Reduced spacing
                          TextFieldTemplate(
                            titel: "Password",
                            name: 'Password',
                            label: 'Password',
                            inputType: TextInputType.visiblePassword,
                            leadingIconColor: AppColorsData.primaryColor,
                            enableFocusBorder: false,
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                            ]),
                          ),
                          const SizedBox(height: 12), // Reduced spacing
                          TextFieldTemplate(
                            titel: "Confirm Password",
                            name: 'Confirm Password',
                            label: 'Confirm your Password',
                            inputType: TextInputType.visiblePassword,
                            leadingIconColor: AppColorsData.primaryColor,
                            enableFocusBorder: false,
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                            ]),
                          ),
                          const SizedBox(height: 20), // Reduced spacing
                          AnimatedButton(
                            text: 'SIGN UP',
                            onPressed: () {},
                            delay: 900,
                          ),
                          SizedBox(height: 12), // Reduced spacing
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account?",
                                style: TextStyle(
                                  fontSize: 12, // Reduced font size
                                  color: Colors.black,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  navigateTo(context, LoginView());
                                },
                                child: Text(
                                  "Log in",
                                  style: TextStyle(
                                    fontSize: 12, // Reduced font size
                                    color: AppColorsData.primaryColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class SignUpBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Draw the wave background with smaller height
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: CustomPaint(painter: SignUpWavePainter()), // Using custom painter with smaller wave
          ),
        ),
      ],
    );
  }
}

class SignUpWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = AppColorsData.primaryColor
      ..style = PaintingStyle.fill;

    // Draw the wave path with smaller height for sign-up screen
    Path path = Path();
    path.lineTo(0, size.height * 0.15); // Adjusted smaller height for wave
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.25, // Slightly adjusted the curve for a smaller wave
      size.width * 0.5,
      size.height * 0.18,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.10, // Adjusted to make the wave more subtle
      size.width,
      size.height * 0.12,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

