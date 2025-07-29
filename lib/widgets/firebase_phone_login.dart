import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseOTPAuth {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _verificationId;

  Future<void> sendOTP(String phoneNumber, Function(String?) onCodeSent, Function(String)? onError) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: "+91${phoneNumber}",
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (onError != null) {
        onError(e.message ?? "Something went wrong");
      }
        print("Verification Failed: ${e.message}");      
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

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      CollectionReference usersRef = _firestore.collection("users");
      QuerySnapshot querySnapshot = await usersRef
          .where("phoneNumber", isEqualTo: "+91${user!.phoneNumber}")
          .get();
      if (querySnapshot.docs.isNotEmpty) {
          await _firestore.collection('users').add({
            "phoneNumber": user.phoneNumber,
            "createdAt": FieldValue.serverTimestamp(),
            "role": "user"
          });
          print("✅ New user added to Firestore");
      }
      else {
          print("✅ User already exists, proceeding to login...");
        }
      return userCredential;
    } catch (e) {
      print("❌ Error verifying OTP: $e");
      return null;
    }
  }
}
