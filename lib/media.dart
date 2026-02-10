import 'dart:html' as html;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({Key? key}) : super(key: key);
  @override
  _MediaScreenState createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _bgController;
  late Animation<double> _bgAnimation;
  late Animation<double> _fadeAnimation;

  final List<SocialLink> _links = [
    SocialLink(
        icon: 'assets/instagram.png',
        label: 'Instagram',
        url: 'https://www.instagram.com/prest.zone'),
    SocialLink(
        icon: 'assets/facebook.png',
        label: 'Facebook',
        url: 'https://www.facebook.com/Prest.Zone'),
    SocialLink(
        icon: 'assets/website.png',
        label: 'Our Website',
        url: 'https://www.prest-zone.com/'),
  ];

  // Updated dark theme colors with golden accents
  static const Color darkPrimary = Color(0xFF1A1A1A);    // Dark background
  static const Color darkAccent = Color(0xFF2D2D2D);     // Darker accent
  static const Color goldPrimary = Color(0xFFD4AF37);    // Primary gold
  static const Color goldDark = Color(0xFFB8860B);       // Darker gold
  static const Color goldLight = Color(0xFFFFD700);      // Light gold
  static const Color textPrimary = Color(0xFFE6E6E6);    // Light text
  static const Color textSecondary = Color(0xFFB0B0B0);  // Secondary text

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _bgController = AnimationController(duration: const Duration(seconds: 4), vsync: this)..repeat(reverse: true);
    _bgAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    if (kIsWeb) {
      html.window.open(url, '_blank');
    } else {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _showErrorSnackbar('Could not launch $url');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.playfairDisplay(color: textPrimary)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkAccent.withOpacity(0.85),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _shareProfile() {
    Clipboard.setData(const ClipboardData(text: 'www.prest-zone.com'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: goldPrimary),
            SizedBox(width: 8),
            Text("Profile link copied to clipboard!", style: GoogleFonts.playfairDisplay(color: textPrimary)),
          ],
        ),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkAccent.withOpacity(0.85),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: goldPrimary.withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(color: goldPrimary.withOpacity(0.15), blurRadius: 20, spreadRadius: 2),
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 5)),
              ],
            ),
            child: Image.asset(
              'assets/prest-zone-logo-removebg.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 120,
                  height: 120,
                  alignment: Alignment.center,
                  child: Text('PREST ZONE', style: TextStyle(color: goldPrimary, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
                );
              },
            ),
          ),
          SizedBox(height: 20),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              "Prest-Zone",
              style: GoogleFonts.cinzel(
                color: goldLight,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(2, 2))],
              ),
            ),
          ),
          SizedBox(height: 15),
          SlideTransition(
            position: Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero).animate(
              CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
            ),
            child: Text(
              "Connect with us on social media",
              style: GoogleFonts.playfairDisplay(color: textSecondary, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(SocialLink link, int index) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 50,
        child: FadeInAnimation(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: GestureDetector(
              onTap: () => _launchURL(link.url),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [darkPrimary, darkAccent, darkPrimary],
                  ),
                  border: Border.all(color: goldPrimary, width: 1.5),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: goldDark.withOpacity(0.2), blurRadius: 5, offset: Offset(0, 2)),
                  ],
                ),
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: goldLight, width: 1),
                      ),
                      child: Image.asset(
                        link.icon,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.link, color: goldLight, size: 20);
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        link.label,
                        style: GoogleFonts.cinzel(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: goldLight, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: goldLight),
            onPressed: _shareProfile,
          ),
        ],
      ),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgAnimation,
            builder: (context, child) => CustomPaint(
              painter: AnimatedGradientPainter(_bgAnimation),
              size: Size.infinite,
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildProfileHeader(),
                      SizedBox(height: 30),
                      AnimationLimiter(
                        child: Column(
                          children: _links
                              .asMap()
                              .entries
                              .map((entry) => _buildSocialButton(entry.value, entry.key))
                              .toList(),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        '© Prest-Zone 2025-2026',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SocialLink {
  final String icon;
  final String label;
  final String url;
  SocialLink({required this.icon, required this.label, required this.url});
}

class AnimatedGradientPainter extends CustomPainter {
  final Animation<double> animation;

  AnimatedGradientPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1A1A1A),  // Dark primary
          Color(0xFF2D2D2D),  // Dark accent
          Color(0xFF1F1F1F),  // Slightly different dark
          Color(0xFF2D2D2D),  // Dark accent
          Color(0xFF1A1A1A),  // Dark primary
        ],
        stops: [
          0.0,
          0.3 + animation.value * 0.2,
          0.5 + animation.value * 0.3,
          0.7 + animation.value * 0.2,
          1.0,
        ],
        transform: GradientRotation(animation.value * 3.14),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(AnimatedGradientPainter oldDelegate) => true;
}