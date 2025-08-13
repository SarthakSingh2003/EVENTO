import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../routes/app_router.dart';

class SecureAccountScreen extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String username;

  const SecureAccountScreen({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
  });

  @override
  State<SecureAccountScreen> createState() => _SecureAccountScreenState();
}

class _SecureAccountScreenState extends State<SecureAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _securityAnswerController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isPhoneValid = false;
  
  String _selectedDay = '1';
  String _selectedMonth = 'January';
  String _selectedYear = '2000';
  String _selectedSecurityQuestion = 'What was your first pet\'s name?';
  
  final List<String> _days = List.generate(31, (index) => (index + 1).toString());
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final List<String> _years = List.generate(100, (index) => (2024 - index).toString());
  
  final List<String> _securityQuestions = [
    'What was your first pet\'s name?',
    'What was your mother\'s maiden name?',
    'What was the name of your first school?',
    'What is your favorite color?',
    'What was your childhood nickname?',
  ];

  @override
  void dispose() {
    _passwordController.dispose();
    _phoneController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }

  void _checkPhoneValidity(String phone) {
    setState(() {
      _isPhoneValid = phone.length >= 10 && phone.contains(RegExp(r'^[0-9\s]+$'));
    });
  }

  Future<void> _handleCreateAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final fullName = '${widget.firstName} ${widget.lastName}';
      
      // Parse birthday
      final monthIndex = _months.indexOf(_selectedMonth) + 1;
      final birthday = DateTime(
        int.parse(_selectedYear),
        monthIndex,
        int.parse(_selectedDay),
      );
      
      await authService.signUpWithEmailAndPassword(
        widget.email,
        _passwordController.text,
        fullName,
        UserRole.attendee, // Default role, can be changed later
        username: widget.username,
        birthday: birthday,
        phone: _phoneController.text.trim(),
        securityQuestion: _selectedSecurityQuestion,
        securityAnswer: _securityAnswerController.text.trim(),
      );
      
      // Navigation will be handled by the router
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
      body: SafeArea(
        child: Column(
          children: [
            // Yellow Header Section
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
                  const Text(
                    'Secure Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            
            // Main Content Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // White Card Container
                      Container(
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
                            // Birthday Field
                            const Text(
                              'Birthday',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedDay,
                                    decoration: InputDecoration(
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
                                    items: _days.map((day) {
                                      return DropdownMenuItem(
                                        value: day,
                                        child: Text(day),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() => _selectedDay = value!);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedMonth,
                                    decoration: InputDecoration(
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
                                    items: _months.map((month) {
                                      return DropdownMenuItem(
                                        value: month,
                                        child: Text(month),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() => _selectedMonth = value!);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedYear,
                                    decoration: InputDecoration(
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
                                    items: _years.map((year) {
                                      return DropdownMenuItem(
                                        value: year,
                                        child: Text(year),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() => _selectedYear = value!);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Password Field
                            const Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
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
                                  return 'Please enter a password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Phone Number Field
                            const Text(
                              'Phone Number',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppTheme.inputBackground,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.language, color: Colors.grey, size: 16),
                                      const SizedBox(width: 4),
                                      const Text('123', style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    onChanged: _checkPhoneValidity,
                                    decoration: InputDecoration(
                                      hintText: '1234 5678 9101',
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
                                      suffixIcon: _isPhoneValid
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                            )
                                          : null,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your phone number';
                                      }
                                      if (value.length < 10) {
                                        return 'Please enter a valid phone number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Security Question Field
                            const Text(
                              'Security Question',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedSecurityQuestion,
                              decoration: InputDecoration(
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
                              items: _securityQuestions.map((question) {
                                return DropdownMenuItem(
                                  value: question,
                                  child: Text(question),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedSecurityQuestion = value!);
                              },
                            ),
                            
                            const SizedBox(height: 12),
                            
                            TextFormField(
                              controller: _securityAnswerController,
                              decoration: InputDecoration(
                                hintText: 'Your Answer..',
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
                                  return 'Please enter your answer';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Create Account Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleCreateAccount,
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
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Back to Login Link
                            Center(
                              child: TextButton(
                                onPressed: () => AppNavigation.goToLogin(context),
                                child: const Text(
                                  'Back to Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                          ],
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
