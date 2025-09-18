import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/event_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/payment_verification_service.dart';
import '../../../core/models/payment_verification_model.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageEventScreen extends StatefulWidget {
  final String eventId;
  
  const ManageEventScreen({super.key, required this.eventId});

  @override
  State<ManageEventScreen> createState() => _ManageEventScreenState();
}

class _ManageEventScreenState extends State<ManageEventScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  
  EventModel? _event;
  bool _isLoading = true;
  Stream<List<Map<String, dynamic>>>? _appealsStream;
  List<Map<String, dynamic>> _appeals = const [];
  List<PaymentVerificationModel> _paymentVerifications = [];
  bool _isLoadingPayments = false;
  
  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    try {
      final event = await _firestoreService.getEvent(widget.eventId);
      if (mounted) {
        setState(() {
          _event = event;
          _isLoading = false;
        });
      }
      if (event != null) {
        _setupAppealsStream();
        _loadPaymentVerifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading event: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _setupAppealsStream() {
    _appealsStream ??= _firestoreService.streamAppealsForEvent(widget.eventId);
    _appealsStream!.listen((list) {
      if (!mounted) return;
      setState(() {
        _appeals = list;
      });
    });
  }

  Future<void> _loadPaymentVerifications() async {
    setState(() {
      _isLoadingPayments = true;
    });
    try {
      final verifications = await PaymentVerificationService.getEventPaymentVerifications(widget.eventId);
      if (mounted) {
        setState(() {
          _paymentVerifications = verifications;
          _isLoadingPayments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPayments = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading payment verifications: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Event'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.secondaryColor,
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
        ),
        body: const Center(
          child: Text('Event not found or you don\'t have permission to manage it.'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Event'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.secondaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/edit-event/${_event!.id}'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Banner
            if (_event!.bannerImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    _event!.bannerImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Event Title
            Text(
              _event!.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Event Stats
            _buildStatsCard(),
            
            const SizedBox(height: 24),
            
            // Management Actions
            _buildManagementActions(),
            
            const SizedBox(height: 24),

            // Payment Verifications
            _buildPaymentVerificationsSection(),
            
            // Access Appeals
            _buildAppealsSection(),
            
            // Event Details
            _buildEventDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentVerificationsSection() {
    final primaryStream = FirebaseFirestore.instance
        .collection('payment_verifications')
        .where('eventId', isEqualTo: widget.eventId)
        .snapshots();
    final legacyStream = FirebaseFirestore.instance
        .collection('payment_verifications')
        .where('eventID', isEqualTo: widget.eventId)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: primaryStream,
      builder: (context, primarySnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: legacyStream,
          builder: (context, legacySnap) {
            final primaryDocs = primarySnap.data?.docs ?? const [];
            final legacyDocs = legacySnap.data?.docs ?? const [];
            final allDocs = [...primaryDocs, ...legacyDocs];
            final byId = <String, PaymentVerificationModel>{};
            for (final d in allDocs) {
              final model = PaymentVerificationModel.fromMap({
                ...d.data(),
                'id': d.id,
              });
              byId[model.id] = model;
            }
            final items = byId.values.toList()
              ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

            final pendingCount = items.where((v) => v.isPending).length;
            final verifiedCount = items.where((v) => v.isVerified).length;
            final rejectedCount = items.where((v) => v.isRejected).length;

            final showSpinner = primarySnap.connectionState == ConnectionState.waiting || legacySnap.connectionState == ConnectionState.waiting;
            final error = primarySnap.error ?? legacySnap.error;

            return Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.payment, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Verifications',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (showSpinner)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          TextButton(
                            onPressed: _loadPaymentVerifications,
                            child: const Text('Refresh'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildPaymentStatItem('Pending', pendingCount, Colors.orange),
                        _buildPaymentStatItem('Verified', verifiedCount, Colors.green),
                        _buildPaymentStatItem('Rejected', rejectedCount, Colors.red),
                      ],
                    ),
                    if (items.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Recent Verifications',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...items.take(3).map((verification) =>
                          _buildPaymentVerificationItem(verification)
                        ).toList(),
                      if (items.length > 3)
                        TextButton(
                          onPressed: () => context.go('/organizer-payment-verification/${_event!.id}?title=${Uri.encodeComponent(_event!.title)}'),
                          child: Text('View All (${items.length})'),
                        ),
                    ] else if (error != null) ...[
                      const SizedBox(height: 16),
                      Text('Error: $error', style: const TextStyle(color: Colors.red)),
                    ] else ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'No payment verifications yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentStatItem(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentVerificationItem(PaymentVerificationModel verification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _getStatusColor(verification.status).withOpacity(0.1),
            child: Icon(
              _getStatusIcon(verification.status),
              size: 16,
              color: _getStatusColor(verification.status),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verification.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  verification.formattedAmount,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (verification.isPending) ...[
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _approvePayment(verification),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
              ),
              child: const Text('Approve', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: () => _rejectPayment(verification),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
              ),
              child: const Text('Reject', style: TextStyle(fontSize: 12)),
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(verification.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStatusColor(verification.status)),
              ),
              child: Text(
                verification.status.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(verification.status),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'verified':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Future<void> _approvePayment(PaymentVerificationModel verification) async {
    try {
      final authService = context.read<AuthService>();
      final user = authService.userModel;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await PaymentVerificationService.verifyPayment(
        verificationId: verification.id,
        verifiedBy: user.name,
        isApproved: true,
      );

      // Create ticket for the user
      await _createTicketForUser(verification);

      // Refresh the list
      await _loadPaymentVerifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment approved and ticket issued to ${verification.userName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectPayment(PaymentVerificationModel verification) async {
    final reasonController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Payment Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject this payment verification?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection (optional)',
                hintText: 'Enter reason for rejection...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final authService = context.read<AuthService>();
        final user = authService.userModel;
        
        if (user == null) {
          throw Exception('User not authenticated');
        }

        await PaymentVerificationService.verifyPayment(
          verificationId: verification.id,
          verifiedBy: user.name,
          isApproved: false,
          rejectionReason: reasonController.text.trim().isNotEmpty 
              ? reasonController.text.trim() 
              : 'Payment verification rejected',
        );

        // Refresh the list
        await _loadPaymentVerifications();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment verification rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject payment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _createTicketForUser(PaymentVerificationModel verification) async {
    try {
      final firestoreService = FirestoreService();
      
      // Generate QR code for ticket
      final qrCode = _generateQRCode();
      
      // Create ticket
      final ticket = {
        'eventId': verification.eventId,
        'eventTitle': verification.eventTitle,
        'userId': verification.userId,
        'userName': verification.userName,
        'qrCode': qrCode,
        'price': verification.amount,
        'isFree': false,
        'purchasedAt': DateTime.now().toIso8601String(),
        'transactionId': verification.transactionId,
        'paymentVerified': true,
        'verifiedAt': DateTime.now().toIso8601String(),
      };

      await firestoreService.createTicketFromMap(ticket);
    } catch (e) {
      throw Exception('Failed to create ticket: $e');
    }
  }

  String _generateQRCode() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return 'EVENTO_${random.toString().substring(5)}';
  }

  Widget _buildAppealsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Access Requests',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_appeals.isEmpty)
              const Text('No access requests yet.'),
            if (_appeals.isNotEmpty)
              ..._appeals.map((a) => _buildAppealTile(a)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppealTile(Map<String, dynamic> appeal) {
    final status = (appeal['status'] ?? 'pending') as String;
    final isPending = status == 'pending';
    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${appeal['userName']} (${appeal['userEmail']})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isApproved
                      ? Colors.green.withOpacity(0.1)
                      : isRejected
                          ? Colors.red.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: isApproved
                        ? Colors.green[700]
                        : isRejected
                            ? Colors.red[700]
                            : Colors.orange[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(appeal['reason'] ?? ''),
          if ((appeal['additionalInfo'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              appeal['additionalInfo'],
              style: const TextStyle(color: Colors.grey),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isPending ? () => _reviewAppeal(appeal, true) : null,
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Approve', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isPending ? () => _reviewAppeal(appeal, false) : null,
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text('Reject', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _reviewAppeal(Map<String, dynamic> appeal, bool approve) async {
    try {
      await _firestoreService.updateAppealStatus(
        eventId: appeal['eventId'],
        userId: appeal['userId'],
        status: approve ? 'approved' : 'rejected',
        reviewedBy: _authService.currentUser?.uid,
        reviewerName: _authService.userModel?.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Appeal approved' : 'Appeal rejected'),
          backgroundColor: approve ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating appeal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Tickets',
                    _event!.totalTickets.toString(),
                    Icons.confirmation_number,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Sold Tickets',
                    _event!.soldTickets.toString(),
                    Icons.shopping_cart,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Available',
                    _event!.availableTickets.toString(),
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildManagementActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Creator Controls',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToEditEvent(),
                    icon: const Icon(Icons.edit, color: Colors.black),
                    label: const Text('Edit', style: TextStyle(color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToAnalytics(),
                    icon: const Icon(Icons.analytics, color: Colors.yellow),
                    label: const Text('Analytics', style: TextStyle(color: Colors.yellow)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToScanTickets(),
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.yellow),
                    label: const Text('Tickets', style: TextStyle(color: Colors.yellow)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/event-appeals/${_event!.id}'),
                    icon: const Icon(Icons.security, color: Colors.white),
                    label: const Text('Access Requests', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showCancelConfirmation,
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/organizer-payment-verification/${_event!.id}?title=${Uri.encodeComponent(_event!.title)}'),
                    icon: const Icon(Icons.payment, color: Colors.white),
                    label: const Text('Payment Verifications', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showDeleteConfirmation,
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text('Delete Event', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditEvent() {
    try {
      print('Navigating to edit event: ${_event!.id}');
      context.go('/edit-event/${_event!.id}');
    } catch (e) {
      print('Error navigating to edit screen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error navigating to edit screen: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _navigateToAnalytics() {
    try {
      print('Navigating to analytics: ${_event!.id}');
      context.go('/event-analytics/${_event!.id}');
    } catch (e) {
      print('Error navigating to analytics screen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error navigating to analytics screen: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _navigateToScanTickets() {
    try {
      print('Navigating to scan tickets: ${_event!.id}');
      context.go('/scan-tickets/${_event!.id}');
    } catch (e) {
      print('Error navigating to scan tickets screen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error navigating to scan tickets screen: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Event'),
        content: const Text('Are you sure you want to cancel this event? This will mark the event as cancelled and notify all attendees.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Event'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelEvent();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Event'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelEvent() async {
    try {
      print('Cancelling event: ${widget.eventId}');
      await _firestoreService.updateEvent(widget.eventId, {
        'isActive': false,
        'cancelledAt': DateTime.now().toIso8601String(),
      });
      
      if (mounted) {
        // Update local state immediately
        setState(() {
          _event = _event?.copyWith(
            isActive: false,
          );
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event cancelled successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        // Navigate back after a short delay to ensure UI updates
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.go('/');
          }
        });
      }
    } catch (e) {
      print('Error cancelling event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling event: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildEventDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Date', _event!.formattedDate),
            _buildDetailRow('Time', _event!.formattedTime),
            _buildDetailRow('Location', _event!.location),
            _buildDetailRow('Category', _event!.category),
            _buildDetailRow('Price', _event!.formattedPrice),
            _buildDetailRow('Status', _event!.status),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent() async {
    try {
      print('Deleting event: ${widget.eventId}');
      await _firestoreService.deleteEvent(widget.eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event deleted successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      print('Error deleting event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting event: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
