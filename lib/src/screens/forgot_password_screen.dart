import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  // Animation Controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  // Animations
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  bool _isLoading = false;
  String? _errorMessage;

  // Enhanced color scheme
  final Color primaryColor = const Color(0xFF00796B);
  final Color lightPrimaryColor = const Color(0xFFB2DFDB);
  final Color accentColor = const Color(0xFF004D40);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _slideController.forward();
        _fadeController.forward();
      }
    });
  }

  Future<void> _sendPasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.heavyImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
      _showSuccessAnimation();
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context); // Return to login screen
      }
    } on FirebaseAuthException catch (e) {
      HapticFeedback.heavyImpact();
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = 'The email address is invalid.';
          break;
        case 'user-not-found':
          message = 'No user found with this email address.';
          break;
        default:
          message = 'An error occurred: ${e.message}';
      }
      setState(() {
        _errorMessage = message;
      });
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseAnimation.value * 0.1),
                    child: Icon(
                      Icons.check_circle,
                      color: primaryColor,
                      size: 60,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Password Reset Email Sent!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your email for the reset link.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(16),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: validator,
        onTap: () {
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  Widget _buildSendResetButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isLoading
              ? [Colors.grey[300]!, Colors.grey[400]!]
              : [primaryColor, accentColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isLoading
            ? []
            : [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _sendPasswordReset,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            alignment: Alignment.center,
            child: AnimatedOpacity(
              opacity: _isLoading ? 0.7 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: _isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text(
                "Send Reset Link",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                semanticsLabel: "Send Reset Link Button",
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Enhanced Background with Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.1),
                  lightPrimaryColor.withOpacity(0.05),
                  Colors.white,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.5),
                      radius: 1.5,
                      colors: [
                        primaryColor.withOpacity(0.1 * _pulseAnimation.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                height: size.height - MediaQuery.of(context).padding.top,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Animated Logo Section
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.8),
                                        Colors.white.withOpacity(0.4),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.2 + 0.1 * _pulseAnimation.value),
                                        blurRadius: 20 + 10 * _pulseAnimation.value,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Transform.scale(
                                    scale: 1.0 + (_pulseAnimation.value * 0.05),
                                    child: Image.asset(
                                      "assets/images/Logo.png",
                                      height: 80,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                        Icons.medical_services,
                                        size: 80,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [primaryColor, lightPrimaryColor],
                              ).createShader(bounds),
                              child: const Text(
                                "Reset Password",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Enter your email to receive a password reset link",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Animated Form Section
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 0,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildEnhancedTextField(
                                  controller: _emailController,
                                  label: 'Email Address',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Enter your email';
                                    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                          onPressed: () {
                                            setState(() {
                                              _errorMessage = null;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 28),
                                _buildSendResetButton(),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pop(context);
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  child: Text(
                                    'Back to Login',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      decoration: TextDecoration.underline,
                                    ),
                                    semanticsLabel: 'Back to Login Link',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.stop();
    _pulseController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}