// lib/Features/Forget_Password/manger/forget_password_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'forget_password_state.dart';

class ForgetPasswordCubit extends Cubit<ForgetPasswordState> {
  final FirebaseAuth _auth;

  ForgetPasswordCubit({required FirebaseAuth auth})
      : _auth = auth,
        super(ForgetPasswordInitial());

  Future<void> resetPassword(String email) async {
    emit(ForgetPasswordLoading());
    try {
      await _auth.sendPasswordResetEmail(email: email);
      emit(ForgetPasswordSuccess('Password reset email sent! Check your inbox.'));
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message ?? 'Unknown error'}';
      }
      emit(ForgetPasswordFailure(errorMessage));
    } catch (e) {
      emit(ForgetPasswordFailure('An unexpected error occurred.'));
    }
  }
}