import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lokconnect/features/admin_user_service.dart';
import 'package:lokconnect/features/home/ui/home.dart';
import 'package:lokconnect/features/login/bloc/login_bloc.dart';
import 'package:lokconnect/features/login/ui/otp_verification.dart';
import 'package:lokconnect/widgets/custom_alert.dart';
import 'package:lokconnect/widgets/custom_button.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../../widgets/custom_input.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final LoginBloc loginBloc = LoginBloc();
  final Color mainColor = const Color(0xfff1efe7); // Made const
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false; // New state variable for password visibility

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

  Future<void> _handleEmailLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showCustomAlert(
        context: context,
        title: "Error",
        message: "Email and password are required.",
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Load admin data only after successful login
      await Provider.of<AdminUserService>(context, listen: false).loadAdminData();

      if (mounted) { // Check if the widget is still mounted before setState and navigation
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => Home()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showCustomAlert(
          context: context,
          title: "Login Failed",
          message: e.message ?? "Something went wrong.",
        );
      }
    }
  }

  // Function for password reset
  void _showForgotPasswordDialog() {
    TextEditingController resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Reset Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter your email to receive a password reset link."),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                resetEmailController.dispose();
              },
            ),
            ElevatedButton(
              child: const Text("Send Reset Email"),
              onPressed: () async {
                String email = resetEmailController.text.trim();
                if (email.isEmpty) {
                  showCustomAlert(
                    context: dialogContext,
                    title: "Error",
                    message: "Please enter your email.",
                  );
                  return;
                }

                Navigator.of(dialogContext).pop(); // Close the email input dialog
                resetEmailController.dispose();

                setState(() {
                  _isLoading = true;
                });

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                    showCustomAlert(
                      context: context,
                      title: "Password Reset",
                      message: "A password reset link has been sent to your email. Please check your inbox.",
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                    showCustomAlert(
                      context: context,
                      title: "Error",
                      message: e.message ?? "Failed to send reset email.",
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                    showCustomAlert(
                      context: context,
                      title: "Error",
                      message: "An unexpected error occurred.",
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
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
            height: 200,
            color: mainColor,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator()) // Show loader while logging in
                : Column(
                  children: [

                    CustomButton(
                        onPress: kIsWeb ? _handleEmailLogin : _handleLogin,
                        buttonText: "Login",
                      ),
                      TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
          ),
          body: Stack(
            children: [
              Container(
                color: mainColor,
                child: Center(
                  child: SingleChildScrollView(
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
                            image: const AssetImage('assets/logo_large.png'),
                            height: kIsWeb ? 100 : 300,
                            width: kIsWeb ? 400 : 300,
                          ),
                        ),
                        Container(
                          // width: 500,r
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              if (kIsWeb) ...[
                                CustomInput(
                                  textController: _emailController,
                                  hintText: "Enter your email",
                                  onSubmit: (_) => _handleEmailLogin(),
                                ),
                                const SizedBox(height: 12),
                                CustomInput(
                                  isSecure: !_isPasswordVisible,
                                  textController: _passwordController,
                                  hintText: "Enter your password",
                                  onSubmit: (_) => _handleEmailLogin(),
                                  suffixIcon: IconButton( // Add the suffix icon
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey, // Adjust color as needed
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8), // Spacing below password field
                                
                              ] else ...[
                                CustomInput(
                                  textController: _phoneController,
                                  hintText: "Enter your mobile number",
                                  onSubmit: (_) => _handleLogin(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
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