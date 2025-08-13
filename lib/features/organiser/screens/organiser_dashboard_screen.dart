import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/event_model.dart';
import '../../../core/utils/constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/animated_logo.dart';
import '../../../routes/app_router.dart';

class OrganiserDashboardScreen extends StatelessWidget {
  const OrganiserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();
    final firestoreService = FirestoreService();
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AnimatedLogo(size: 32, borderRadius: 8, showShadow: false),
            const SizedBox(width: 8),
            const Text('Organiser Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => AppNavigation.goToProfile(context),
          ),
        ],
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: firestoreService.getEventsByOrganiser(authService.userModel?.id ?? 'mock-user-id'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final events = snapshot.data ?? [];
          final upcomingEvents = events.where((e) => e.isUpcoming).toList();
          final pastEvents = events.where((e) => e.isPast).toList();
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${authService.userModel?.name ?? 'Organiser'}!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        Text(
                          'Manage your events and track their performance',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: AppConstants.largePadding),
                
                // Quick Actions
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        text: 'Create Event',
                        icon: Icons.add,
                        onPressed: () => AppNavigation.goToCreateEvent(context),
                      ),
                    ),
                    const SizedBox(width: AppConstants.defaultPadding),
                    Expanded(
                      child: OutlineButton(
                        text: 'Past Events',
                        icon: Icons.history,
                        onPressed: () => AppNavigation.goToPastEvents(context),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppConstants.largePadding),
                
                // Upcoming Events
                Text(
                  'Upcoming Events (${upcomingEvents.length})',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                
                if (upcomingEvents.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.largePadding),
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 48,
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                          ),
                          const SizedBox(height: AppConstants.defaultPadding),
                          Text(
                            'No upcoming events',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppConstants.smallPadding),
                          Text(
                            'Create your first event to get started',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: upcomingEvents.length,
                    itemBuilder: (context, index) {
                      final event = upcomingEvents[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                            child: Icon(
                              Icons.event,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            event.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${event.formattedDate} • ${event.soldTickets}/${event.totalTickets} tickets sold',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => AppNavigation.goToManageEvent(context, event.id!),
                          ),
                        ),
                      );
                    },
                  ),
                
                const SizedBox(height: AppConstants.largePadding),
                
                // Past Events Summary
                if (pastEvents.isNotEmpty) ...[
                  Text(
                    'Past Events (${pastEvents.length})',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppConstants.defaultPadding),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'View past events',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'See analytics and feedback from your past events',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () => AppNavigation.goToPastEvents(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
} 