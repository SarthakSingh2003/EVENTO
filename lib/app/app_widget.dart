import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/auth_service.dart';
import '../routes/app_router.dart';
import 'theme/app_theme.dart';
import '../core/services/theme_service.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, ThemeService>(
      builder: (context, authService, themeService, child) {
        // Create router instance for this build
        final appRouter = AppRouter(authService: authService);
        
        return MaterialApp.router(
          title: 'Evento',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          builder: (context, child) {
            // Clamp text scaling for better responsiveness across devices
            final mediaQuery = MediaQuery.of(context);
            final clampedTextScaler = mediaQuery.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.20);
            return MediaQuery(
              data: mediaQuery.copyWith(textScaler: clampedTextScaler),
              child: child ?? const SizedBox.shrink(),
            );
          },
          routerConfig: appRouter.router,
        );
      },
    );
  }
} 