import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lokconnect/features/user_details/ui/user_member_home_page.dart';
import 'package:lokconnect/widgets/firebase_phone_login.dart';
import 'package:lokconnect/theme/app_palette.dart'; // adjust import path to match your project

class OTPScreen extends StatefulWidget {
  final String? verificationId;
  final String? phoneNumber;
  OTPScreen({required this.verificationId, required this.phoneNumber});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> with TickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final FirebaseOTPAuth _authService = FirebaseOTPAuth();

  bool isLoading = false;

  late final AnimationController _entrance;
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();
    _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat(reverse: true);
    for (final node in _focusNodes) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final n in _focusNodes) n.dispose();
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

  String getOtp() {
    return _controllers.map((controller) => controller.text).join();
  }

  void _verifyOTP(String otp, String? verification, AppPalette palette) async {
    setState(() => isLoading = true);

    UserCredential? user = await _authService.verifyOTP(otp, verification);

    setState(() => isLoading = false);

    if (user != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => UserMemberHomePage(phoneNumber: widget.phoneNumber!)),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP Verified Successfully")),
      );
    } else {
      print("OTP RESPONSE!");
      print(user);
      await Flushbar(
        flushbarPosition: FlushbarPosition.BOTTOM,
        title: 'Alert',
        message: 'Please enter a valid OTP!',
        backgroundColor: palette.card,
        titleColor: palette.gold,
        messageColor: palette.textPrimary,
        duration: const Duration(seconds: 3),
      ).show(context);
    }
  }

  TextStyle _serif(AppPalette palette, {double size = 26, FontWeight weight = FontWeight.w700, Color? color}) {
    return TextStyle(
      fontFamily: 'serif',
      fontSize: size,
      fontWeight: weight,
      color: color ?? palette.textPrimary,
      height: 1.15,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.bg,
      body: Stack(
        children: [
          _AmbientBackground(controller: _ambient, palette: palette),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _slideFade(
                      interval: _iv(0.0, 0.4),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(color: palette.card, shape: BoxShape.circle),
                        child: Icon(Icons.sms_outlined, color: palette.gold, size: 34),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _slideFade(
                      interval: _iv(0.1, 0.45),
                      child: Text("Verify OTP", style: _serif(palette, size: 24), textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 10),
                    _slideFade(
                      interval: _iv(0.15, 0.5),
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(color: palette.textPrimary.withOpacity(0.6), fontSize: 13.5, height: 1.4),
                          children: [
                            const TextSpan(text: "Enter the 6-digit code sent to\n"),
                            TextSpan(
                              text: "+91 ${widget.phoneNumber ?? ''}",
                              style: TextStyle(color: palette.gold, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 34),
                    _slideFade(interval: _iv(0.3, 0.65), child: _buildOtpRow(palette)),
                    const SizedBox(height: 30),
                    if (isLoading)
                      SizedBox(
                        height: 26,
                        width: 26,
                        child: CircularProgressIndicator(strokeWidth: 2.6, color: palette.gold),
                      ),
                    if (!isLoading)
                      _slideFade(interval: _iv(0.5, 0.85), child: _buildVerifyButton(palette)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpRow(AppPalette palette) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final focused = _focusNodes[index].hasFocus;
        return Container(
          width: 44,
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: palette.card, // same as card bg, not a separate boxed fill — avoids the "heavy box" look
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: focused ? palette.gold : palette.divider.withOpacity(0.3),
              width: focused ? 1.6 : 0.75,
            ),
            boxShadow: focused
                ? [BoxShadow(color: palette.gold.withOpacity(0.25), blurRadius: 10, spreadRadius: 1)]
                : null,
          ),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: TextStyle(color: palette.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
            cursorColor: palette.gold,
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
              }
              if (index == 5 && value.isNotEmpty) {
                FocusScope.of(context).unfocus();
              }
            },
            decoration: const InputDecoration(
              counterText: "",
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVerifyButton(AppPalette palette) {
    return _TapScale(
      onTap: () {
        String otp = getOtp();
        print("Entered OTP: $otp");
        _verifyOTP(otp, widget.verificationId, palette);
      },
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_rounded, color: palette.textPrimary, size: 20),
            const SizedBox(width: 8),
            Text("Verify", style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700, fontSize: 15.5)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Ambient background — themed, matches login screen
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
              right: -60 + 30 * t,
              child: _glowOrb(220, palette.gold.withOpacity(0.10)),
            ),
            Positioned(
              bottom: -100 + 20 * (1 - t),
              left: -70 + 25 * (1 - t),
              child: _glowOrb(240, const Color(0xFF6FCF97).withOpacity(0.06)),
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