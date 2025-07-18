part of 'login_bloc.dart';

@immutable
sealed class LoginEvent {}

class SendOTPEvent extends LoginEvent {
  final String phoneNumber;
  SendOTPEvent({required this.phoneNumber});
}

class OTPSuccessEvent extends LoginEvent{
   final String? verificationId;
   final String? phoneNumber;
   OTPSuccessEvent({required this.verificationId, required this.phoneNumber});
}

class OTPErrorEvent extends LoginEvent{
  final String errorMessage;
  OTPErrorEvent({required this.errorMessage});
}

