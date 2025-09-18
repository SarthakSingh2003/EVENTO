import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/event_model.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/animated_logo.dart';
import '../../../app/theme/app_theme.dart';
import '../../../routes/app_router.dart';
import '../widgets/event_card.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _isLoading = false;
  
  late TabController _tabController;
  List<EventModel> _upcomingEvents = [];
  List<EventModel> _pastEvents = [];
  List<String> _selectedTags = [];
  
  // Available tags for filtering
  final List<String> _availableTags = [
    'tech', 'music', 'business', 'food', 'art', 'sports', 
    'education', 'health', 'entertainment', 'startup', 
    'networking', 'festival', 'conference', 'workshop'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    
    try {
      // Load upcoming events with synced ticket counts
      _upcomingEvents = await _firestoreService.getUpcomingEventsWithSync();
      
      // Load past events
      final pastStream = _firestoreService.getPastEvents();
      _pastEvents = await pastStream.first;
      
    } catch (e) {
      debugPrint('Error loading events: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterEvents() {
    // This method is now handled directly in _buildEventsList
    // Keeping it for compatibility with existing calls
  }

  void _onSearchChanged(String value) {
    _filterEvents();
  }

  void _onTagSelected(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
      _filterEvents();
    });
  }

  void _onTabChanged() {
    _filterEvents();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        title: Row(
          children: [
            const AnimatedLogo(size: 32, borderRadius: 8, showShadow: false),
            const SizedBox(width: 8),
            const Text('EVENTO', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Refresh events',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => AppNavigation.goToProfile(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) => _onTabChanged(),
          indicatorColor: Theme.of(context).colorScheme.onSurface,
          labelColor: Theme.of(context).colorScheme.onSurface,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'My Events'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search events...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterEvents();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Tags Filter
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableTags.length,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemBuilder: (context, index) {
                      final tag = _availableTags[index];
                      final isSelected = _selectedTags.contains(tag);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(tag, overflow: TextOverflow.ellipsis),
                          selected: isSelected,
                          onSelected: (selected) => _onTagSelected(tag),
                          backgroundColor: isSelected 
                              ? Theme.of(context).colorScheme.primary 
                              : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          selectedColor: Theme.of(context).colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
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
            child: _isLoading
                ? const Center(child: LoadingIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Upcoming Events Tab
                      _buildEventsList(_upcomingEvents, 'upcoming'),
                      
                      // Past Events Tab
                      _buildEventsList(_pastEvents, 'past'),
                      
                      // My Events Tab
                      _buildMyEventsList(),
                    ],
                  ),
          ),
        ],
      ),
      
      // Floating Action Buttons - My Tickets and Create Event
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: () => AppNavigation.goToMyTickets(context),
            backgroundColor: AppTheme.secondaryColor,
            foregroundColor: AppTheme.primaryColor,
            icon: const Icon(Icons.confirmation_number),
            label: const Text('My Tickets'),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: () => AppNavigation.goToCreateEvent(context),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: AppTheme.secondaryColor,
            icon: const Icon(Icons.add),
            label: const Text('Create Event'),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<EventModel> events, String type) {
    // Apply filtering to the events based on current tab
    List<EventModel> filteredEvents;
    
    if (_searchController.text.isEmpty && _selectedTags.isEmpty) {
      filteredEvents = events;
    } else {
      filteredEvents = events.where((event) {
        bool matchesSearch = _searchController.text.isEmpty ||
            event.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            event.description.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            event.location.toLowerCase().contains(_searchController.text.toLowerCase());

        bool matchesTags = _selectedTags.isEmpty ||
            _selectedTags.any((tag) => event.tags.contains(tag));

        return matchesSearch && matchesTags;
      }).toList();
    }
    
    if (filteredEvents.isEmpty) {
      // Show appropriate message based on whether there are no events or no filtered results
      if (events.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type == 'upcoming' ? Icons.event_busy : Icons.history,
                size: 64,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                type == 'upcoming' ? 'No upcoming events' : 'No past events',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                type == 'upcoming' 
                    ? 'Check back later for new events!'
                    : 'Events will appear here after they\'re completed',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      } else {
        // No events match the current filters
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'No events found',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search or filters',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredEvents.length,
        itemBuilder: (context, index) {
          final event = filteredEvents[index];
          return EventCard(
            event: event,
            showCreatorActions: false,
          );
        },
      ),
    );
  }

  Widget _buildMyEventsList() {
    // Get current user's events from filtered events (which includes search/filter)
    final currentUserId = _authService.userModel?.id;
    final myUpcomingEvents = _upcomingEvents.where((event) => 
      event.organiserId == currentUserId
    ).toList();
    final myPastEvents = _pastEvents.where((event) => 
      event.organiserId == currentUserId
    ).toList();
    final myEvents = [...myUpcomingEvents, ...myPastEvents];
    
    // Apply search and filter to my events
    final filteredMyEvents = myEvents.where((event) {
      bool matchesSearch = _searchController.text.isEmpty ||
          event.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          event.description.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          event.location.toLowerCase().contains(_searchController.text.toLowerCase());

      bool matchesTags = _selectedTags.isEmpty ||
          _selectedTags.any((tag) => event.tags.contains(tag));

      return matchesSearch && matchesTags;
    }).toList();
    
    if (myEvents.isEmpty) {
      if (currentUserId != null && currentUserId.isNotEmpty) {
        return FutureBuilder<List<EventModel>>(
          future: _firestoreService.getUserEvents(currentUserId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: LoadingIndicator());
            }
            final fetched = snapshot.data ?? [];
            if (fetched.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_note,
                      size: 64,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Events Created Yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first event to get started!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => AppNavigation.goToCreateEvent(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Your First Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.secondaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final filteredFetched = fetched.where((event) {
              bool matchesSearch = _searchController.text.isEmpty ||
                  event.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                  event.description.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                  event.location.toLowerCase().contains(_searchController.text.toLowerCase());

              bool matchesTags = _selectedTags.isEmpty ||
                  _selectedTags.any((tag) => event.tags.contains(tag));

              return matchesSearch && matchesTags;
            }).toList();

            return RefreshIndicator(
              onRefresh: _loadEvents,
              color: AppTheme.primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredFetched.length,
                itemBuilder: (context, index) {
                  final event = filteredFetched[index];
                  return EventCard(
                    event: event,
                    showCreatorActions: true,
                  );
                },
              ),
            );
          },
        );
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 64,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'No Events Created Yet',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first event to get started!',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => AppNavigation.goToCreateEvent(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.secondaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    if (filteredMyEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'No events found',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }
    
    // Show user's events with filtering
    return RefreshIndicator(
      onRefresh: _loadEvents,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredMyEvents.length,
        itemBuilder: (context, index) {
          final event = filteredMyEvents[index];
          return EventCard(
            event: event,
            showCreatorActions: true, // Enable creator actions
          );
        },
      ),
    );
  }
} 