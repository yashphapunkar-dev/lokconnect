import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lokconnect/constants/custom_colors.dart';
import 'package:lokconnect/features/home/ui/home.dart';
import 'package:lokconnect/widgets/firebase_phone_login.dart';

class OTPScreen extends StatefulWidget {
  final String? verificationId;
  OTPScreen({required this.verificationId});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final FirebaseOTPAuth _authService = FirebaseOTPAuth();
  
  bool isLoading = false; // Loader state

  String getOtp() {
    return _controllers.map((controller) => controller.text).join();
  }

  void _verifyOTP(String otp, String? verification) async {
    setState(() {
      isLoading = true; // Start loader
    });

    UserCredential? user = await _authService.verifyOTP(otp, verification);

    setState(() {
      isLoading = false; // Stop loader
    });

    if (user != null) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => Home()));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OTP Verified Successfully")),
      );
    } else {
      await Flushbar(
        flushbarPosition: FlushbarPosition.BOTTOM,
        title: 'Alert',
        message: 'Please enter a valid OTP!',
        duration: Duration(seconds: 3),
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Please enter OTP received on your phone number.",
              style: CustomTextStyle.subHeadingTextStyle,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Container(
                  width: 40,
                  height: 50,
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                      } else if (value.isEmpty && index > 0) {
                        FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                      }
                    },
                    decoration: InputDecoration(
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 20),
            if (isLoading) CircularProgressIndicator(), // Loader
            SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: isLoading
            ? null
            : () {
                String otp = getOtp();
                print("Entered OTP: $otp");
                _verifyOTP(otp, widget.verificationId);
              },
        child: Icon(Icons.check, color: Colors.white,),
      ),
    );
  }
}
