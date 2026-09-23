import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseOTPAuth {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _verificationId;

  Future<void> sendOTP(
    String phoneNumber,
    Function(String?) onCodeSent,
    Function(String)? onError,
  ) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: "+91$phoneNumber",
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth.signInWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (onError != null) {
            onError(e.message ?? "Something went wrong");
          }
          print("Auto-verification sign-in failed: ${e.message}");
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (onError != null) {
          onError(e.message ?? "Something went wrong");
        }
        print("Verification Failed: ${e.code} - ${e.message}");
      },
      codeSent: (String verificationId, int? resendToken) {
        print("Verification code sent, verificationId: $verificationId");
        _verificationId = verificationId;
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  /// Verifies the entered OTP and signs the user in.
  ///
  /// Throws [FirebaseAuthException] if the code is wrong/expired or the
  /// verification session is invalid — callers should catch this to show
  /// the user a specific message. A successful sign-in always returns a
  /// non-null [UserCredential], even if the Firestore bookkeeping below
  /// has a problem (that's logged but never fails the login).
  Future<UserCredential?> verifyOTP(String otp, String? verificationId) async {
    if (verificationId == null || verificationId.isEmpty) {
      throw FirebaseAuthException(
        code: 'session-expired',
        message: 'Verification session expired. Please request a new code.',
      );
    }

    final PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );

    // Let this throw on wrong/expired code, rate limiting, etc.
    // Do NOT catch-and-swallow here — the caller needs the real error code.
    final UserCredential userCredential =
        await _auth.signInWithCredential(credential);

    final User? user = userCredential.user;

    // From here on, sign-in has already succeeded. Any failure in the
    // Firestore sync below must not turn a successful login into a
    // "verification failed" for the user — just log it.
    if (user != null) {
      await _syncUserDoc(user);
    }

    return userCredential;
  }

  Future<void> _syncUserDoc(User user) async {
    try {
      final CollectionReference usersRef = _firestore.collection("users");
      final QuerySnapshot querySnapshot = await usersRef
          .where("phoneNumber", isEqualTo: user.phoneNumber)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // No existing doc for this phone number → new user.
        await usersRef.add({
          "phoneNumber": user.phoneNumber,
          "createdAt": FieldValue.serverTimestamp(),
          "role": "user",
        });
        print("✅ New user added to Firestore");
      } else {
        // Existing user → nothing to create.
        print("✅ User already exists, proceeding to login...");
      }
    } catch (e) {
      // Non-fatal: the user is already signed in via Firebase Auth even if
      // this Firestore step fails (e.g. permission-denied, network issue).
      print("⚠️ Firestore user-doc sync failed (non-fatal): $e");
    }
  }
}