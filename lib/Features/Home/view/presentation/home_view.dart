import 'package:drivebuddy/Core/Utils/App%20Colors.dart';
import 'package:drivebuddy/Features/Login/presenation/login_view.dart';
import 'package:drivebuddy/Features/Sign_up/presenation/sign_up_view.dart';
import 'package:flutter/material.dart';

import '../../../../core/Utils/Shared Methods.dart';

class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          AnimatedBackground(),
          Column(
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size(size.width, size.height),
                      painter: WaveBorderPainter(),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: size.width,
                        height: size.height * 0.5,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [AnimatedLogo()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FadeInText(
                      text: 'DriveBuddy',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      delay: 500,
                    ),
                    SizedBox(height: 8),
                    FadeInText(
                      text: 'Unlock the mystery behind every dashboard alert\n'
                          'Drive smarter and safer with us!',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                      delay: 700,
                    ),
                    SizedBox(height: 32),
                    AnimatedButton(
                      text: 'CREATE ACCOUNT',
                      onPressed: () {
                        navigateTo(context, SignUpView());

                      },
                      delay: 900,
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: TextStyle(fontSize: 14, color: Colors.black),
                        ),
                        TextButton(onPressed: (){
                          navigateTo(context, LoginView());

                        }, child: Text(
                          "Log in",
                          style:TextStyle(fontSize: 14, color: AppColorsData.primaryColor, fontWeight: FontWeight.w700),
                        ),)

                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WaveBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = AppColorsData.primaryColor
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.lineTo(0, size.height * 0.9);
    path.quadraticBezierTo(
        size.width * 0.25, size.height * 0.99, size.width * 0.5, size.height * 0.8);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.6, size.width, size.height * 0.8);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}



class AnimatedBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(decoration: BoxDecoration(color: Colors.white)),
    );
  }
}

class AnimatedLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 70,
      backgroundColor: AppColorsData.white,
      child: Image.asset("assets/images/logo.png")
    );
  }
}

class FadeInText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final int delay;
  TextAlign? textAlign;

  FadeInText({required this.text, required this.style, required this.delay, this.textAlign = TextAlign.center});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}

class AnimatedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final int delay;

  AnimatedButton({required this.text, required this.onPressed, required this.delay});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsData.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
}
