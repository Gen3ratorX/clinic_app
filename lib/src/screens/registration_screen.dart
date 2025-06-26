import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


enum PasswordStrength { veryWeak, weak, medium, strong, veryStrong }

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Animation Controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  // Animations
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  bool _termsAccepted = false;
  bool _hasReadTerms = false;
  bool _passwordObscured = true;
  bool _confirmPasswordObscured = true;
  PasswordStrength _passwordStrength = PasswordStrength.veryWeak;
  bool _passwordsMatch = true;
  bool _isLoading = false;
  String? _errorMessage;

  String _selectedGender = 'Male';
  final List<String> _genders = ['Male', 'Female'];

  // Enhanced color scheme
  final Color primaryColor = const Color(0xFF00796B);       // Teal
  final Color lightPrimaryColor = const Color(0xFFB2DFDB);  // Mint
  final Color accentColor = const Color(0xFF004D40);        // Dark Teal
  Future<void> saveFCMTokenToFirestore(String uid) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });
    }
  }


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

  Future<void> _pickDate() async {
    HapticFeedback.lightImpact();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: primaryColor),
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _checkPasswordMatch() {
    setState(() {
      _passwordsMatch = _passwordController.text == _confirmPasswordController.text;
    });
  }

  void _checkPasswordStrength(String password) {
    final bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    final bool hasLower = password.contains(RegExp(r'[a-z]'));
    final bool hasDigit = password.contains(RegExp(r'\d'));
    final bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int criteriaMet = 0;
    if (hasUpper) criteriaMet++;
    if (hasLower) criteriaMet++;
    if (hasDigit) criteriaMet++;
    if (hasSpecial) criteriaMet++;

    PasswordStrength strength;
    if (password.length < 8 || criteriaMet < 2) {
      strength = PasswordStrength.veryWeak;
    } else if (password.length >= 12 && criteriaMet == 4) {
      strength = PasswordStrength.veryStrong;
    } else if (password.length >= 8 && criteriaMet == 4) {
      strength = PasswordStrength.strong;
    } else if (password.length >= 8 && criteriaMet == 3) {
      strength = PasswordStrength.medium;
    } else if (password.length >= 8 && criteriaMet == 2) {
      strength = PasswordStrength.weak;
    } else {
      strength = PasswordStrength.veryWeak;
    }

    setState(() {
      _passwordStrength = strength;
    });
  }

  Widget _buildPasswordStrengthBar() {
    List<Color> colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.lightGreen,
      primaryColor,
    ];

    int activeBars = _passwordStrength.index + 1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.only(top: 6.0, bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: activeBars / 5,
              backgroundColor: Colors.grey[200],
              color: colors[activeBars.clamp(0, 4)],
              minHeight: 4,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _passwordStrength.name.capitalize,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors[activeBars.clamp(0, 4)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool isDate = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
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
        textCapitalization: textCapitalization,
        obscureText: isPassword ? (controller == _passwordController ? _passwordObscured : _confirmPasswordObscured) : false,
        readOnly: isDate,
        onTap: isDate ? _pickDate : null,
        validator: validator,
        onChanged: onChanged,
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
              controller == _passwordController
                  ? (_passwordObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined)
                  : (_confirmPasswordObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              color: primaryColor,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                if (controller == _passwordController) {
                  _passwordObscured = !_passwordObscured;
                } else {
                  _confirmPasswordObscured = !_confirmPasswordObscured;
                }
              });
            },
          )
              : isDate
              ? Icon(Icons.calendar_today, color: primaryColor)
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

  Widget _buildDropdownField() {
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
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: InputDecoration(
          labelText: "Gender",
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
            child: Icon(Icons.wc, color: primaryColor, size: 20),
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
        ),
        items: _genders.map((gender) {
          return DropdownMenuItem(value: gender, child: Text(gender));
        }).toList(),
        onChanged: (value) {
          HapticFeedback.lightImpact();
          setState(() => _selectedGender = value!);
        },
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _termsAccepted ? primaryColor : Colors.transparent,
            border: Border.all(
              color: _termsAccepted ? primaryColor : Colors.grey[400]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              if (_hasReadTerms) {
                setState(() {
                  _termsAccepted = !_termsAccepted;
                });
              }
            },
            child: _termsAccepted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
            final accepted = await Navigator.pushNamed(context, '/terms');
            if (accepted == true) {
              setState(() {
                _hasReadTerms = true;
                _termsAccepted = true;
              });
            }
          },
          child: Text(
            "I agree to the Terms & Conditions",
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
            semanticsLabel: "Terms and Conditions link",
          ),
        ),
      ],
    );
  }


  Widget _buildCreateAccountButton() {
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
          onTap: _termsAccepted && !_isLoading ? _register : null,
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
                "Create Account",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                semanticsLabel: "Create Account Button",
              ),
            ),
          ),
        ),
      ),
    );
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
                'Registration Successful!',
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

  Future<void> _register() async {
    if (_formKey.currentState!.validate() && _termsAccepted) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        String uid = userCredential.user!.uid;
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'lastName': _lastNameController.text.trim(),
          'firstName': _firstNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'dob': _dobController.text,
          'gender': _selectedGender,
          'createdAt': FieldValue.serverTimestamp(),
        });
