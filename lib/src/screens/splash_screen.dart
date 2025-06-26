import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class SplashScreen extends StatefulWidget {
  final bool? isLoggedIn;
  const SplashScreen({super.key, this.isLoggedIn});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _pulseController;
  late final AnimationController _progressController;
  late final AnimationController _bgController;

  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _slideAnim;
  late final Animation<double> _rotateAnim;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _bgShiftAnim;

  Future<void> saveFCMTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmToken': token,
      });
    }
  }


  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
    _progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)));
    _slideAnim = Tween<double>(begin: 40.0, end: 0.0).animate(CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
    _rotateAnim = Tween<double>(begin: -0.1, end: 0.1).animate(CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 1.0, curve: Curves.easeInOut)));
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _bgShiftAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_bgController);
  }

  void _startAnimationSequence() {
    _mainController.forward();
    _progressController.forward();
    Timer(const Duration(milliseconds: 3200), () {
      if (mounted) _handleNavigation();
    });
  }

  Future<void> _handleNavigation() async {
    if (widget.isLoggedIn != null) {
      if (widget.isLoggedIn == true) {
        await saveFCMTokenToFirestore(); // ✅ Save FCM token
        Navigator.of(context).pushReplacementNamed('/patientHome');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await saveFCMTokenToFirestore(); // ✅ Save FCM token
      Navigator.of(context).pushReplacementNamed('/patientHome');
      return;
    }

    const storage = FlutterSecureStorage();
    final email = await storage.read(key: 'email');
    final password = await storage.read(key: 'password');

    if (email != null && password != null) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        await saveFCMTokenToFirestore(); // ✅ Save FCM token
        if (mounted) Navigator.of(context).pushReplacementNamed('/patientHome');
      } catch (_) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      }
    } else {
      if (mounted) Navigator.of(context).pushReplacementNamed('/register');
    }
  }


  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_mainController, _pulseController, _progressController, _bgController]),
        builder: (context, _) {
          return Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(gradient: _buildBackgroundGradient(isDark)),
            child: Stack(
              children: [
                ...List.generate(20, (i) => _buildFloatingParticle(i, size, isDark)),
                _buildContent(size, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  LinearGradient _buildBackgroundGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      transform: GradientRotation(_bgShiftAnim.value * 2 * math.pi),
      colors: isDark
          ? [Color(0xFF1A1A1A), Color(0xFF2D2D2D), Color(0xFF1F1F1F), Color(0xFF0F0F0F)]
          : [Color(0xFFF8F9FA), Color(0xFFE9ECEF), Color(0xFFF1F3F4), Color(0xFFFFFFFF)],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );
  }

  Widget _buildFloatingParticle(int i, Size size, bool isDark) {
    final offset = (i * 0.1) % 1.0;
    final particleSize = 2.0 + (i % 3) * 2.0;
    final x = (i * 50.0) % size.width;
    final yMovement = 50.0 + (i % 4) * 20.0;
    final y = size.height * 0.2 + math.sin((_bgShiftAnim.value + offset) * 2 * math.pi) * yMovement;

    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: particleSize,
        height: particleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        ),
      ),
    );
  }

  Widget _buildContent(Size size, bool isDark) {
    const olive = Color(0xFF00796B);
    const lightPrimaryColor = Color(0xFFB2DFDB);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: Offset(0, _slideAnim.value),
            child: Transform.rotate(
              angle: _rotateAnim.value,
              child: Opacity(
                opacity: _fadeAnim.value,
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: _buildLogo(olive, isDark),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Transform.translate(
            offset: Offset(0, _slideAnim.value * 0.5),
            child: Opacity(
              opacity: _fadeAnim.value,
              child: _buildTitle(isDark, olive),
            ),
          ),
          const SizedBox(height: 48),
          Transform.translate(
            offset: Offset(0, _slideAnim.value * 0.3),
            child: Opacity(
              opacity: _fadeAnim.value,
              child: _buildProgressBar(olive, lightPrimaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(Color border, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]
              : [Colors.white.withOpacity(0.4), Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
        ),
        boxShadow: [
          BoxShadow(
            color: border.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Image.asset('assets/images/Logo.png', height: 80),
    );
  }

  Widget _buildTitle(bool isDark, Color color) {
    return Text(
      'Deseret Hospital',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : color,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildProgressBar(Color bg, Color fill) {
    return SizedBox(
      width: 280,
      height: 60,
      child: CustomPaint(
        painter: HeartBeatPulsePainter(
          animationValue: _pulseAnim.value,
          backgroundColor: Colors.transparent, // Removed background fill
          pulseColor: fill,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class HeartBeatPulsePainter extends CustomPainter {
  final double animationValue;
  final Color backgroundColor;
  final Color pulseColor;

  HeartBeatPulsePainter({
    required this.animationValue,
    required this.backgroundColor,
    required this.pulseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Skip drawing background rectangle

    final pulsePaint = Paint()
      ..color = pulseColor.withOpacity(0.8 + 0.2 * math.sin(animationValue * 2 * math.pi))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final centerY = size.height / 2;
    final width = size.width;

    path.moveTo(0, centerY);

    final pulse1X = width * 0.15;
    path.lineTo(pulse1X - 8, centerY);
    path.lineTo(pulse1X - 4, centerY - 6);
    path.lineTo(pulse1X, centerY);
    path.lineTo(pulse1X + 4, centerY + 8);
    path.lineTo(pulse1X + 8, centerY);

    path.lineTo(pulse1X + 25, centerY);

    final mainPulseX = width * 0.5;
    final pulseIntensity = 0.7 + 0.5 * math.sin(animationValue * 2 * math.pi);
    path.lineTo(mainPulseX - 12, centerY);
    path.lineTo(mainPulseX - 8, centerY + 5);
    path.lineTo(mainPulseX - 4, centerY - 30 * pulseIntensity);
    path.lineTo(mainPulseX, centerY + 12 * pulseIntensity);
    path.lineTo(mainPulseX + 4, centerY);
    path.lineTo(mainPulseX + 12, centerY);

    final pulse2X = width * 0.75;
    path.lineTo(pulse2X - 15, centerY);
    path.lineTo(pulse2X - 8, centerY - 8);
    path.lineTo(pulse2X, centerY);
    path.lineTo(pulse2X + 8, centerY + 4);
    path.lineTo(pulse2X + 15, centerY);

    path.lineTo(width, centerY);

    canvas.drawPath(path, pulsePaint);

    final glowIntensity = 0.2 + 0.3 * math.sin(animationValue * 2 * math.pi);
    final glowPaint = Paint()
      ..color = pulseColor.withOpacity(glowIntensity)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(path, glowPaint);

    final scanLineX = width * ((animationValue * 1.2) % 1.0);
    final scanPaint = Paint()
      ..color = pulseColor.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(scanLineX, 5),
      Offset(scanLineX, size.height - 5),
      scanPaint,
    );

    for (int i = 0; i < 3; i++) {
      final dotOpacity = math.max(0.0, 1.0 - (animationValue - i * 0.3).abs() * 3);
      if (dotOpacity > 0) {
        final dotPaint = Paint()
          ..color = pulseColor.withOpacity(dotOpacity)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(width * 0.9 + i * 8, centerY - 15),
          2 + dotOpacity,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
