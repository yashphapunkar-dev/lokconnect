part of 'login_bloc.dart';

@immutable
sealed class LoginEvent {}

class SendOTPEvent extends LoginEvent {
  final String phoneNumber;
  SendOTPEvent({required this.phoneNumber});
}

class OTPSuccessEvent extends LoginEvent{
   final String? verificationId;
   OTPSuccessEvent({required this.verificationId});
}

class OTPFailureEvent extends LoginEvent{}
