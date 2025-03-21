import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore integration
import '../../data/UserModel.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore; // Optional: For Firestore integration

  LoginCubit({
    required FirebaseAuth auth,
    FirebaseFirestore? firestore, // Optional parameter
  }) : _auth = auth,
       _firestore = firestore ?? FirebaseFirestore.instance,
       super(LoginInitial());

  /// Logs in a user with email and password
  Future<void> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    emit(LoginLoading());
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      final user = userCredential.user;
      if (user != null) {
        final userModel = UserModel.fromFirebaseUser(user);

        emit(LoginSuccess(userModel));
      } else {
        emit(LoginFailure('Login failed: No user found'));
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = _mapFirebaseErrorToMessage(e);
      emit(LoginFailure(errorMessage));
    } catch (e) {
      emit(LoginFailure('An unexpected error occurred: $e'));
    }
  }

  /// Logs out the current user
  Future<void> logout() async {
    emit(LoginLoading());
    try {
      await _auth.signOut();
      emit(LoginInitial());
    } catch (e) {
      emit(LoginFailure('Failed to log out: $e'));
    }
  }

  /// Checks the current authentication state
  void checkAuthState() {
    final user = _auth.currentUser;
    if (user != null) {
      final userModel = UserModel.fromFirebaseUser(user);
      if (user.emailVerified) {
        emit(LoginSuccess(userModel));
      } else {
        emit(LoginInitial());
      }
    } else {
      emit(LoginInitial());
    }
  }

  /// Resends email verification if the user exists but isn't verified
  Future<void> resendEmailVerification(String email) async {
    emit(LoginLoading());
    try {
      final user = _auth.currentUser;
      if (user != null && user.email == email && !user.emailVerified) {
        await user.sendEmailVerification();
        emit(
          LoginFailure('Verification email resent. Please check your inbox.'),
        );
      } else {
        emit(LoginFailure('No unverified user found with this email.'));
      }
    } catch (e) {
      emit(LoginFailure('Failed to resend verification: $e'));
    }
  }

  /// Updates user profile (e.g., displayName or photoUrl)
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      emit(LoginLoading());
      try {
        await user.updateProfile(displayName: displayName, photoURL: photoUrl);
        await user.reload(); // Refresh user data
        final updatedUser = _auth.currentUser!;
        final userModel = UserModel.fromFirebaseUser(updatedUser);
        await _saveUserToFirestore(userModel); // Update Firestore
        emit(LoginSuccess(userModel));
      } catch (e) {
        emit(LoginFailure('Failed to update profile: $e'));
      }
    } else {
      emit(LoginFailure('No user is currently logged in.'));
    }
  }

  /// Saves or updates user data in Firestore
  Future<void> _saveUserToFirestore(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
            user.toMap(),
            SetOptions(merge: true), // Merge to avoid overwriting existing data
          );
    } catch (e) {
      print('Error saving user to Firestore: $e');
      // Optionally emit a failure state if this is critical
    }
  }

  /// Maps FirebaseAuthException codes to user-friendly messages
  String _mapFirebaseErrorToMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account exists with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'An error occurred: ${e.message ?? 'Unknown error'}';
    }
  }

  @override
  void onChange(Change<LoginState> change) {
    super.onChange(change);
    print('LoginCubit: $change'); // Debugging state changes
  }
}
