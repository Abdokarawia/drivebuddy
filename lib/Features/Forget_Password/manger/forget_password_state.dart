

abstract class ForgetPasswordState {}

class ForgetPasswordInitial extends ForgetPasswordState {}

class ForgetPasswordLoading extends ForgetPasswordState {}

class ForgetPasswordSuccess extends ForgetPasswordState {
  final String message;
  ForgetPasswordSuccess(this.message);
}

class ForgetPasswordFailure extends ForgetPasswordState {
  final String errorMessage;
  ForgetPasswordFailure(this.errorMessage);
}
