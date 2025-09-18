import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/services/auth_service.dart';
import '../core/models/user_model.dart';
import '../features/auth/screens/dynamic_login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../core/widgets/splash_screen.dart';
import '../features/organiser/screens/create_event_screen.dart';
import '../features/organiser/screens/manage_event_screen.dart';
import '../features/organiser/screens/edit_event_screen.dart';
import '../features/organiser/screens/event_analytics_screen.dart';
import '../features/organiser/screens/scan_tickets_screen.dart';
import '../features/organiser/screens/ticket_management_screen.dart';
import '../features/organiser/screens/event_appeals_screen.dart';
import '../features/organiser/screens/view_appeals_screen.dart';
import '../features/moderator/screens/qr_scanner_screen.dart';
import '../features/attendee/screens/event_list_screen.dart';
import '../features/attendee/screens/event_detail_screen.dart';
import '../features/attendee/screens/my_tickets_screen.dart';
import '../features/attendee/screens/qr_payment_screen.dart';
import '../features/attendee/screens/payment_verification_screen.dart';
import '../features/attendee/screens/payment_verification_status_screen.dart';
import '../features/organiser/screens/payment_verification_screen.dart' as organizer_payment;
import '../features/common/screens/profile_screen.dart';

class AppRouter {
  final AuthService authService;

  AppRouter({required this.authService});

  GoRouter get router => GoRouter(
    initialLocation: '/splash',
    redirect: _handleRedirect,
    refreshListenable: authService, // Listen to auth service changes
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const DynamicLoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // Create Event Route (Direct access)
      GoRoute(
        path: '/create-event',
        name: 'create_event',
        builder: (context, state) => const CreateEventScreen(),
      ),

      // Manage Event Route
      GoRoute(
        path: '/manage-event/:eventId',
        name: 'manage_event',
        builder: (context, state) => ManageEventScreen(
          eventId: state.pathParameters['eventId']!,
        ),
      ),

      // Edit Event Route
      GoRoute(
        path: '/edit-event/:eventId',
        name: 'edit_event',
        builder: (context, state) => EditEventScreen(
          eventId: state.pathParameters['eventId']!,
        ),
      ),

      // Event Analytics Route
      GoRoute(
        path: '/event-analytics/:eventId',
        name: 'event_analytics',
        builder: (context, state) => EventAnalyticsScreen(
          eventId: state.pathParameters['eventId']!,
        ),
      ),

      // Scan Tickets Route
      GoRoute(
        path: '/scan-tickets/:eventId',
        name: 'scan_tickets',
        builder: (context, state) => ScanTicketsScreen(
          eventId: state.pathParameters['eventId']!,
        ),
      ),

      // Ticket Management Route
      GoRoute(
        path: '/ticket-management/:eventId',
        name: 'ticket_management',
        builder: (context, state) => TicketManagementScreen(
          eventId: state.pathParameters['eventId']!,
        ),
      ),

      // Event Appeals Route
      GoRoute(
        path: '/event-appeals/:eventId',
        name: 'event_appeals',
        builder: (context, state) => EventAppealsScreen(
          eventId: state.pathParameters['eventId']!,
        ),
      ),

      // View Appeals Route (detailed view)
      GoRoute(
        path: '/view-appeals/:eventId',
        name: 'view_appeals',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final eventTitle = state.uri.queryParameters['title'] ?? 'Event';
          return ViewAppealsScreen(
            eventId: eventId,
            eventTitle: eventTitle,
          );
        },
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
          GoRoute(
            path: 'qr-payment',
            name: 'qr_payment',
            builder: (context, state) {
              final args = state.extra as Map<String, dynamic>?;
              return QRPaymentScreen(
                event: args?['event'],
                amount: args?['amount'] ?? 0.0,
                userEmail: args?['userEmail'] ?? '',
                userName: args?['userName'] ?? '',
              );
            },
          ),
          GoRoute(
            path: 'payment-verification',
            name: 'payment_verification',
            builder: (context, state) {
              final args = state.extra as Map<String, dynamic>?;
              return PaymentVerificationScreen(
                event: args?['event'],
                amount: args?['amount'] ?? 0.0,
                userEmail: args?['userEmail'] ?? '',
                userName: args?['userName'] ?? '',
              );
            },
          ),
          GoRoute(
            path: 'payment-verification-status',
            name: 'payment_verification_status',
            builder: (context, state) {
              final eventId = state.uri.queryParameters['eventId'] ?? '';
              final title = state.uri.queryParameters['title'] ?? 'Event';
              return PaymentVerificationStatusScreen(eventId: eventId, eventTitle: title);
            },
          ),
        ],
      ),

      // Organizer Payment Verification Route
      GoRoute(
        path: '/organizer-payment-verification/:eventId',
        name: 'organizer_payment_verification',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final eventTitle = state.uri.queryParameters['title'] ?? 'Event';
          return organizer_payment.OrganizerPaymentVerificationScreen(
            eventId: eventId,
            eventTitle: eventTitle,
          );
        },
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

    // Debug logging
    debugPrint('Router Redirect - Auth: $isAuthenticated, Role: $userRole, Path: $currentPath');

    // If not authenticated, redirect to login (but allow splash screen)
    if (!isAuthenticated) {
      if (currentPath != '/login' && currentPath != '/signup' && currentPath != '/splash') {
        debugPrint('Redirecting to login - not authenticated');
        return '/login';
      }
      return null;
    }

    // If authenticated, redirect to home if on auth pages
    if (isAuthenticated) {
      if (currentPath == '/login' || currentPath == '/signup') {
        debugPrint('User is authenticated, redirecting to home');
        return '/';
      }
    }

    return null;
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

  static void goToCreateEvent(BuildContext context) {
    context.go('/create-event');
  }

  static void goToManageEvent(BuildContext context, String eventId) {
    context.go('/manage-event/$eventId');
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