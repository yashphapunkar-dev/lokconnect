part of 'login_bloc.dart';

@immutable
sealed class LoginState {}

abstract class LoginActionState extends LoginState{}

final class LoginInitial extends LoginState {}

class PhoneLogin extends LoginActionState{}

class LoadingState extends LoginActionState{}

class LoadingCompletedState extends LoginActionState{}

class OTPSentState extends LoginActionState {
  final String? verificationId;
  OTPSentState({required this.verificationId});
}

class OTPErrorState extends LoginActionState {
  final String errorMessage;
  OTPErrorState({required this.errorMessage});
}
