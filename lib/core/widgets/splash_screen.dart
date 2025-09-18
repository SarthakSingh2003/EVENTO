import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with animation - clipped to circle
            ClipOval(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Image.asset(
                  'lib/asssets/images/LOGO.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 800.ms)
                .scale(begin: const Offset(0.5, 0.5), duration: 800.ms)
                .then()
                .shimmer(duration: 1000.ms, delay: 500.ms),
            
            const SizedBox(height: 40),
            
            // App name with typewriter effect
            const Text(
              'EVENTO',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'Poppins',
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 1000.ms)
                .slideY(begin: 0.3, duration: 1000.ms),
            
            const SizedBox(height: 16),
            
            // Tagline
            const Text(
              'Your Events, Your Way',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontFamily: 'Poppins',
              ),
            )
                .animate()
                .fadeIn(delay: 1000.ms, duration: 1000.ms)
                .slideY(begin: 0.3, duration: 1000.ms),
          ],
        ),
      ),
    );
  }
}
