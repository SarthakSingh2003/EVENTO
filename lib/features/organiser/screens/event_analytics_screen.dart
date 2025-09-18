import 'package:flutter/material.dart';
import '../../../core/models/event_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/loading_indicator.dart';
import 'package:go_router/go_router.dart';

class EventAnalyticsScreen extends StatefulWidget {
  final String eventId;
  
  const EventAnalyticsScreen({super.key, required this.eventId});

  @override
  State<EventAnalyticsScreen> createState() => _EventAnalyticsScreenState();
}

class _EventAnalyticsScreenState extends State<EventAnalyticsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  EventModel? _event;
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};
  
  @override
  void initState() {
    super.initState();
    _loadEventAndAnalytics();
  }

  Future<void> _loadEventAndAnalytics() async {
    try {
      final event = await _firestoreService.getEvent(widget.eventId);
      final analytics = await _firestoreService.getEventStatistics(widget.eventId);
      
      if (mounted) {
        setState(() {
          _event = event;
          _analytics = analytics;
        });
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      if (mounted) {
        String errorMessage = 'Error loading analytics';
        
        // Check if it's an index error and provide helpful message
        if (e.toString().contains('failed-precondition') || e.toString().contains('index')) {
          errorMessage = 'Database index is being created. Please try again in a few minutes.';
        } else if (e.toString().contains('permission-denied')) {
          errorMessage = 'You don\'t have permission to view this event.';
        } else {
          errorMessage = 'Error loading analytics: ${e.toString().split(':').last.trim()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadEventAndAnalytics,
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

  @override
  Widget build(BuildContext context) {
         if (_isLoading) {
       return Scaffold(
         appBar: AppBar(
           title: const Text('Event Analytics'),
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
           title: const Text('Event Analytics'),
           backgroundColor: AppTheme.primaryColor,
           foregroundColor: AppTheme.secondaryColor,
           leading: IconButton(
             icon: const Icon(Icons.arrow_back),
             onPressed: () => context.go('/event/${widget.eventId}'),
           ),
         ),
         body: const Center(
           child: Text('Event not found'),
         ),
       );
     }
    
           return Scaffold(
              appBar: AppBar(
          title: const Text('Event Analytics'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.secondaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/event/${widget.eventId}'),
          ),
         actions: [
           IconButton(
             icon: const Icon(Icons.refresh),
             onPressed: _loadEventAndAnalytics,
           ),
         ],
       ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Header
            _buildEventHeader(),
            
            const SizedBox(height: 24),
            
            // Key Metrics
            _buildKeyMetrics(),
            
            const SizedBox(height: 24),
            
            // Real-time Statistics
            _buildRealTimeStats(),
            
            const SizedBox(height: 24),
            
            // Ticket Sales Chart
            _buildTicketSalesChart(),
            
            const SizedBox(height: 24),
            
            // Revenue Analysis
            _buildRevenueAnalysis(),
            
            const SizedBox(height: 24),
            
            // Attendance Insights
            _buildAttendanceInsights(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _event!.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analytics Dashboard',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _event!.formattedDate,
                        style: TextStyle(color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _event!.location,
                        style: TextStyle(color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetrics() {
    final totalTickets = _analytics['totalTickets'] ?? 0;
    final usedTickets = _analytics['usedTickets'] ?? 0;
    final unusedTickets = _analytics['unusedTickets'] ?? 0;
    final soldTickets = _analytics['soldTickets'] ?? 0;
    final availableTickets = _analytics['availableTickets'] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
                              child: _buildMetricCard(
                  'Total Tickets',
                  totalTickets.toString(),
                  Icons.confirmation_number,
                  AppTheme.primaryColor,
                ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Sold Tickets',
                soldTickets.toString(),
                Icons.shopping_cart,
                Colors.green,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Available',
                availableTickets.toString(),
                Icons.check_circle,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Used',
                usedTickets.toString(),
                Icons.person,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Real-time Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Recent Sales (7d)',
                '${_analytics['recentSales'] ?? 0}',
                Icons.trending_up,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Monthly Sales',
                '${_analytics['monthlySales'] ?? 0}',
                Icons.calendar_month,
                Colors.indigo,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Avg Tickets/Day',
                '${_analytics['avgTicketsPerDay']?.toStringAsFixed(1) ?? '0.0'}',
                Icons.schedule,
                Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Days Active',
                '${_analytics['daysSinceCreation'] ?? 0}',
                Icons.timer,
                Colors.deepOrange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTicketSalesChart() {
    final soldTickets = _analytics['soldTickets'] ?? 0;
    final totalTickets = _analytics['totalTickets'] ?? 0;
    final percentage = totalTickets > 0 ? (soldTickets / totalTickets) : 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ticket Sales Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Progress Bar
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              minHeight: 12,
            ),
            
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(percentage * 100).toStringAsFixed(1)}% Sold',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  '$soldTickets / $totalTickets',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Sales Timeline
            _buildSalesTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesTimeline() {
    final recentSales = _analytics['recentSales'] ?? 0;
    final monthlySales = _analytics['monthlySales'] ?? 0;
    final soldTickets = _analytics['soldTickets'] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sales Timeline',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Real timeline data from Firebase
        _buildTimelineItem('Last 7 Days', '$recentSales tickets sold', Colors.green),
        _buildTimelineItem('Last 30 Days', '$monthlySales tickets sold', Colors.blue),
        _buildTimelineItem('Total Sold', '$soldTickets tickets sold', AppTheme.primaryColor),
      ],
    );
  }

  Widget _buildTimelineItem(String period, String sales, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              period,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            sales,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueAnalysis() {
    if (_event!.isFree) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Revenue Analysis',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This is a free event. No revenue analysis available.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    final totalRevenue = _analytics['totalRevenue'] ?? 0.0;
    final potentialRevenue = _event!.totalTickets * _event!.price;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildRevenueCard(
                    'Total Revenue',
                    '\$${totalRevenue.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRevenueCard(
                    'Potential Revenue',
                    '\$${potentialRevenue.toStringAsFixed(2)}',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Revenue breakdown
            _buildRevenueBreakdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(String title, String amount, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              amount,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueBreakdown() {
    final totalRevenue = _analytics['totalRevenue'] ?? 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenue Breakdown',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        _buildBreakdownItem('Ticket Sales', totalRevenue),
        _buildBreakdownItem('Processing Fees', 0.0), // Mock data
        _buildBreakdownItem('Platform Fees', 0.0), // Mock data
        const Divider(),
        _buildBreakdownItem('Net Revenue', totalRevenue, isTotal: true),
      ],
    );
  }

  Widget _buildBreakdownItem(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceInsights() {
    final attendanceRate = _analytics['attendanceRate'] ?? 0.0;
    final usedTickets = _analytics['usedTickets'] ?? 0;
    final totalTickets = _analytics['totalTickets'] ?? 0;
    final avgTicketsPerDay = _analytics['avgTicketsPerDay'] ?? 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Insights',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Attendance rate
            _buildInsightItem(
              'Expected Attendance Rate',
              '${attendanceRate.toStringAsFixed(1)}%',
              Icons.people,
              Colors.green,
            ),
            
            const SizedBox(height: 12),
            
            // Peak hours
            _buildInsightItem(
              'Peak Registration Hours',
              '2:00 PM - 4:00 PM',
              Icons.access_time,
              Colors.blue,
            ),
            
            const SizedBox(height: 12),
            
            // Popular demographics
            _buildInsightItem(
              'Popular Age Group',
              '25-34 years',
              Icons.person,
              Colors.orange,
            ),
            
            const SizedBox(height: 12),
            
            // Geographic distribution
            _buildInsightItem(
              'Top Location',
              'Local Area (60%)',
              Icons.location_on,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
