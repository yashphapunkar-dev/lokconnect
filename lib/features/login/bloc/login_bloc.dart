import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:lokconnect/widgets/firebase_phone_login.dart';
import 'package:meta/meta.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final FirebaseOTPAuth _authService = FirebaseOTPAuth();

  LoginBloc() : super(LoginInitial()) {
    on<SendOTPEvent>(userLogin);
    on<OTPSuccessEvent>(otpSuccessEvent);
    on<OTPErrorEvent>(otpErrorEvent);
  }

  Future<void> userLogin(SendOTPEvent event, Emitter<LoginState> emit) async {
    try {
      _authService.sendOTP(event.phoneNumber, (verificationId) {
        add(OTPSuccessEvent(verificationId: verificationId, phoneNumber: event.phoneNumber));
      }, (error) {
        add(OTPErrorEvent(errorMessage: "OTP request failed: ${error.toString()}"));
      });
    } catch (e) {
      emit(OTPErrorState(errorMessage: "OTP request failed: ${e.toString()}"));
    }
  }

  FutureOr<void> otpSuccessEvent(OTPSuccessEvent event, Emitter<LoginState> emit) {
    emit(OTPSentState(verificationId: event.verificationId, phoneNumber: event.phoneNumber));
  }

  FutureOr<void> otpErrorEvent(OTPErrorEvent event, Emitter<LoginState> emit) {
     emit(OTPErrorState(errorMessage: event.errorMessage));
  }
}
