import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lokconnect/features/login/bloc/login_bloc.dart';
import 'package:lokconnect/features/login/ui/otp_verification.dart';
import 'package:lokconnect/widgets/custom_alert.dart';
import 'package:lokconnect/widgets/custom_button.dart';
import 'package:lottie/lottie.dart';
import '../../../widgets/custom_input.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final LoginBloc loginBloc = LoginBloc();
  final Color mainColor = Color(0xfff1efe7);
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;

  void _handleLogin() {
    String phoneNumber = _phoneController.text.trim();

    // ✅ Validate phone number format
    if (phoneNumber.isEmpty) {
      showCustomAlert(
        context: context,
        title: "Error",
        message: "Please enter your mobile number",
      );
      return;
    } else if (!RegExp(r'^[0-9]{10}$').hasMatch(phoneNumber)) {
      showCustomAlert(
        context: context,
        title: "Invalid Number",
        message: "Please enter a valid 10-digit mobile number.",
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    loginBloc.add(SendOTPEvent(phoneNumber: phoneNumber));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      bloc: loginBloc,
      listenWhen: (previous, current) => current is LoginActionState,
      buildWhen: (previous, current) => current is! LoginActionState,
      listener: (context, state) {
        if (state is OTPSentState) {
          setState(() {
            _isLoading = false;
          });
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => OTPScreen(verificationId: state.verificationId),
          ));
        } else if (state is OTPErrorState) {
          setState(() {
            _isLoading = false;
          });
          showCustomAlert(
            context: context,
            title: "Error",
            message: state.errorMessage,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          bottomNavigationBar: Container(
            height: 120,
            color: mainColor,
            child: _isLoading
                ? Center(child: CircularProgressIndicator()) // Show loader while logging in
                : CustomButton(
                    onPress: _handleLogin,
                    buttonText: "Login",
                  ),
          ),
          body: Stack(
            children: [
              Container(
                color: mainColor,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/animationlogo.json',
                        fit: BoxFit.cover,
                        repeat: true,
                        height: kIsWeb ? 200 : 300,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: Image(
                          image: AssetImage('assets/logo_large.png'),
                          height: kIsWeb ? 100 : 300,
                          width: kIsWeb ? 400 : 300,
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 20, right: 20),
                        child: Column(
                          children: [
                            CustomInput(
                              textController: _phoneController,
                              hintText: "Enter your mobile number",
                              onSubmit: (value) => _handleLogin(),
                              // keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
