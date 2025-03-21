import 'package:bloc/bloc.dart';
import 'package:drivebuddy/Features/Sign_up/manger/sign_up_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import '../../Login/data/UserModel.dart';

class SignUpCubit extends Cubit<SignUpState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger('SignUpCubit');

  SignUpCubit({
    required FirebaseAuth auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(SignUpInitial()) {
    _setupLogging();
  }

  /// Sets up logging configuration
  void _setupLogging() {
    Logger.root.level = Level.ALL; // Log all levels
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

  /// Registers a new user with email, password, and username
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    _logger.info('Starting sign-up process for email: $email');
    emit(SignUpLoading());

    print(email);
    try {
      _logger.fine('Creating user with Firebase Authentication');
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        _logger.fine('User created successfully, UID: ${user.uid}');

        // Update display name
        _logger.fine('Updating display name to: $username');
        await user.updateDisplayName(username);

        // Create UserModel
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: username,
          photoUrl: user.photoURL,
        );
        _logger.fine('UserModel created: ${userModel.toMap()}');

        // Save user data to Firestore
        await _saveUserToFirestore(userModel);

        _logger.info('Sign-up completed successfully for user: ${user.uid}');
        emit(SignUpSuccess(
          userModel,
          'Account created successfully!',
        ));
      } else {
        _logger.warning('User creation failed: No user object returned');
        emit(SignUpFailure('Sign-up failed: No user created'));
      }
    } on FirebaseAuthException catch (e) {
      final errorMessage = _mapFirebaseErrorToMessage(e);
      _logger.severe('Firebase Authentication error: $errorMessage', e, StackTrace.current);
      emit(SignUpFailure(errorMessage));
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error during sign-up: $e', e, stackTrace);
      emit(SignUpFailure('An unexpected error occurred: $e'));
    }
  }

  /// Saves or updates user data in Firestore
  Future<void> _saveUserToFirestore(UserModel user) async {
    _logger.fine('Saving user data to Firestore for UID: ${user.uid}');
    try {
      await _firestore.collection('users').doc(user.uid).set(
        user.toMap(),
        SetOptions(merge: true),
      );
      _logger.fine('User data saved successfully to Firestore');
    } catch (e, stackTrace) {
      _logger.warning('Error saving user to Firestore: $e', e, stackTrace);
      // Optionally emit a failure state if this is critical
    }
  }

  /// Maps FirebaseAuthException codes to user-friendly messages
  String _mapFirebaseErrorToMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please use a different email.';
      case 'invalid-email':
        return 'The email address is not valid.';
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
    _logger.fine('State changed - Current: ${change.currentState}, Next: ${change.nextState}');
  }

  @override
  Future<void> close() {
    _logger.info('SignUpCubit closing');
    return super.close();
  }
}