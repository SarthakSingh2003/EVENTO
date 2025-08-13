import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/event_model.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/animated_logo.dart';
import '../../../routes/app_router.dart';
import '../widgets/event_card.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AnimatedLogo(size: 32, borderRadius: 8, showShadow: false),
            const SizedBox(width: 8),
            const Text(AppConstants.appName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => AppNavigation.goToProfile(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppConstants.searchEventsPlaceholder,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                
                const SizedBox(height: AppConstants.defaultPadding),
                
                // Category Filter
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: ['All', ...AppConstants.eventCategories].length,
                    itemBuilder: (context, index) {
                      final category = ['All', ...AppConstants.eventCategories][index];
                      final isSelected = _selectedCategory == category;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: AppConstants.smallPadding),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedCategory = category);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Events List
          Expanded(
            child: StreamBuilder<List<EventModel>>(
              stream: _firestoreService.getUpcomingEvents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularLoadingIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: AppConstants.defaultPadding),
                        Text(
                          'Error loading events',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        Text(
                          'Please try again later',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                final events = snapshot.data ?? [];
                final filteredEvents = _filterEvents(events);
                
                if (filteredEvents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                        const SizedBox(height: AppConstants.defaultPadding),
                        Text(
                          _searchController.text.isNotEmpty 
                              ? 'No events found' 
                              : 'No upcoming events',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'Try adjusting your search'
                              : 'Check back later for new events',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                  ),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
                      child: EventCard(
                        event: event,
                        onTap: () => AppNavigation.goToEventDetail(context, event.id!),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on events
              break;
            case 1:
              AppNavigation.goToMyTickets(context);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: AppConstants.eventsLabel,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: AppConstants.ticketsLabel,
          ),
        ],
      ),
    );
  }

  List<EventModel> _filterEvents(List<EventModel> events) {
    List<EventModel> filtered = events;

    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((event) {
        return event.title.toLowerCase().contains(query) ||
               event.description.toLowerCase().contains(query) ||
               event.location.toLowerCase().contains(query) ||
               event.category.toLowerCase().contains(query);
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((event) => event.category == _selectedCategory).toList();
    }

    return filtered;
  }
} 