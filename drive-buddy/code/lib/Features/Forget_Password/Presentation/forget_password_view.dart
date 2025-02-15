import 'package:drivebuddy/Core/Utils/App%20Colors.dart';
import 'package:drivebuddy/core/Utils/Shared%20Methods.dart';
import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'dart:ui' as ui;
import '../../../core/Utils/Core Components.dart';
import '../../Home/view/presentation/home_view.dart';
import '../../Login/presenation/login_view.dart';
import '../../Reset_Password/presenation/Reset_Password_View.dart';

class ForgetPasswordView extends StatelessWidget {
  const ForgetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          LoginBackground(),
          Column(
            children: [
              Expanded(
                flex: 2,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size(size.width, size.height * 0.18),
                      painter: LoginWavePainter(),
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
                        text: 'Forgot Password?',
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
                        text: 'Enter your email to receive a password reset link.',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                        delay: 700,
                      ),
                      SizedBox(height: 24),
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          TextFieldTemplate(
                            name: 'Email',
                            label: 'Enter your Email',
                            leadingIcon: Icons.email,
                            boolleadingIcon: true,
                            leadingIconColor: AppColorsData.primaryColor,
                            enableFocusBorder: false,
                            titel: "Email",
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.email(),
                            ]),
                          ),
                          const SizedBox(height: 20),
                          AnimatedButton(
                            text: 'SEND RESET LINK',
                            onPressed: () {
                              navigateTo(context, ResetPasswordView());
                            },
                            delay: 900,
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Remember your password?",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
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
