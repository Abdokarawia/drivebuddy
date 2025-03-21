import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import '../../../Core/Utils/App Colors.dart';
import '../../../core/Utils/Shared Methods.dart';
import '../../Login/presenation/view/login_view.dart';
import '../../Login/data/UserModel.dart';
import '../../Main/view/presentation/Main_view.dart';
import '../../Tabs/Presenation/tabs_view.dart';

// SignUpCubit with Logging
class SignUpCubit extends Cubit<SignUpState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger('SignUpCubit');

  SignUpCubit({required FirebaseAuth auth, FirebaseFirestore? firestore})
    : _auth = auth,
      _firestore = firestore ?? FirebaseFirestore.instance,
      super(SignUpInitial()) {
    _setupLogging();
  }

  void _setupLogging() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
      if (record.error != null) {
        print('Error: ${record.error}');
      }
      if (record.stackTrace != null) {
        print('Stacktrace: ${record.stackTrace}');
      }
    });
    _logger.fine('SignUpCubit initialized');
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    _logger.info('Starting sign-up process for email: $email');
    emit(SignUpLoading());
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      final user = userCredential.user;
      if (user != null) {
        _logger.fine('User created successfully, UID: ${user.uid}');
        await user.updateDisplayName(username);
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: username,
          photoUrl: user.photoURL,
        );
        await _saveUserToFirestore(userModel);
        _logger.info('Sign-up completed successfully for user: ${user.uid}');
        emit(SignUpSuccess(userModel, 'Account created successfully!'));
      } else {
        _logger.warning('User creation failed: No user object returned');
        emit(SignUpFailure('Sign-up failed: No user created'));
      }
    } on FirebaseAuthException catch (e) {
      final errorMessage = _mapFirebaseErrorToMessage(e);
      _logger.severe(
        'Firebase Authentication error: $errorMessage',
        e,
        StackTrace.current,
      );
      emit(SignUpFailure(errorMessage));
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error during sign-up: $e', e, stackTrace);
      emit(SignUpFailure('An unexpected error occurred: $e'));
    }
  }

  Future<void> _saveUserToFirestore(UserModel user) async {
    _logger.fine('Saving user data to Firestore for UID: ${user.uid}');
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
      _logger.fine('User data saved successfully to Firestore');
    } catch (e, stackTrace) {
      _logger.warning('Error saving user to Firestore: $e', e, stackTrace);
    }
  }

  String _mapFirebaseErrorToMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please use a different email.';
      case 'invalid-email':
        _logger.warning('Invalid email format attempted: ${e.email}');
        return 'The email address is invalid. Please use a properly formatted email (e.g., user@example.com)';
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'An error occurred: ${e.message ?? 'Unknown error'}';
    }
  }

  @override
  void onChange(Change<SignUpState> change) {
    super.onChange(change);
    _logger.fine(
      'State changed - Current: ${change.currentState}, Next: ${change.nextState}',
    );
  }

  @override
  Future<void> close() {
    _logger.info('SignUpCubit closing');
    return super.close();
  }
}

// SignUpState
abstract class SignUpState {}

class SignUpInitial extends SignUpState {}

class SignUpLoading extends SignUpState {}

class SignUpSuccess extends SignUpState {
  final UserModel user;
  final String message;
  SignUpSuccess(this.user, this.message);
}

class SignUpFailure extends SignUpState {
  final String errorMessage;
  SignUpFailure(this.errorMessage);
}

// Custom Text Field
class CustomTextField extends StatelessWidget {
  final String label;
  final IconData? icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Color? iconColor;

  const CustomTextField({
    super.key,
    required this.label,
    this.icon,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            icon != null
                ? Icon(icon, color: iconColor ?? AppColorsData.primaryColor)
                : null,
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      validator: validator,
    );
  }
}

// SignUpView
class SignUpView extends StatelessWidget {
  SignUpView({super.key});

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();

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
              child: Text(message, style: const TextStyle(color: Colors.white)),
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
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocProvider(
      create:
          (context) => SignUpCubit(
            auth: FirebaseAuth.instance,
            firestore: FirebaseFirestore.instance,
          ),
      child: BlocListener<SignUpCubit, SignUpState>(
        listener: (context, state) {
          if (state is SignUpSuccess) {
            _showSnackBar(context, state.message, true);
            Future.delayed(const Duration(seconds: 1), () {
              navigateTo(
                context,
                TabsScreen(
                    state.user.email.toString(),
                    state.user.uid.toString(),
                  state.user.displayName.toString(),
                ),
              );
            });
          } else if (state is SignUpFailure) {
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
                      const SignUpBackground(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: size.height * 0.35),
                              const FadeInText(
                                text: 'Create Account',
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
                                text: 'Join DriveBuddy today',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                                delay: 700,
                              ),
                              const SizedBox(height: 24),
                              _buildTextFields(),
                              const SizedBox(height: 24),
                              BlocBuilder<SignUpCubit, SignUpState>(
                                builder: (context, state) {
                                  return AnimatedButton(
                                    text: 'SIGN UP',
                                    isLoading: state is SignUpLoading,
                                    onPressed: () {
                                      if (_formKey.currentState?.validate() ??
                                          false) {
                                        context
                                            .read<SignUpCubit>()
                                            .signUpWithEmailAndPassword(
                                              email: _emailController.text,
                                              password:
                                                  _passwordController.text,
                                              username:
                                                  _usernameController.text,
                                            );
                                      }
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
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
            label: 'Choose a Username',
            icon: Icons.person,
            controller: _usernameController,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Username is required'),
              FormBuilderValidators.minLength(
                3,
                errorText: 'Username must be at least 3 characters',
              ),
            ]),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Enter your Email',
            icon: Icons.email,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Email is required'),
              FormBuilderValidators.email(
                errorText: 'Please enter a valid email address',
                regex: RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Create Password',
            icon: Icons.lock,
            controller: _passwordController,
            keyboardType: TextInputType.visiblePassword,
            obscureText: true,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Password is required'),
              FormBuilderValidators.minLength(
                6,
                errorText: 'Password must be at least 6 characters',
              ),
            ]),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Confirm Password',
            icon: Icons.lock,
            keyboardType: TextInputType.visiblePassword,
            obscureText: true,
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
        const Text(
          "Already have an account?",
          style: TextStyle(fontSize: 12, color: Colors.black),
        ),
        TextButton(
          onPressed: () {
            navigateTo(context, const LoginView());
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

// Background Components
class SignUpWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint =
        Paint()
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
  const SignUpBackground({super.key});

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
            child: buildLogo(), // Assuming buildLogo() is defined elsewhere
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

class _FadeInTextState extends State<FadeInText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.delay),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
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

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animationDuration),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
                  backgroundColor:
                      widget.backgroundColor ?? AppColorsData.primaryColor,
                  foregroundColor: widget.textColor ?? Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child:
                    widget.isLoading
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
