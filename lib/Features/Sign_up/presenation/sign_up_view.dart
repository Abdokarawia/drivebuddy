import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../../Core/Utils/App Colors.dart';
import '../../../core/Utils/Core Components.dart';
import '../../../core/Utils/Shared Methods.dart';
import '../../Home/view/presentation/home_view.dart';
import '../../Login/presenation/login_view.dart';

class SignUpView extends StatelessWidget {
  SignUpView({super.key});

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,  // Prevents auto-resize issues
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  SignUpBackground(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: size.height * 0.35),
                          FadeInText(
                            text: 'Create Account',
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
                            text: 'Join DriveBuddy today',
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                            delay: 700,
                          ),
                          SizedBox(height: 24),
                          _buildTextFields(),
                          SizedBox(height: 24),
                          AnimatedButton(
                            text: 'SIGN UP',
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                // Handle sign up logic
                              }
                            },
                            delay: 900,
                          ),
                          SizedBox(height: 12),
                          _buildLoginRedirect(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFields() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFieldTemplate(
            name: 'Username',
            label: 'Choose a Username',
            leadingIcon: Icons.person,
            boolleadingIcon: true,
            leadingIconColor: AppColorsData.primaryColor,
            enableFocusBorder: false,
            titel: "Username",
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Username is required'),
              FormBuilderValidators.minLength(3, errorText: 'Username must be at least 3 characters'),
            ]),
          ),
          SizedBox(height: 12),
          TextFieldTemplate(
            name: 'Email',
            label: 'Enter your Email',
            leadingIcon: Icons.email,
            boolleadingIcon: true,
            leadingIconColor: AppColorsData.primaryColor,
            enableFocusBorder: false,
            titel: "Email",
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Email is required'),
              FormBuilderValidators.email(errorText: 'Please enter a valid email'),
            ]),
          ),
          SizedBox(height: 12),
          TextFieldTemplate(
            titel: "Password",
            name: 'Password',
            label: 'Create Password',
            textEditingController: _passwordController,
            inputType: TextInputType.visiblePassword,
            leadingIconColor: AppColorsData.primaryColor,
            enableFocusBorder: false,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Password is required'),
              FormBuilderValidators.minLength(6, errorText: 'Password must be at least 6 characters'),
            ]),
          ),
          SizedBox(height: 12),
          TextFieldTemplate(
            titel: "Confirm Password",
            name: 'ConfirmPassword',
            label: 'Confirm Password',
            inputType: TextInputType.visiblePassword,
            leadingIconColor: AppColorsData.primaryColor,
            enableFocusBorder: false,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              } else if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRedirect(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account?",
          style: TextStyle(
            fontSize: 12,
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
              fontSize: 12,
              color: AppColorsData.primaryColor,
              fontWeight: FontWeight.w700,
            ),
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

class SignUpBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: CustomPaint(painter: SignUpWavePainter()),
          ),
        ),
        Positioned(
          top: 155,
          right: 20,
          child: SizedBox(
            width: 130,
            height: 130,
            child: AnimatedLogo(),
          ),
        ),
      ],
    );
  }
}