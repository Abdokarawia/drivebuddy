import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../../../Core/Utils/App Colors.dart';
import '../../../../core/Utils/Shared Methods.dart';
import '../../../Home/view/presentation/home_view.dart';
import '../../../Main/view/presentation/Main_view.dart';
import '../../../Sign_up/presenation/sign_up_view.dart';
import '../../../Tabs/Presenation/tabs_view.dart';
import '../manger/login_cubit.dart';
import '../../../Forget_Password/Presentation/forget_password_view.dart'; // Added import

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _showSnackBar(BuildContext context, String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocProvider(
      create: (context) => LoginCubit(auth: FirebaseAuth.instance)..checkAuthState(),
      child: BlocListener<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            _showSnackBar(context, 'Welcome back!', true);
            Future.delayed(const Duration(seconds: 1), () {
              navigateTo(context,  TabsScreen(
                 state.user.email.toString(),
                state.user.uid.toString(),
                state.user.displayName.toString(),
              ),);
            });
          } else if (state is LoginFailure) {
            _showSnackBar(context, state.errorMessage, false);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      const LoginBackground(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: size.height * 0.35),
                              const FadeInText(
                                text: 'Welcome Back!',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                delay: 500,
                              ),
                              const SizedBox(height: 4),
                              const FadeInText(
                                textAlign: TextAlign.start,
                                text: 'Log in to your DriveBuddy account',
                                style: TextStyle(fontSize: 14, color: Colors.black54),
                                delay: 700,
                              ),
                              const SizedBox(height: 24),
                              _buildTextFields(),
                              const SizedBox(height: 12),
                              _buildForgotPassword(context), // Added Forgot Password link
                              const SizedBox(height: 12),
                              BlocBuilder<LoginCubit, LoginState>(
                                builder: (context, state) {
                                  return AnimatedButton(
                                    text: 'LOG IN',
                                    isLoading: state is LoginLoading,
                                    onPressed: () {
                                      if (_formKey.currentState?.validate() ?? false) {
                                        context.read<LoginCubit>().loginWithEmailAndPassword(
                                          email: _emailController.text.trim(),
                                          password: _passwordController.text.trim(),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildSignUpRedirect(context),
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
        ),
      ),
    );
  }

  Widget _buildTextFields() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            label: 'Enter your Email',
            icon: Icons.email,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Email is required'),
              FormBuilderValidators.email(
                errorText: 'Please enter a valid email address',
                regex: RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Enter your Password',
            icon: Icons.lock,
            controller: _passwordController,
            keyboardType: TextInputType.visiblePassword,
            obscureText: _obscurePassword,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Password is required'),
              FormBuilderValidators.minLength(6, errorText: 'Password must be at least 6 characters'),
            ]),
            trailing: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppColorsData.primaryColor,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPassword(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => navigateTo(context, const ForgetPasswordView()),
        child: Text(
          "Forgot Password?",
          style: TextStyle(
            fontSize: 12,
            color: AppColorsData.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpRedirect(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account?",
          style: TextStyle(fontSize: 12, color: Colors.black),
        ),
        TextButton(
          onPressed: () => navigateTo(context, SignUpView()),
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
    );
  }
}

// Custom Text Field
class CustomTextField extends StatelessWidget {
  final String label;
  final IconData? icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? trailing;

  const CustomTextField({
    super.key,
    required this.label,
    this.icon,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: AppColorsData.primaryColor) : null,
        suffixIcon: trailing,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColorsData.primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: validator,
    );
  }
}

// Background Components
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
  const LoginBackground({super.key});

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
            width: 130,
            height: 130,
            child: buildLogo(),
          ),
        ),
      ],
    );
  }
}

// Animation Components
class FadeInText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int delay;
  final TextAlign? textAlign;

  const FadeInText({
    super.key,
    required this.text,
    required this.style,
    required this.delay,
    this.textAlign = TextAlign.center,
  });

  @override
  State<FadeInText> createState() => _FadeInTextState();
}

class _FadeInTextState extends State<FadeInText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.delay),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SizedBox(
        width: double.infinity,
        child: Text(
          widget.text,
          style: widget.style,
          textAlign: widget.textAlign,
        ),
      ),
    );
  }
}

class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;
  final int animationDuration;

  const AnimatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.animationDuration = 200,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animationDuration),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isLoading) _controller.forward();
      },
      onTapUp: (_) {
        if (!widget.isLoading) {
          _controller.reverse();
          widget.onPressed();
        }
      },
      onTapCancel: () {
        if (!widget.isLoading) _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width ?? double.infinity,
              height: widget.height ?? 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: widget.isLoading ? null : widget.onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.backgroundColor ?? AppColorsData.primaryColor,
                  foregroundColor: widget.textColor ?? Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: widget.isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.textColor ?? Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget buildLogo() {
  return Container(
    width: 170,
    height: 170,
    child: Center(
      child: Image.asset(
        "assets/images/logo.png",
        width: 170 * 0.7,
        height: 170 * 0.7,
      ),
    ),
  );
}