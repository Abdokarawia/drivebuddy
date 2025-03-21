import '../../Login/data/UserModel.dart';

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