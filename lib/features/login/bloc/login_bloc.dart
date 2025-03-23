import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:lokconnect/widgets/firebase_phone_login.dart';
import 'package:meta/meta.dart';
part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final FirebaseOTPAuth _authService = FirebaseOTPAuth();

  LoginBloc() : super(LoginInitial()) {
    on<LoginEvent>((event, emit) {});
    on<SendOTPEvent>(userLogin);
    on<OTPSuccessEvent>(otpSuccessEvent);
  }

  Future<void> userLogin(SendOTPEvent event, Emitter<LoginState> emit) async {
   emit(LoadingState());
    try{
        _authService.sendOTP(event.phoneNumber, (verificationId) {
              add(OTPSuccessEvent(verificationId: verificationId));
        });
      } catch (e) {
          emit(OTPErrorState(errorMessage: "Error: ${e.toString()}"));
      }
  }

  FutureOr<void> otpSuccessEvent(OTPSuccessEvent event, Emitter<LoginState> emit) {
    // emit(LoadingCompletedState());
    emit(OTPSentState(verificationId: event.verificationId));
  }
}
