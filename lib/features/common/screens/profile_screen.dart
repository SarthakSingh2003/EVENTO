import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/constants.dart';
import '../../../routes/app_router.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/theme_service.dart';
// import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            final didPop = await Navigator.of(context).maybePop();
            if (!didPop && context.mounted) {
              context.goNamed('home');
            }
          },
        ),
        title: const Text('Profile'),
        actions: [
          Builder(
            builder: (context) {
              final themeService = context.watch<ThemeService>();
              final isDark = themeService.isDarkMode;
              return IconButton(
                tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
                icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                onPressed: () => themeService.toggleDarkMode(!isDark),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            // User Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        authService.userModel?.name.isNotEmpty == true 
                            ? authService.userModel!.name[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    Text(
                      authService.userModel?.name ?? 'User',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      authService.userModel?.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Actions removed per request
            
            const Spacer(),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await authService.signOut();
                  if (context.mounted) {
                    AppNavigation.goToLogin(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}