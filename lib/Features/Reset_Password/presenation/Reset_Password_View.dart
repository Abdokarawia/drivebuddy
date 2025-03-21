import 'package:drivebuddy/Core/Utils/App%20Colors.dart';
import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../../core/Utils/Core Components.dart';
import '../../Home/view/presentation/home_view.dart';
import '../../Sign_up/presenation/sign_up_view.dart';

class ResetPasswordView extends StatelessWidget {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          ResetPasswordBackground(),
          Column(
            children: [
              Expanded(
                flex: 2,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size(size.width, size.height * 0.18),
                      painter: ResetPasswordWavePainter(),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: SizedBox(
                          width: size.width,
                          height: size.height * 0.36,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [buildLogo()],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInText(
                        text: 'Reset Password',
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
                        text: 'Enter your new password below',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                        delay: 700,
                      ),
                      SizedBox(height: 24),
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          TextFieldTemplate(
                            name: 'NewPassword',
                            label: 'Enter New Password',
                            inputType: TextInputType.visiblePassword,
                            leadingIconColor: AppColorsData.primaryColor,
                            enableFocusBorder: false,
                            titel: "New Password",
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.minLength(6,
                                  errorText:
                                  "Password must be at least 6 characters"),
                            ]),
                          ),
                          const SizedBox(height: 12),
                          TextFieldTemplate(
                            name: 'ConfirmPassword',
                            label: 'Confirm Password',
                            inputType: TextInputType.visiblePassword,
                            leadingIconColor: AppColorsData.primaryColor,
                            enableFocusBorder: false,
                            titel: "Confirm Password",
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.minLength(6,
                                  errorText:
                                  "Password must be at least 6 characters"),
                            ]),
                          ),
                          const SizedBox(height: 20),
                          AnimatedButton(
                            text: 'RESET PASSWORD',
                            onPressed: () {
                              // Add Reset Password logic here
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ResetPasswordWavePainter extends CustomPainter {
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

class ResetPasswordBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: CustomPaint(painter: ResetPasswordWavePainter()),
          ),
        ),
      ],
    );
  }
}
