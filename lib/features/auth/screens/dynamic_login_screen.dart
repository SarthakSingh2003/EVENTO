import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/helpers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../routes/app_router.dart';
import 'dart:ui'; // Added for ImageFilter

class DynamicLoginScreen extends StatefulWidget {
  const DynamicLoginScreen({super.key});

  @override
  State<DynamicLoginScreen> createState() => _DynamicLoginScreenState();
}

class _DynamicLoginScreenState extends State<DynamicLoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _savePassword = false;
  bool _showLoginForm = false;
  int _currentSlideIndex = 0;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late PageController _pageController;
  
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _eventSlides = [];
  bool _isLoadingEvents = true;

  // Fallback sample events when no real events exist
  final List<Map<String, dynamic>> _fallbackEvents = [
    {
      'color': Colors.purple,
      'title': 'Music Festival 2024',
      'date': 'March 15, 2024',
      'location': 'Central Park, NYC',
      'icon': Icons.music_note,
      'isFallback': true,
    },
    {
      'color': Colors.blue,
      'title': 'Tech Conference',
      'date': 'April 20, 2024',
      'location': 'Convention Center, SF',
      'icon': Icons.computer,
      'isFallback': true,
    },
    {
      'color': Colors.orange,
      'title': 'Food & Wine Expo',
      'date': 'May 10, 2024',
      'location': 'Downtown Plaza, LA',
      'icon': Icons.restaurant,
      'isFallback': true,
    },
    {
      'color': Colors.green,
      'title': 'Art Gallery Opening',
      'date': 'June 5, 2024',
      'location': 'Modern Art Museum, Chicago',
      'icon': Icons.palette,
      'isFallback': true,
    },
    {
      'color': Colors.red,
      'title': 'Startup Meetup',
      'date': 'July 12, 2024',
      'location': 'Innovation Hub, Austin',
      'icon': Icons.rocket_launch,
      'isFallback': true,
    },
  ];

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
    _pageController = PageController();
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
    
    // Load events (real or fallback)
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      setState(() => _isLoadingEvents = true);
      
      // Try to fetch real upcoming events
      final realEvents = await _firestoreService.getUpcomingEvents().first;
      
      if (realEvents.isNotEmpty) {
        // Convert real events to slide format
        _eventSlides = realEvents.take(5).map((event) => {
          'id': event.id,
          'title': event.title,
          'date': _formatDate(event.date),
          'location': event.location,
          'bannerImage': event.bannerImage,
          'category': event.category,
          'isFallback': false,
          'color': _getCategoryColor(event.category),
          'icon': _getCategoryIcon(event.category),
        }).toList();
      } else {
        // Use fallback events if no real events exist
        _eventSlides = _fallbackEvents;
      }
    } catch (e) {
      // If there's an error, use fallback events
      _eventSlides = _fallbackEvents;
    } finally {
      setState(() => _isLoadingEvents = false);
      // Start auto-slide after events are loaded
      _startAutoSlide();
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'music':
        return Colors.purple;
      case 'technology':
        return Colors.blue;
      case 'food & drink':
        return Colors.orange;
      case 'arts & culture':
        return Colors.green;
      case 'business':
        return Colors.red;
      case 'sports':
        return Colors.amber;
      case 'education':
        return Colors.indigo;
      case 'health & wellness':
        return Colors.teal;
      case 'entertainment':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'music':
        return Icons.music_note;
      case 'technology':
        return Icons.computer;
      case 'food & drink':
        return Icons.restaurant;
      case 'arts & culture':
        return Icons.palette;
      case 'business':
        return Icons.business;
      case 'sports':
        return Icons.sports_soccer;
      case 'education':
        return Icons.school;
      case 'health & wellness':
        return Icons.favorite;
      case 'entertainment':
        return Icons.movie;
      default:
        return Icons.event;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    if (_eventSlides.isEmpty) return;
    
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _pageController.hasClients) {
        _currentSlideIndex = (_currentSlideIndex + 1) % _eventSlides.length;
        _pageController.animateToPage(
          _currentSlideIndex,
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOutCubic,
        );
        _startAutoSlide(); // Continue the cycle
      }
    });
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
      
      if (success && mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (authService.isAuthenticated) {
          debugPrint('Google Sign-In successful, navigating to home');
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        } else {
          debugPrint('Authentication state not updated properly');
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
      body: Stack(
        children: [
          // Background slideshow
          _isLoadingEvents
              ? Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue,
                        Colors.blue.withOpacity(0.7),
                        Colors.blue.withOpacity(0.5),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentSlideIndex = index;
                    });
                  },
                  itemCount: _eventSlides.length,
                  itemBuilder: (context, index) {
                    final Map<String, dynamic> slide = _eventSlides[index];
                    final bool isFallback = (slide['isFallback'] as bool?) ?? false;
                    final Color slideColor = slide['color'] as Color;
                    final IconData slideIcon = slide['icon'] as IconData;
                    final String title = slide['title'] as String;
                    final String date = slide['date'] as String;
                    final String location = slide['location'] as String;
                    final String? bannerImage = slide['bannerImage'] as String?;
                    final String? category = slide['category'] as String?;
                    
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            slideColor,
                            slideColor.withOpacity(0.7),
                            slideColor.withOpacity(0.5),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Show real event image if available, otherwise use gradient
                          if (!isFallback && bannerImage != null)
                            Positioned.fill(
                              child: ClipRect(
                                child: ImageFiltered(
                                  imageFilter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                                  child: Transform.scale(
                                    scale: 1.1, // Slightly larger for parallax effect
                                    child: Image.network(
                                      bannerImage!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        // Fallback to gradient if image fails to load
                                        return Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                slideColor,
                                                slideColor.withOpacity(0.7),
                                                slideColor.withOpacity(0.5),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          
                          // Enhanced overlay gradient for better text readability
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.2),
                                  Colors.black.withOpacity(0.4),
                                  Colors.black.withOpacity(0.6),
                                ],
                                stops: const [0.0, 0.4, 0.7, 1.0],
                              ),
                            ),
                          ),
                          
                          // Additional subtle overlay for better contrast
                          Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 1.5,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                          
                          // Top gradient overlay for better button visibility
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 120,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.3),
                                    Colors.black.withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                          
                          // Event content with enhanced styling and animations
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOut,
                            child: AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 500),
                              child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                // Category badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        slideIcon,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isFallback ? 'Sample Event' : (category ?? 'Event'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Event title with enhanced typography
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                    height: 1.2,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                        color: Colors.black26,
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Event details with improved layout
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.calendar_today,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              date,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.location_on,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              location,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                        ],
                      ),
                    );
                  },
                ),
          
          // Enhanced slide indicators
          if (!_isLoadingEvents && _eventSlides.isNotEmpty)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _eventSlides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: _currentSlideIndex == index ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentSlideIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      boxShadow: _currentSlideIndex == index
                          ? [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          
          // Enhanced top right corner buttons with glassmorphism
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 20,
            child: Row(
              children: [
                // Login button with glassmorphism
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: ElevatedButton(
                        onPressed: () => setState(() => _showLoginForm = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Signup button with glassmorphism
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: OutlinedButton(
                        onPressed: () => AppNavigation.goToSignup(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.5),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 500.ms).slide(begin: const Offset(0.3, 0)),
          ),
          
          // App logo and title at center
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: 0,
            right: 0,
            child: Column(
              children: [
                ClipOval(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'lib/asssets/images/LOGO.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.5, 0.5)),
                const SizedBox(height: 20),
                Column(
                  children: [
                    const Text(
                      'EVENTO',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        shadows: [
                          Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 4,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    if (_eventSlides.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _eventSlides.first['isFallback'] == true 
                              ? Colors.white.withOpacity(0.2)
                              : Colors.green.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _eventSlides.first['isFallback'] == true ? 'Sample Events' : 'Live Events',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ).animate().fadeIn(delay: 400.ms).slide(begin: const Offset(0, 0.3)),
                const SizedBox(height: 8),
                const Text(
                  'Your Events, Your Way',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms).slide(begin: const Offset(0, 0.3)),
              ],
            ),
          ),
          
          // Login form overlay
          if (_showLoginForm)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double maxCardWidth = constraints.maxWidth < 480 ? constraints.maxWidth - 32 : 440;
                    final double radius = constraints.maxWidth < 360 ? 12 : 20;
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxCardWidth,
                        maxHeight: MediaQuery.of(context).size.height * 0.9,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(radius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(bottom: 12 + MediaQuery.of(context).viewInsets.bottom),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                      // Close button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _showLoginForm = false),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Login form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.black),
                              cursorColor: Colors.black,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'Email Address',
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                prefixIcon: const Icon(Icons.email_outlined),
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
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.black),
                              cursorColor: Colors.black,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword 
                                      ? Icons.visibility_outlined 
                                      : Icons.visibility_off_outlined,
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
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  value: _savePassword,
                                  onChanged: (value) {
                                    setState(() => _savePassword = value ?? false);
                                  },
                                  activeColor: AppTheme.primaryColor,
                                ),
                                const Text('Remember me'),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
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
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                              ),
                            ),
                            if (!isKeyboardVisible)
                              Column(
                                children: [
                                  const SizedBox(height: 16),
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
                                      label: const Text('Sign in with Google'),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Colors.grey),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account? "),
                                TextButton(
                                  onPressed: () {
                                    setState(() => _showLoginForm = false);
                                    AppNavigation.goToSignup(context);
                                  },
                                  child: const Text('Sign Up'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
