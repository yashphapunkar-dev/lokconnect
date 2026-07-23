import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:lokconnect/features/admin_user_service.dart';
import 'package:lokconnect/features/home/ui/home.dart';
import 'package:lokconnect/features/login/bloc/login_bloc.dart';
import 'package:lokconnect/features/login/ui/otp_verification.dart';
import 'package:lokconnect/widgets/custom_alert.dart';
import 'package:lottie/lottie.dart';
import 'package:lokconnect/theme/app_palette.dart';
import 'package:lokconnect/theme/theme_controller.dart';

TextStyle _serif(BuildContext context, {double size = 30, FontWeight weight = FontWeight.w700, Color? color}) {
  return TextStyle(
    fontFamily: 'serif',
    fontSize: size,
    fontWeight: weight,
    color: color ?? context.palette.textPrimary,
    height: 1.15,
  );
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with TickerProviderStateMixin {
  final LoginBloc loginBloc = LoginBloc();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  late final AnimationController _entrance;
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
    _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _entrance.dispose();
    _ambient.dispose();
    super.dispose();
  }

  Animation<double> _iv(double start, double end) =>
      CurvedAnimation(parent: _entrance, curve: Interval(start, end, curve: Curves.easeOutCubic));

  Widget _slideFade({required Animation<double> interval, required Widget child}) {
    return FadeTransition(
      opacity: interval,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(interval),
        child: child,
      ),
    );
  }

  void _handleLogin() {
    String phoneNumber = _phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      showCustomAlert(context: context, title: "Error", message: "Please enter your mobile number");
      return;
    } else if (!RegExp(r'^[0-9]{10}$').hasMatch(phoneNumber)) {
      showCustomAlert(
        context: context,
        title: "Invalid Number",
        message: "Please enter a valid 10-digit mobile number.",
      );
      return;
    }

    setState(() => _isLoading = true);
    loginBloc.add(SendOTPEvent(phoneNumber: phoneNumber));
  }

  Future<void> _handleEmailLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showCustomAlert(context: context, title: "Error", message: "Email and password are required.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      await Provider.of<AdminUserService>(context, listen: false).loadAdminData();

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => Home()));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showCustomAlert(context: context, title: "Login Failed", message: e.message ?? "Something went wrong.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return BlocConsumer<LoginBloc, LoginState>(
      bloc: loginBloc,
      listenWhen: (previous, current) => current is LoginActionState,
      buildWhen: (previous, current) => current is! LoginActionState,
      listener: (context, state) {
        if (state is OTPSentState) {
          setState(() => _isLoading = false);
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => OTPScreen(
              verificationId: state.verificationId,
              phoneNumber: state.phoneNumber,
            ),
          ));
        } else if (state is OTPErrorState) {
          setState(() => _isLoading = false);
          showCustomAlert(context: context, title: "Error", message: state.errorMessage);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: palette.bg,
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              _AmbientBackground(controller: _ambient, palette: palette),
              SafeArea(
                child: Stack(
                  children: [
                    // Global light/dark toggle — top-right corner
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Consumer<ThemeController>(
                        builder: (context, themeController, _) {
                          return IconButton(
                            onPressed: themeController.toggleTheme,
                            icon: Icon(
                              themeController.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              color: palette.gold,
                            ),
                          );
                        },
                      ),
                    ),
                    Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _slideFade(interval: _iv(0.0, 0.4), child: _buildLogo()),
                            const SizedBox(height: 8),
                            _slideFade(interval: _iv(0.1, 0.45), child: _buildHeadline(palette)),
                            const SizedBox(height: 34),
                            _slideFade(interval: _iv(0.25, 0.6), child: _buildFormCard(palette)),
                            const SizedBox(height: 26),
                            _slideFade(interval: _iv(0.55, 0.85), child: _buildLoginButton(palette)),
                            const SizedBox(height: 22),
                            _slideFade(
                              interval: _iv(0.7, 1.0),
                              child: Text(
                                "Appledore Consulting Group©",
                                style: TextStyle(color: palette.textMuted, fontWeight: FontWeight.w500, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      height: 130,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Lottie.asset('assets/animationlogo.json', fit: BoxFit.contain, repeat: true),
      ),
    );
  }

  Widget _buildHeadline(AppPalette palette) {
    return Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: "Welcome to\n", style: _serif(context, size: 26)),
              TextSpan(text: "LokConnect", style: _serif(context, size: 30, color: palette.gold)),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          "Sign in to access your property records and documents.",
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.textPrimary.withOpacity(0.6), fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildFormCard(AppPalette palette) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
  color: palette.divider.withOpacity(0.25),
  width: 0.75,
),
      ),
      child: kIsWeb
          ? Column(
              children: [
                _ThemedInputField(
                  palette: palette,
                  controller: _emailController,
                  hint: "Enter your email",
                  icon: Icons.mail_outline_rounded,
                  onSubmitted: (_) => _handleEmailLogin(),
                ),
                const SizedBox(height: 14),
                _ThemedInputField(
                  palette: palette,
                  controller: _passwordController,
                  hint: "Enter your password",
                  icon: Icons.lock_outline_rounded,
                  obscure: !_isPasswordVisible,
                  onSubmitted: (_) => _handleEmailLogin(),
                  suffix: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: palette.textMuted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
              ],
            )
          : _ThemedInputField(
              palette: palette,
              controller: _phoneController,
              hint: "10-digit mobile number",
              icon: Icons.phone_iphone_rounded,
              keyboardType: TextInputType.phone,
              prefixText: "+91  ",
              onSubmitted: (_) => _handleLogin(),
            ),
    );
  }

  Widget _buildLoginButton(AppPalette palette) {
    return _TapScale(
      onTap: _isLoading ? () {} : (kIsWeb ? _handleEmailLogin : _handleLogin),
      child: Container(
        width: double.infinity,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.gold,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: palette.gold.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: _isLoading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.6, color: palette.textPrimary),
              )
            : Text(
                "Login",
                style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700, fontSize: 15.5),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Themed input field — reads colors from AppPalette, works in light/dark
// ─────────────────────────────────────────────────────────────────────────
class _ThemedInputField extends StatelessWidget {
  final AppPalette palette;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final String? prefixText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  const _ThemedInputField({
    required this.palette,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.prefixText,
    this.keyboardType,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: palette.divider.withOpacity(0.35), // 👈 THE BORDER
          width: 0.75,)
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        style: TextStyle(color: palette.textPrimary, fontSize: 14.5),
        cursorColor: palette.gold,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 4, right: 2),
            child: Icon(icon, size: 19, color: palette.gold),
          ),
          prefixText: prefixText,
          prefixStyle: TextStyle(color: palette.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w600),
          suffixIcon: suffix,
          hintText: hint,
          hintStyle: TextStyle(color: palette.textMuted, fontSize: 13.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Ambient background — themed, works in light/dark
// ─────────────────────────────────────────────────────────────────────────
class _AmbientBackground extends StatelessWidget {
  final AnimationController controller;
  final AppPalette palette;
  const _AmbientBackground({required this.controller, required this.palette});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Stack(
          children: [
            Container(color: palette.bg),
            Positioned(
              top: -80 + 20 * t,
              left: -60 + 30 * t,
              child: _glowOrb(220, palette.gold.withOpacity(0.10)),
            ),
            Positioned(
              bottom: -100 + 20 * (1 - t),
              right: -70 + 25 * (1 - t),
              child: _glowOrb(260, const Color(0xFF6FCF97).withOpacity(0.06)),
            ),
          ],
        );
      },
    );
  }

  Widget _glowOrb(double size, Color color) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapScale({required this.child, required this.onTap});

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}