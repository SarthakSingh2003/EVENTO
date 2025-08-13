import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/services/auth_service.dart';
import '../core/models/user_model.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/organiser/screens/organiser_dashboard_screen.dart';
import '../features/organiser/screens/create_event_screen.dart';
import '../features/organiser/screens/manage_event_screen.dart';
import '../features/organiser/screens/view_past_events_screen.dart';
import '../features/moderator/screens/qr_scanner_screen.dart';
import '../features/attendee/screens/event_list_screen.dart';
import '../features/attendee/screens/event_detail_screen.dart';
import '../features/attendee/screens/my_tickets_screen.dart';
import '../features/common/screens/profile_screen.dart';

class AppRouter {
  final AuthService authService;

  AppRouter({required this.authService});

  GoRouter get router => GoRouter(
    initialLocation: '/',
    redirect: _handleRedirect,
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // Organiser Routes
      GoRoute(
        path: '/organiser',
        name: 'organiser_dashboard',
        builder: (context, state) => const OrganiserDashboardScreen(),
        routes: [
          GoRoute(
            path: 'create-event',
            name: 'create_event',
            builder: (context, state) => const CreateEventScreen(),
          ),
          GoRoute(
            path: 'manage-event/:eventId',
            name: 'manage_event',
            builder: (context, state) {
              final eventId = state.pathParameters['eventId'] ?? '';
              return ManageEventScreen(eventId: eventId);
            },
          ),
          GoRoute(
            path: 'past-events',
            name: 'past_events',
            builder: (context, state) => const ViewPastEventsScreen(),
          ),
        ],
      ),

      // Moderator Routes
      GoRoute(
        path: '/moderator',
        name: 'moderator_scanner',
        builder: (context, state) => const QRScannerScreen(),
      ),

      // Attendee Routes
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const EventListScreen(),
        routes: [
          GoRoute(
            path: 'event/:eventId',
            name: 'event_detail',
            builder: (context, state) {
              final eventId = state.pathParameters['eventId'] ?? '';
              return EventDetailScreen(eventId: eventId);
            },
          ),
          GoRoute(
            path: 'my-tickets',
            name: 'my_tickets',
            builder: (context, state) => const MyTicketsScreen(),
          ),
        ],
      ),

      // Common Routes
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => _buildErrorScreen(context, state),
  );

  String? _handleRedirect(BuildContext context, GoRouterState state) {
    final isAuthenticated = authService.isAuthenticated;
    final userRole = authService.userRole;
    final currentPath = state.fullPath;

    // If not authenticated, redirect to login
    if (!isAuthenticated) {
      if (currentPath != '/login' && currentPath != '/signup') {
        return '/login';
      }
      return null;
    }

    // If authenticated, handle role-based routing
    if (isAuthenticated && userRole != null) {
      // If on auth pages, redirect to appropriate dashboard
      if (currentPath == '/login' || currentPath == '/signup') {
        return _getDashboardPath(userRole);
      }

      // Check if user has access to current route
      if (userRole != null && currentPath != null && !_hasAccessToRoute(userRole, currentPath!)) {
        return _getDashboardPath(userRole);
      }
    }

    return null;
  }

  String _getDashboardPath(UserRole role) {
    switch (role) {
      case UserRole.organiser:
        return '/organiser';
      case UserRole.moderator:
        return '/moderator';
      case UserRole.attendee:
        return '/';
    }
  }

  bool _hasAccessToRoute(UserRole role, String path) {
    switch (role) {
      case UserRole.organiser:
        return path.startsWith('/organiser') || 
               path == '/profile' || 
               path == '/';
      case UserRole.moderator:
        return path.startsWith('/moderator') || 
               path == '/profile' || 
               path == '/';
      case UserRole.attendee:
        return path.startsWith('/') && 
               !path.startsWith('/organiser') && 
               !path.startsWith('/moderator') || 
               path == '/profile';
    }
  }

  Widget _buildErrorScreen(BuildContext context, GoRouterState state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// Navigation helpers
class AppNavigation {
  static void goToLogin(BuildContext context) {
    context.go('/login');
  }

  static void goToSignup(BuildContext context) {
    context.go('/signup');
  }

  static void goToHome(BuildContext context) {
    context.go('/');
  }

  static void goToProfile(BuildContext context) {
    context.go('/profile');
  }

  static void goToEventDetail(BuildContext context, String eventId) {
    context.go('/event/$eventId');
  }

  static void goToMyTickets(BuildContext context) {
    context.go('/my-tickets');
  }

  static void goToOrganiserDashboard(BuildContext context) {
    context.go('/organiser');
  }

  static void goToCreateEvent(BuildContext context) {
    context.go('/organiser/create-event');
  }

  static void goToManageEvent(BuildContext context, String eventId) {
    context.go('/organiser/manage-event/$eventId');
  }

  static void goToPastEvents(BuildContext context) {
    context.go('/organiser/past-events');
  }

  static void goToModeratorScanner(BuildContext context) {
    context.go('/moderator');
  }

  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  static void goBackToHome(BuildContext context) {
    context.go('/');
  }
} 