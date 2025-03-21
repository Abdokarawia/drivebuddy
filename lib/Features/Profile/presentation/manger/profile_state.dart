// profile_state.dart
import 'package:equatable/equatable.dart';
import '../../data/ProfileModel.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  // Initial state before any action has been taken
}

class ProfileLoading extends ProfileState {
  // State when profile data is being fetched, updated, or image is being removed
}

class ProfileLoaded extends ProfileState {
  final ProfileModel profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileUpdated extends ProfileState {
  final ProfileModel profile;

  const ProfileUpdated(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}