part of 'login_cubit.dart';

abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final UserModel user;

  LoginSuccess(this.user);

  @override
  String toString() => 'LoginSuccess(user: $user)';
}

class LoginFailure extends LoginState {
  final String errorMessage;

  LoginFailure(this.errorMessage);

  @override
  String toString() => 'LoginFailure(errorMessage: $errorMessage)';
}