// ✅ Save FCM token
        await saveFCMTokenToFirestore(uid);

        HapticFeedback.heavyImpact();
        _showSuccessAnimation();

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/patientHome');
        }
      } on FirebaseAuthException catch (e) {
        HapticFeedback.heavyImpact();
        String message;
        switch (e.code) {
          case 'email-already-in-use':
            message = 'The email address is already in use.';
            break;
          case 'invalid-email':
            message = 'The email address is invalid.';
            break;
          case 'weak-password':
            message = 'The password is too weak.';
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
      } on FirebaseException catch (e) {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = 'Firestore error: ${e.message ?? 'Unknown error'}';
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
    } else if (!_termsAccepted) {
      HapticFeedback.lightImpact();
      setState(() {
        _errorMessage = 'Please accept the Terms & Conditions.';
      });
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
    }
  }

  Future<bool> _onWillPop() async {
    Navigator.pushReplacementNamed(context, '/login');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
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
            ),
            AnimatedBuilder(
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
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
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
                              "Create Account",
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
                            "Join Deseret today",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
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
                                        controller: _lastNameController,
                                        label: 'Surname',
                                        icon: Icons.person,
                                        textCapitalization: TextCapitalization.words,
                                        validator: (value) => value == null || value.isEmpty ? 'Enter your surname' : null,
                                      ),
                                      const SizedBox(height: 20),
                                      _buildEnhancedTextField(
                                        controller: _firstNameController,
                                        label: 'First Name',
                                        icon: Icons.person,
                                        textCapitalization: TextCapitalization.words,
                                        validator: (value) => value == null || value.isEmpty ? 'Enter your first name' : null,
                                      ),
                                      const SizedBox(height: 20),
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
                                      const SizedBox(height: 20),
                                      _buildEnhancedTextField(
                                        controller: _phoneController,
                                        label: 'Phone Number',
                                        icon: Icons.phone,
                                        keyboardType: TextInputType.phone,
                                        validator: (value) => value == null || value.isEmpty ? 'Enter your phone number' : null,
                                      ),
                                      const SizedBox(height: 20),
                                      _buildEnhancedTextField(
                                        controller: _dobController,
                                        label: 'Date of Birth',
                                        icon: Icons.calendar_today,
                                        isDate: true,
                                        validator: (value) => value == null || value.isEmpty ? 'Select your date of birth' : null,
                                      ),
                                      const SizedBox(height: 20),
                                      _buildDropdownField(),
                                      const SizedBox(height: 20),
                                      _buildEnhancedTextField(
                                        controller: _passwordController,
                                        label: 'Password',
                                        icon: Icons.lock_outline,
                                        isPassword: true,
                                        validator: (value) => value == null || value.isEmpty ? 'Enter your password' : null,
                                        onChanged: _checkPasswordStrength,
                                      ),
                                      _buildPasswordStrengthBar(),
                                      const SizedBox(height: 20),
                                      _buildEnhancedTextField(
                                        controller: _confirmPasswordController,
                                        label: 'Confirm Password',
                                        icon: Icons.lock,
                                        isPassword: true,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Confirm your password';
                                          } else if (value != _passwordController.text) {
                                            return 'Passwords do not match';
                                          }
                                          return null;
                                        },
                                        onChanged: (_) => _checkPasswordMatch(),
                                      ),
                                      if (!_passwordsMatch)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Passwords do not match',
                                            style: TextStyle(color: Colors.red, fontSize: 12),
                                          ),
                                        ),
                                      const SizedBox(height: 20),
                                      _buildTermsCheckbox(),
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
                                      _buildCreateAccountButton(),
                                      const SizedBox(height: 16),
                                      GestureDetector(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          Navigator.pushReplacementNamed(context, '/login');
                                        },
                                        child: Text(
                                          'Already have an account? Sign In',
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            decoration: TextDecoration.none,
                                          ),
                                          textAlign: TextAlign.center,
                                          semanticsLabel: 'Sign In Link',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.stop();
    _pulseController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

extension StringExtension on String {
  String get capitalize => this[0].toUpperCase() + substring(1).toLowerCase();
}