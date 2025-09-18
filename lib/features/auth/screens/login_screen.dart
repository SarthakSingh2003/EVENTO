import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../app/theme/app_theme.dart';
import '../../../routes/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _savePassword = false;
  
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
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final success = await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (success && mounted) {
        // Manual navigation trigger
        debugPrint('Email/password login successful, navigating to home');
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

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('Starting Google Sign-In process...');
      final authService = context.read<AuthService>();
      final success = await authService.signInWithGoogle();
      
      debugPrint('Google Sign-In result: $success');
      debugPrint('Auth service isAuthenticated: ${authService.isAuthenticated}');
      debugPrint('Auth service userRole: ${authService.userRole}');
      
      if (success && mounted) {
        // Wait a bit for the auth state to update
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Check auth state again
        debugPrint('After delay - isAuthenticated: ${authService.isAuthenticated}');
        
        if (authService.isAuthenticated) {
          debugPrint('Google Sign-In successful, navigating to home');
          // Use Navigator instead of AppNavigation for more direct control
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        } else {
          debugPrint('Authentication state not updated properly');
          // Fallback navigation
          AppNavigation.goToHome(context);
        }
      } else {
        debugPrint('Google Sign-In failed or cancelled');
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
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
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Animated Yellow Header Section
            Builder(
              builder: (context) {
                final double screenWidth = MediaQuery.of(context).size.width;
                final bool isTiny = screenWidth < 340;
                final double headerPad = isTiny ? 16 : 24;
                final double titleSize = isTiny ? 28 : 32;
                final double subtitleSize = isTiny ? 16 : 18;
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(headerPad),
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
                      // Animated Logo/Title
                      AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            'Welcome Back',
                            textStyle: TextStyle(
                              fontSize: titleSize,
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
                        'Sign in to continue your event journey',
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
                      const SizedBox(height: 20),
                    ],
                  ),
                ).animate().slideY(begin: -1, duration: 800.ms).fadeIn(duration: 1000.ms);
              },
            ),
            
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
                                  'Sign In to Your Account',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontFamily: 'Poppins',
                                  ),
                                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.3),
                                const SizedBox(height: 8),
                                Text(
                                  'Welcome back! Sign in to your account to continue discovering amazing events, managing your tickets, and staying updated with your favorite organizers.',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontFamily: 'Poppins',
                                  ),
                                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.3),
                                const SizedBox(height: 24),
                                
                                // Animated Email Field
                                Text(
                                  'Email Address',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                    fontFamily: 'Poppins',
                                  ),
                                ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.3),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  style: const TextStyle(color: Colors.black),
                                  cursorColor: Colors.black,
                                  keyboardType: TextInputType.emailAddress,
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
                                      Icons.person_outline,
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
                                ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.3),
                                
                                const SizedBox(height: 20),
                                
                                // Animated Password Field
                                Text(
                                  'Password',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                    fontFamily: 'Poppins',
                                  ),
                                ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.3),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(color: Colors.black),
                                  cursorColor: Colors.black,
                                  decoration: InputDecoration(
                                    hintText: '************',
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
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword 
                                          ? Icons.visibility_outlined 
                                          : Icons.visibility_off_outlined,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() => _obscurePassword = !_obscurePassword);
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                ).animate().fadeIn(delay: 900.ms).slideX(begin: -0.3),
                                
                                const SizedBox(height: 16),
                                
                                // Animated Save Password and Forgot Password
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: _savePassword,
                                      onChanged: (value) {
                                        setState(() => _savePassword = value ?? false);
                                      },
                                      activeColor: AppTheme.primaryColor,
                                    ),
                                    const Text(
                                      'Save Password',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ).animate().fadeIn(delay: 1000.ms).slideX(begin: -0.3),
                                
                                const SizedBox(height: 24),
                                
                                // Animated Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
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
                                            'Sign In',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                  ),
                                ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.3).scale(begin: const Offset(0.8, 0.8)),
                                
                                if (!isKeyboardVisible) ...[
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
                                  ).animate().fadeIn(delay: 1200.ms).scale(begin: const Offset(0, 1)),
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
                                  ).animate().fadeIn(delay: 1300.ms).slideY(begin: 0.3).scale(begin: const Offset(0.8, 0.8)),
                                ],

                                const SizedBox(height: 24),
                                
                                // Animated Create New Account Link
                                Center(
                                  child: TextButton(
                                    onPressed: () => AppNavigation.goToSignup(context),
                                    child: const Text(
                                      'Don\'t have an account? Sign Up',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ).animate().fadeIn(delay: 1400.ms).slideY(begin: 0.3),
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