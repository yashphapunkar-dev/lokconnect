import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lokconnect/features/home/models/user_model.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:lokconnect/theme/app_palette.dart'; // adjust import path to match your project

TextStyle _serif(
  AppPalette palette, {
  double size = 30,
  FontWeight weight = FontWeight.w700,
  Color? color,
}) {
  return TextStyle(
    fontFamily: 'serif',
    fontSize: size,
    fontWeight: weight,
    color: color ?? palette.textPrimary,
    height: 1.15,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────
class UserMemberHomePage extends StatefulWidget {
  final String phoneNumber;

  const UserMemberHomePage({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  State<UserMemberHomePage> createState() => _UserMemberHomePageState();
}

class _UserMemberHomePageState extends State<UserMemberHomePage>
    with TickerProviderStateMixin {
  late Future<UserModel?> _userDataFuture;

  late final AnimationController _entrance;
  late final AnimationController _ambient;
  late final AnimationController _tiltSpring;

  double _tiltX = 0;
  double _tiltY = 0;

  final GlobalKey _docsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();

    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
      ..forward();

    _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);

    _tiltSpring = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
  }

  @override
  void dispose() {
    _entrance.dispose();
    _ambient.dispose();
    _tiltSpring.dispose();
    super.dispose();
  }

  Future<UserModel?> _fetchUserData() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: '+91' + widget.phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = querySnapshot.docs.first;
        UserModel user = UserModel.fromSnapshot(userDoc);
        if (!user.aprooved) return null;
        return user;
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }

  void _viewDocumentInApp(BuildContext context, String docName, String docUrl) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, anim, __) => FadeTransition(
          opacity: anim,
          child: PdfViewerPage(pdfUrl: docUrl, title: docName),
        ),
      ),
    );
  }

  void _scrollToDocuments() {
    final ctx = _docsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    }
  }

  Animation<double> _iv(double start, double end) {
    return CurvedAnimation(parent: _entrance, curve: Interval(start, end, curve: Curves.easeOutCubic));
  }

  Widget _slideFade({required Animation<double> interval, required Widget child}) {
    return FadeTransition(
      opacity: interval,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(interval),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: FutureBuilder<UserModel?>(
          future: _userDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoading(palette);
            } else if (snapshot.hasError) {
              return Center(
                child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
              );
            } else if (!snapshot.hasData || snapshot.data == null) {
              return _buildUnauthorized(snapshot.data?.aprooved ?? false, palette);
            }
            return _buildContent(snapshot.data!, palette);
          },
        ),
      ),
    );
  }

  Widget _buildLoading(AppPalette palette) {
    return Center(
      child: SizedBox(
        height: 42,
        width: 42,
        child: CircularProgressIndicator(strokeWidth: 3, color: palette.gold),
      ),
    );
  }

  Widget _buildUnauthorized(bool isApproved, AppPalette palette) {
    return Center(
      child: FadeTransition(
        opacity: _iv(0.0, 0.6),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: palette.card, shape: BoxShape.circle),
                child: Icon(Icons.person_off, size: 46, color: palette.gold),
              ),
              const SizedBox(height: 22),
              Text(
                !isApproved
                    ? "Your account is not approved yet. Please contact admin."
                    : "You are not an authorized user. Please contact admin.",
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.textPrimary.withOpacity(0.7), fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 24),
              _goldButton(palette, "Logout", onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).popUntil((route) => route.isFirst);
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main content ─────────────────────────────────────────────────────
  Widget _buildContent(UserModel user, AppPalette palette) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(palette),
          const SizedBox(height: 18),
          _slideFade(interval: _iv(0.0, 0.45), child: _buildHeroCard(user, palette)),
          const SizedBox(height: 18),
          _slideFade(interval: _iv(0.25, 0.55), child: _buildStatsRow(user, palette)),
          const SizedBox(height: 26),
          _slideFade(interval: _iv(0.35, 0.62), child: _sectionTitle("Contact Details", palette)),
          _slideFade(interval: _iv(0.4, 0.65), child: _buildContactCard(user, palette)),
          const SizedBox(height: 26),
          KeyedSubtree(
            key: _docsKey,
            child: _slideFade(interval: _iv(0.5, 0.72), child: _sectionTitle("Documents", palette)),
          ),
          user.documents == null || user.documents!.isEmpty
              ? _buildNoDocuments(palette)
              : _buildDocumentsList(user, palette),
          const SizedBox(height: 28),
          _slideFade(interval: _iv(0.8, 1.0), child: _buildFooterNotice(palette)),
        ],
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────
  Widget _buildTopBar(AppPalette palette) {
    return FadeTransition(
      opacity: _iv(0.0, 0.3),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: palette.gold,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.menu_book_rounded, color: palette.textPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("LokConnect",
                  style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold, fontSize: 17)),
              Text("LOKMANYA NAGAR, INDORE",
                  style: TextStyle(color: palette.textMuted, fontSize: 10, letterSpacing: 0.6)),
            ],
          ),
          const Spacer(),
          _GlassIconButton(
            palette: palette,
            icon: Icons.logout_rounded,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  // ── Hero card with isometric 3D stack ───────────────────────────────
  Widget _buildHeroCard(UserModel user, AppPalette palette) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 16, 24),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: palette.divider.withOpacity(0.3), width: 0.75),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: palette.divider.withOpacity(0.3), width: 0.75),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.place_outlined, size: 13, color: palette.textMuted),
                    const SizedBox(width: 5),
                    Text("Lokmanya Nagar · Indore",
                        style: TextStyle(color: palette.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: "Welcome back,\n", style: _serif(palette, size: 26)),
                TextSpan(
                  text: "${user.firstName}.",
                  style: _serif(palette, size: 26, color: palette.gold, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Your property records, verification status and documents — all in one place.",
            style: TextStyle(color: palette.textPrimary.withOpacity(0.65), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _goldButton(palette, "View Documents", icon: Icons.folder_open_rounded, onTap: _scrollToDocuments),
              const Spacer(),
              _IsometricStack(
                controller: _ambient,
                tiltX: _tiltX,
                tiltY: _tiltY,
                palette: palette,
                onDrag: (dx, dy) {
                  setState(() {
                    _tiltY = (_tiltY + dx / 260).clamp(-0.5, 0.5);
                    _tiltX = (_tiltX - dy / 260).clamp(-0.5, 0.5);
                  });
                },
                onDragEnd: _springBackTilt,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _springBackTilt() {
    final startX = _tiltX;
    final startY = _tiltY;
    _tiltSpring.reset();
    final anim = CurvedAnimation(parent: _tiltSpring, curve: Curves.elasticOut);
    anim.addListener(() {
      setState(() {
        _tiltX = startX * (1 - anim.value);
        _tiltY = startY * (1 - anim.value);
      });
    });
    _tiltSpring.forward();
  }

  Widget _goldButton(AppPalette palette, String label, {IconData? icon, required VoidCallback onTap}) {
    return _TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: palette.gold,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: palette.gold.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 17, color: palette.textPrimary), const SizedBox(width: 8)],
            Text(label,
                style: TextStyle(
                    color: palette.textPrimary, fontWeight: FontWeight.w700, fontSize: 13.5)),
          ],
        ),
      ),
    );
  }

  // ── Stat cards ────────────────────────────────────────────────────────
  Widget _buildStatsRow(UserModel user, AppPalette palette) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            palette: palette,
            label: "MEMBERSHIP NO.",
            value: user.membershipNumber ?? '—',
            icon: Icons.badge_outlined,
            iconColor: palette.gold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            palette: palette,
            label: "PLOT NUMBER",
            value: user.plotNumber ?? '—',
            icon: Icons.location_city_outlined,
            iconColor: const Color(0xFF6FCF97),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: _serif(palette, size: 19, weight: FontWeight.w700)),
    );
  }

  // ── Contact card ─────────────────────────────────────────────────────
  Widget _buildContactCard(UserModel user, AppPalette palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.divider.withOpacity(0.3), width: 0.75),
      ),
      child: Column(
        children: [
          _contactRow(Icons.email_outlined, "Email", user.email ?? 'N/A', palette),
          Container(
            height: 1,
            color: palette.divider.withOpacity(0.3),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          _contactRow(Icons.phone_outlined, "Phone Number", user.phoneNumber ?? 'N/A', palette),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value, AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: palette.inputBg, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 17, color: palette.gold),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: palette.textMuted, fontSize: 11.5)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(color: palette.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Documents ─────────────────────────────────────────────────────────
  Widget _buildNoDocuments(AppPalette palette) {
    return _slideFade(
      interval: _iv(0.55, 0.78),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: palette.card, borderRadius: BorderRadius.circular(18)),
        child: Center(
          child: Text("No documents available.",
              style: TextStyle(color: palette.textMuted, fontStyle: FontStyle.italic)),
        ),
      ),
    );
  }

  Widget _buildDocumentsList(UserModel user, AppPalette palette) {
    final entries =
        user.documents!.entries.where((e) => e.key != "Profile Picture").toList(growable: false);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final start = math.min(0.92, 0.5 + index * 0.08);
        final end = math.min(1.0, start + 0.3);
        return _slideFade(
          interval: _iv(start, end),
          child: _buildDocumentTile(entries[index].key, entries[index].value, palette),
        );
      },
    );
  }

  Widget _buildDocumentTile(String docName, String docUrl, AppPalette palette) {
    return _TapScale(
      onTap: () => _viewDocumentInApp(context, docName, docUrl),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.divider.withOpacity(0.3), width: 0.75),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: palette.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.picture_as_pdf_rounded, color: palette.gold, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(docName,
                      style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w600, fontSize: 14.5),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text("Tap to view document",
                      style: TextStyle(color: palette.textMuted, fontSize: 11.5)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: palette.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterNotice(AppPalette palette) {
    return Column(
      children: [
        Text("IMPORTANT NOTICE",
            style: TextStyle(color: palette.gold, fontWeight: FontWeight.bold, fontSize: 12.5, letterSpacing: 0.6)),
        const SizedBox(height: 10),
        Text(
          "The information available on LokConnect is highly confidential and sensitive. "
          "It includes personal property documents such as lease agreements and official records. "
          "Please do not share, forward, or disclose any information from this application with "
          "unauthorized individuals.",
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.textPrimary.withOpacity(0.5), fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 14),
        Text("Appledore Consulting Group©",
            style: TextStyle(color: palette.textMuted, fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Stat card
// ─────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final AppPalette palette;
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.palette,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.divider.withOpacity(0.3), width: 0.75),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(color: palette.textMuted, fontSize: 10.5, letterSpacing: 0.5)),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(color: palette.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Isometric floating "document stack"
// ─────────────────────────────────────────────────────────────────────────
class _IsometricStack extends StatelessWidget {
  final AnimationController controller;
  final double tiltX;
  final double tiltY;
  final AppPalette palette;
  final void Function(double dx, double dy) onDrag;
  final VoidCallback onDragEnd;

  const _IsometricStack({
    required this.controller,
    required this.tiltX,
    required this.tiltY,
    required this.palette,
    required this.onDrag,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (d) => onDrag(d.delta.dx, d.delta.dy),
      onPanEnd: (_) => onDragEnd(),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final bob = 4 * math.sin(controller.value * math.pi);
          return Transform.translate(
            offset: Offset(0, bob),
            child: SizedBox(
              height: 92,
              width: 110,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0025)
                      ..rotateX(0.55 + tiltX)
                      ..rotateZ(-0.72 + tiltY),
                    child: Stack(
                      alignment: Alignment.center,
                      children: List.generate(4, (i) {
                        final isTop = i == 3;
                        return Transform.translate(
                          offset: Offset(0, -i * 9.5),
                          child: Container(
                            height: 14,
                            width: 64,
                            decoration: BoxDecoration(
                              color: isTop ? palette.card : palette.textPrimary,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: palette.gold, width: 1.4),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    top: 6,
                    child: Transform.rotate(
                      angle: controller.value * math.pi / 3,
                      child: Container(
                        height: 16,
                        width: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3E8E5A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 2,
                    bottom: 2,
                    child: Transform.rotate(
                      angle: -controller.value * math.pi / 4,
                      child: Container(
                        height: 13,
                        width: 13,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB5523F),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────
class _GlassIconButton extends StatelessWidget {
  final AppPalette palette;
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.palette, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Material(
          color: palette.card,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Icon(icon, color: palette.textPrimary.withOpacity(0.75), size: 19),
            ),
          ),
        ),
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
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// PDF viewer page
// ─────────────────────────────────────────────────────────────────────────
class PdfViewerPage extends StatelessWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerPage({Key? key, required this.pdfUrl, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: palette.bg,
        iconTheme: IconThemeData(color: palette.textPrimary),
      ),
      backgroundColor: palette.bg,
      body: SfPdfViewer.network(pdfUrl),
    );
  }
}