import 'package:drivebuddy/Core/Utils/App%20Colors.dart';
import 'package:drivebuddy/Features/Forget_Password/Presentation/forget_password_view.dart';
import 'package:drivebuddy/Features/Sign_up/presenation/sign_up_view.dart';
import 'package:drivebuddy/Features/Tabs/Presenation/tabs_view.dart';
import 'package:drivebuddy/core/Utils/Shared%20Methods.dart';
import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'dart:ui' as ui;
import '../../../core/Utils/Core Components.dart';
import '../../Home/view/presentation/home_view.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final _formKey = GlobalKey<FormState>(); // Form key for validation
    bool _obscurePassword = true; // Toggle for password visibility

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          LoginBackground(),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.37),
                    FadeInText(
                      text: 'Welcome Back!',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      delay: 500,
                    ),
                    SizedBox(height: 4),
                    FadeInText(
                      textAlign: TextAlign.start,
                      text: 'Log in to your DriveBuddy account',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                      delay: 700,
                    ),
                    SizedBox(height: 24),
                    TextFieldTemplate(
                      name: 'Username',
                      label: 'Enter your Username',
                      leadingIcon: Icons.person,
                      boolleadingIcon: true,
                      leadingIconColor: AppColorsData.primaryColor,
                      enableFocusBorder: false,
                      titel: "Username",
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(
                              errorText: 'Username is required'),
                        ]),
                    ),
                    SizedBox(height: 12),
                    TextFieldTemplate(
                      titel: "Password",
                      name: 'Password',
                      label: 'Password',
                      inputType: TextInputType.visiblePassword,
                      leadingIconColor: AppColorsData.primaryColor,
                      enableFocusBorder: false,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                            errorText: 'Password is required'),
                        FormBuilderValidators.minLength(6,
                            errorText: 'Password must be at least 6 characters'),
                      ]),
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          navigateTo(context, ForgetPasswordView());
                        },
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColorsData.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    AnimatedButton(
                      text: 'LOG IN',
                      onPressed: () {

                        navigateAndFinished(context, TabsScreen());

                      },
                      delay: 900,
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            navigateTo(context, SignUpView());
                          },
                          child: Text(
                            "Sign up",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColorsData.primaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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

class LoginBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: CustomPaint(painter: LoginWavePainter()),
          ),
        ),
        Positioned(
          top: 155,
          right: 20,
          child: SizedBox(
            width: 130,  // Adjust as needed
            height: 130, // Adjust as needed
            child: AnimatedLogo(),
          ),
        ),

      ],
    );
  }
}
