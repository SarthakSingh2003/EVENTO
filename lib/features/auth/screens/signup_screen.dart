import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../app/theme/app_theme.dart';
import '../../../routes/app_router.dart';
import 'secure_account_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _isUsernameValid = false;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _checkUsernameValidity(String username) {
    setState(() {
      _isUsernameValid = username.length >= 3 && username.contains(RegExp(r'^[a-zA-Z0-9_]+$'));
    });
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) return;

    // Navigate to the next step (Secure Account screen)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecureAccountScreen(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          username: _usernameController.text.trim(),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final success = await authService.signInWithGoogle();
      
      if (success && mounted) {
        // Manual navigation trigger
        debugPrint('Google Sign-In successful, navigating to home');
        AppNavigation.goToHome(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Animated Yellow Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.headerBackground,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Animated Title
                  AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'Welcome to EVENTO',
                        textStyle: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontFamily: 'Poppins',
                        ),
                        speed: const Duration(milliseconds: 200),
                      ),
                    ],
                    totalRepeatCount: 1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Gateway to Amazing Events',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
                  const SizedBox(height: 20),
                ],
              ),
            ).animate().slideY(begin: -1, duration: 800.ms).fadeIn(duration: 1000.ms),
            
            // Main Content Section
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Animated White Card Container
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Animated Title
                                Text(
                                  'Create Your Account',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontFamily: 'Poppins',
                                  ),
                                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.3),
                                const SizedBox(height: 8),
                                Text(
                                  'Join thousands of event enthusiasts! Create your account to discover amazing events, purchase tickets, and connect with like-minded people.',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontFamily: 'Poppins',
                                  ),
                                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.3),
                                const SizedBox(height: 24),
                                
                                // Animated Name Fields
                                Text(
                                  'Full Name',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                    fontFamily: 'Poppins',
                                  ),
                                ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.3),
                                const SizedBox(height: 8),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final bool stacked = constraints.maxWidth < 480;
                                    if (stacked) {
                                      return Column(
                                        children: [
                                          TextFormField(
                                            controller: _firstNameController,
                                            style: const TextStyle(color: Colors.black),
                                            cursorColor: Colors.black,
                                            decoration: InputDecoration(
                                              hintText: 'First Name',
                                              filled: true,
                                              fillColor: AppTheme.inputBackground,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 16,
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please enter first name';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 12),
                                          TextFormField(
                                            controller: _lastNameController,
                                            style: const TextStyle(color: Colors.black),
                                            cursorColor: Colors.black,
                                            decoration: InputDecoration(
                                              hintText: 'Last Name',
                                              filled: true,
                                              fillColor: AppTheme.inputBackground,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 16,
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please enter last name';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      );
                                    }
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _firstNameController,
                                            style: const TextStyle(color: Colors.black),
                                            cursorColor: Colors.black,
                                            decoration: InputDecoration(
                                              hintText: 'First Name',
                                              filled: true,
                                              fillColor: AppTheme.inputBackground,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 16,
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please enter first name';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _lastNameController,
                                            style: const TextStyle(color: Colors.black),
                                            cursorColor: Colors.black,
                                            decoration: InputDecoration(
                                              hintText: 'Last Name',
                                              filled: true,
                                              fillColor: AppTheme.inputBackground,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 16,
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please enter last name';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.3),
                                
                                const SizedBox(height: 20),
                                
                                // Animated Email Field
                                Text(
                                  'Email Address',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                    fontFamily: 'Poppins',
                                  ),
                                ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.3),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(color: Colors.black),
                                  cursorColor: Colors.black,
                                  decoration: InputDecoration(
                                    hintText: 'Your Email Address',
                                    filled: true,
                                    fillColor: AppTheme.inputBackground,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.email,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!Helpers.isValidEmail(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ).animate().fadeIn(delay: 900.ms).slideX(begin: -0.3),
                                
                                const SizedBox(height: 20),
                                
                                // Animated Username Field
                                Text(
                                  'Choose a Username',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                    fontFamily: 'Poppins',
                                  ),
                                ).animate().fadeIn(delay: 1000.ms).slideX(begin: -0.3),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _usernameController,
                                  onChanged: _checkUsernameValidity,
                                  style: const TextStyle(color: Colors.black),
                                  cursorColor: Colors.black,
                                  decoration: InputDecoration(
                                    hintText: 'example1234',
                                    filled: true,
                                    fillColor: AppTheme.inputBackground,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    suffixIcon: _isUsernameValid
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          )
                                        : null,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a username';
                                    }
                                    if (value.length < 3) {
                                      return 'Username must be at least 3 characters';
                                    }
                                    if (!value.contains(RegExp(r'^[a-zA-Z0-9_]+$'))) {
                                      return 'Username can only contain letters, numbers, and underscores';
                                    }
                                    return null;
                                  },
                                ).animate().fadeIn(delay: 1100.ms).slideX(begin: -0.3),
                                
                                const SizedBox(height: 24),
                                
                                // Animated Save & Continue Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleContinue,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.buttonBackground,
                                      foregroundColor: AppTheme.buttonText,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                            ),
                                          )
                                        : const Text(
                                            'Create Account',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                  ),
                                ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.3).scale(begin: const Offset(0.8, 0.8)),
                                
                                const SizedBox(height: 20),
                                
                                // Animated Divider
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.grey.shade300)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'OR',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Colors.grey.shade300)),
                                  ],
                                ).animate().fadeIn(delay: 1300.ms).scale(begin: const Offset(0, 1)),
                                
                                const SizedBox(height: 20),
                                
                                // Animated Google Sign In Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                                    icon: Image.network(
                                      'https://developers.google.com/identity/images/g-logo.png',
                                      height: 20,
                                      width: 20,
                                    ),
                                    label: const Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.grey),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ).animate().fadeIn(delay: 1400.ms).slideY(begin: 0.3).scale(begin: const Offset(0.8, 0.8)),
                                
                                const SizedBox(height: 24),
                                
                                // Animated Back to Login Link
                                Center(
                                  child: TextButton(
                                    onPressed: () => AppNavigation.goToLogin(context),
                                    child: const Text(
                                      'Already have an account? Sign In',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ).animate().fadeIn(delay: 1500.ms).slideY(begin: 0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 