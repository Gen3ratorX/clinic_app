import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final storage = const FlutterSecureStorage();

  // Animation Controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  // Animations
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _rememberMe = false;
  String? _errorMessage;

  // Enhanced color scheme
  final Color primaryColor = const Color(0xFF00796B);       // Teal
  final Color lightPrimaryColor = const Color(0xFFB2DFDB);  // Mint
  final Color accentColor = const Color(0xFF004D40);        // Dark Teal


  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSavedCredentials();
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

  /// Loads saved email and password from secure storage, if available
  Future<void> _loadSavedCredentials() async {
    String? savedEmail = await storage.read(key: 'email');
    String? savedPassword = await storage.read(key: 'password');
    if (savedEmail != null && savedPassword != null) {
      _emailController.text = savedEmail;
      _passwordController.text = savedPassword;
      setState(() {
        _rememberMe = true;
      });
    }
  }

  /// Handles the login process with Firebase authentication
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    print("Attempting login with email: ${_emailController.text.trim()}");

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(

        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      print("Login successful");
      await saveFCMTokenToFirestore();



      // Success haptic feedback
      HapticFeedback.heavyImpact();

      if (_rememberMe) {
        await storage.write(key: 'email', value: _emailController.text);
        await storage.write(key: 'password', value: _passwordController.text);
      } else {
        await storage.delete(key: 'email');
        await storage.delete(key: 'password');
      }

      // Success animation before navigation
      _showSuccessAnimation();

      await Future.delayed(const Duration(milliseconds: 1500));
      Navigator.pushReplacementNamed(context, '/patientHome');
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.code} - ${e.message}");

      // Error haptic feedback
      HapticFeedback.heavyImpact();

      String errorMessage;
      switch (e.code) {
        case 'invalid-credential':
          errorMessage = "The email or password you entered is incorrect.";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email format.";
          break;
        case 'too-many-requests':
          errorMessage = "Too many attempts. Please try again later.";
          break;
        default:
          errorMessage = "Login failed: ${e.message}";
      }
      setState(() {
        _errorMessage = errorMessage;
      });
    } catch (e) {
      print("Unexpected error: $e");
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = "An unexpected error occurred: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
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
                'Login Successful!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
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
          _buildBackground(),

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
                    _buildLogoSection(),

                    const Spacer(),

                    // Animated Form Section
                    _buildFormSection(),

                    const Spacer(),

                    // Footer Links
                    _buildFooterSection(),

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

  Widget _buildBackground() {
    return Container(
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
    );
  }

  Widget _buildLogoSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Enhanced Logo Container
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
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Enhanced Title
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [primaryColor, lightPrimaryColor],
              ).createShader(bounds),
              child: const Text(
                "Welcome Back",
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
              "Sign in to continue to Deseret",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return SlideTransition(
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
                // Enhanced Email Field
                _buildEnhancedTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Enter your email";
                    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return "Enter a valid email address";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Enhanced Password Field
                _buildEnhancedTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: (value) => value == null || value.isEmpty ? "Enter your password" : null,
                ),

                // Error Message with Animation
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
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Enhanced Remember Me
                _buildRememberMeSection(),

                const SizedBox(height: 28),

                // Enhanced Sign In Button
                _buildSignInButton(),

                const SizedBox(height: 16),

                // Enhanced Create Account Button
                _buildCreateAccountButton(),
              ],
            ),
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
    bool isPassword = false,
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
        obscureText: isPassword ? !_passwordVisible : false,
        validator: validator,
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
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _passwordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: primaryColor,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _passwordVisible = !_passwordVisible;
              });
            },
          )
              : null,
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
      ),
    );
  }

  Widget _buildRememberMeSection() {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _rememberMe ? primaryColor : Colors.transparent,
            border: Border.all(
              color: _rememberMe ? primaryColor : Colors.grey[400]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _rememberMe = !_rememberMe;
              });
            },
            child: _rememberMe
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          "Remember for 30 days",
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
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
        boxShadow: _isLoading ? [] : [
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
          onTap: _isLoading ? null : _login,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            alignment: Alignment.center,
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
              "Sign In",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateAccountButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: primaryColor, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, '/register');
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              "Create New Account",
              style: TextStyle(
                fontSize: 16,
                color: primaryColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: TextButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(context, '/forgotPassword');
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text(
          "Forgot Password?",
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}