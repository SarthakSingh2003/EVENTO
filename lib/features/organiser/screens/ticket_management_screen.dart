import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/event_model.dart';
import '../../../core/models/ticket_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/loading_indicator.dart';

class TicketManagementScreen extends StatefulWidget {
  final String eventId;
  
  const TicketManagementScreen({super.key, required this.eventId});

  @override
  State<TicketManagementScreen> createState() => _TicketManagementScreenState();
}

class _TicketManagementScreenState extends State<TicketManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  
  EventModel? _event;
  List<TicketModel> _tickets = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  
  @override
  void initState() {
    super.initState();
    _loadEventAndTickets();
  }

  Future<void> _loadEventAndTickets() async {
    setState(() => _isLoading = true);
    
    try {
      final event = await _firestoreService.getEvent(widget.eventId);
      if (event == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event not found. Please check the event ID.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          context.go('/'); // Navigate back to home
        }
        return;
      }
      
      // Check if current user is the event organizer
      final currentUser = _authService.currentUser;
      if (currentUser == null || currentUser.uid != event.organiserId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You don\'t have permission to manage this event.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          context.go('/'); // Navigate back to home
        }
        return;
      }
      
      final tickets = await _firestoreService.getEventTicketsFuture(widget.eventId);
      
      if (mounted) {
        setState(() {
          _event = event;
          _tickets = tickets;
        });
      }
    } catch (e) {
      debugPrint('Error loading tickets: $e');
      if (mounted) {
        String errorMessage = 'Error loading tickets';
        
        // Check if it's an index error and provide helpful message
        if (e.toString().contains('failed-precondition') || e.toString().contains('index')) {
          errorMessage = 'Database index is being created. Please try again in a few minutes.';
        } else if (e.toString().contains('permission-denied')) {
          errorMessage = 'You don\'t have permission to view these tickets.';
        } else {
          errorMessage = 'Error loading tickets: ${e.toString().split(':').last.trim()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _refreshTickets,
              textColor: Colors.white,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Get real-time ticket statistics
  Map<String, dynamic> get _ticketStats {
    final totalTickets = _tickets.length;
    final usedTickets = _tickets.where((t) => t.isUsed).length;
    final unusedTickets = totalTickets - usedTickets;
    
    // Calculate recent sales (last 7 days)
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final recentSales = _tickets.where((t) => 
      t.purchasedAt.isAfter(weekAgo)
    ).length;
    
    return {
      'total': totalTickets,
      'used': usedTickets,
      'unused': unusedTickets,
      'recentSales': recentSales,
      'usageRate': totalTickets > 0 ? (usedTickets / totalTickets) * 100 : 0.0,
    };
  }

  List<TicketModel> get _filteredTickets {
    switch (_selectedFilter) {
      case 'Used':
        return _tickets.where((ticket) => ticket.isUsed).toList();
      case 'Unused':
        return _tickets.where((ticket) => !ticket.isUsed).toList();
      default:
        return _tickets;
    }
  }

  Future<void> _refreshTickets() async {
    await _loadEventAndTickets();
  }

  @override
  Widget build(BuildContext context) {
         if (_isLoading) {
       return Scaffold(
         appBar: AppBar(
           title: const Text('Ticket Management'),
           backgroundColor: AppTheme.primaryColor,
           foregroundColor: AppTheme.secondaryColor,
           leading: IconButton(
             icon: const Icon(Icons.arrow_back),
             onPressed: () => context.go('/event/${widget.eventId}'),
           ),
         ),
         body: const Center(child: LoadingIndicator()),
       );
     }
    
         if (_event == null) {
       return Scaffold(
         appBar: AppBar(
           title: const Text('Event Not Found'),
           backgroundColor: AppTheme.primaryColor,
           foregroundColor: AppTheme.secondaryColor,
           leading: IconButton(
             icon: const Icon(Icons.arrow_back),
             onPressed: () => context.go('/event/${widget.eventId}'),
           ),
         ),
         body: const Center(
           child: Text('Event not found or you don\'t have permission to manage it.'),
         ),
       );
     }
    
         return Scaffold(
       backgroundColor: AppTheme.backgroundColor,
              appBar: AppBar(
          title: const Text('Ticket Management'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.secondaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/event/${widget.eventId}'),
          ),
         actions: [
           IconButton(
             icon: const Icon(Icons.refresh),
             onPressed: _refreshTickets,
             tooltip: 'Refresh Data',
           ),
           IconButton(
             icon: const Icon(Icons.qr_code_scanner),
             onPressed: () => context.go('/scan-tickets/${widget.eventId}'),
             tooltip: 'Scan Tickets',
           ),
         ],
       ),
      body: Column(
        children: [
          // Event Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _event!.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatChip('Total', _ticketStats['total'].toString()),
                      const SizedBox(width: 12),
                      _buildStatChip('Used', _ticketStats['used'].toString()),
                      const SizedBox(width: 12),
                      _buildStatChip('Unused', _ticketStats['unused'].toString()),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatChip('Recent Sales', _ticketStats['recentSales'].toString()),
                      const SizedBox(width: 12),
                      _buildStatChip('Usage Rate', '${_ticketStats['usageRate'].toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterTab('All', _tickets.length, _selectedFilter == 'All'),
                const SizedBox(width: 8),
                _buildFilterTab('Used', _tickets.where((t) => t.isUsed).length, _selectedFilter == 'Used'),
                const SizedBox(width: 8),
                _buildFilterTab('Unused', _tickets.where((t) => !t.isUsed).length, _selectedFilter == 'Unused'),
              ],
            ),
          ),
          
          // Tickets List
          Expanded(
            child: _filteredTickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.confirmation_number_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tickets found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tickets will appear here once they are purchased.',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = _filteredTickets[index];
                      return _buildTicketItem(ticket);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.primaryColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, int count, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppTheme.secondaryColor : AppTheme.primaryColor,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? AppTheme.secondaryColor : AppTheme.primaryColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketItem(TicketModel ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ticket Status Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ticket.isUsed 
                  ? Colors.red.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              ticket.isUsed 
                  ? Icons.check_circle
                  : Icons.confirmation_number,
              color: ticket.isUsed 
                  ? Colors.red
                  : Colors.blue,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Ticket Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ticket #${ticket.id?.substring(0, 8) ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ticket.userName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'User ID: ${ticket.userId.substring(0, 8)}...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          
          // Ticket Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ticket.isUsed 
                      ? Colors.red.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ticket.isUsed 
                      ? 'Used'
                      : 'Active',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ticket.isUsed 
                        ? Colors.red
                        : Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(ticket.purchasedAt),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
