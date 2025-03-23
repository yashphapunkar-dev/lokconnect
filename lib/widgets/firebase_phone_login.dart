import 'package:firebase_auth/firebase_auth.dart';

class FirebaseOTPAuth {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;

  Future<void> sendOTP(String phoneNumber, Function(String?) onCodeSent) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: '+91$phoneNumber',
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print("Verification Failed: ${e.message}");
       
      // showCustomAlert(context: context, title: "Alert", message: "Something went wrong please try again later!");      
      },

      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<UserCredential?> verifyOTP(String otp, String? verificationId) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otp,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Error verifying OTP: $e");
      return null;
    }
  }
}
