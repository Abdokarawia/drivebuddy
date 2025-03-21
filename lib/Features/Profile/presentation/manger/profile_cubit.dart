// presentation/manger/profile_cubit.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drivebuddy/Features/Profile/data/ProfileModel.dart';
import 'package:drivebuddy/Features/Profile/presentation/manger/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileInitial());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _profileSubscription;

  Future<void> getProfile(String uid) async {
    try {
      emit(ProfileLoading());
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        emit(ProfileError('Profile not found'));
        return;
      }

      final profile = ProfileModel.fromJson(doc.data()!);
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError('Failed to load profile: ${e.toString()}'));
    }
  }

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      emit(ProfileLoading());

      // Prepare only the fields that are provided
      Map<String, dynamic> updateData = {};
      if (displayName != null) {
        if (displayName.trim().isEmpty) {
          emit(ProfileError('Display name cannot be empty'));
          return;
        }
        updateData['displayName'] = displayName;
      }
      if (email != null) {
        if (!_isValidEmail(email)) {
          emit(ProfileError('Invalid email format'));
          return;
        }
        updateData['email'] = email;
      }
      if (phoneNumber != null) {
        if (!_isValidPhone(phoneNumber)) {
          emit(ProfileError('Invalid phone number format'));
          return;
        }
        updateData['phoneNumber'] = phoneNumber;
      }

      if (updateData.isEmpty) {
        emit(ProfileError('No changes to update'));
        return;
      }

      // Update only the specified fields
      await _firestore.collection('users').doc(uid).update(updateData);

      // Fetch the updated profile
      final updatedDoc = await _firestore.collection('users').doc(uid).get();
      final updatedProfile = ProfileModel.fromJson(updatedDoc.data()!);

      emit(ProfileUpdated(updatedProfile));
    } catch (e) {
      emit(ProfileError('Failed to update profile: ${e.toString()}'));
    }
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  bool _isValidPhone(String phone) =>
      RegExp(r'^\+?1?\d{9,15}$').hasMatch(phone);
}