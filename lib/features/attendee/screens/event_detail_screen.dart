import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/event_model.dart';
import '../../../core/models/ticket_model.dart';
import '../../../core/models/access_control_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/access_control_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../app/theme/app_theme.dart';
import '../widgets/access_control_appeal_form.dart';
import '../widgets/ticket_purchase_dialog.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  
  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  
  EventModel? _event;
  StreamSubscription<EventModel?>? _eventStreamSubscription;
  StreamSubscription<int>? _ticketCountStreamSubscription;
  bool _isLoading = true;
  bool _isPurchasing = false;
  bool _showAppealForm = false;
  AccessControlValidationResult? _accessValidation;
  StreamSubscription<String?>? _appealStatusStream;
  String? _appealStatus; // null | pending | approved | rejected
  bool _userHasTicket = false;
  
  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  @override
  void dispose() {
    _appealStatusStream?.cancel();
    _eventStreamSubscription?.cancel();
    _ticketCountStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadEvent() async {
    setState(() => _isLoading = true);
    
    try {
      final event = await _firestoreService.getEvent(widget.eventId);
      if (event != null) {
        // If event is cancelled/inactive, redirect away and show info
        if (event.isActive == false) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This event has been cancelled and is no longer available.'),
                backgroundColor: Colors.red,
              ),
            );
            context.go('/');
          }
          return;
        }
        // Auto-fix capacity if needed (migrate legacy events with totalTickets=0)
        await _firestoreService.autoFixEventCapacity(widget.eventId);
        
        // Sync the sold tickets count with actual ticket count
        await _firestoreService.syncSoldTicketsCount(widget.eventId);
        
        // Reload the event to get the updated sold tickets count
        final updatedEvent = await _firestoreService.getEvent(widget.eventId);
        if (updatedEvent != null) {
          if (updatedEvent.isActive == false) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This event has been cancelled and is no longer available.'),
                  backgroundColor: Colors.red,
                ),
              );
              context.go('/');
            }
            return;
          }
          setState(() => _event = updatedEvent);
          
          // Check if user already has a ticket for this event
          await _checkUserTicketStatus();
          
          await _validateAccessControl();
          _setupAppealStatusStream();
          // Start realtime listener for live updates to soldTickets/availability
          _eventStreamSubscription ??= _firestoreService.streamEvent(widget.eventId).listen((e) {
            if (e != null && mounted) {
              if (e.isActive == false) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This event has been cancelled and is no longer available.'),
                    backgroundColor: Colors.red,
                  ),
                );
                context.go('/');
                return;
              }
              setState(() => _event = e);
            }
          });

          // Live ticket count stream for dynamic availability
          _ticketCountStreamSubscription ??= _firestoreService.streamTicketCount(widget.eventId).listen((count) {
            if (_event != null && mounted) {
              setState(() => _event = _event!.copyWith(soldTickets: count));
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading event: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setupAppealStatusStream() {
    final userId = _authService.userModel?.id;
    if (_event?.id == null || userId == null) return;
    
    // Cancel existing stream if any
    _appealStatusStream?.cancel();
    
    _appealStatusStream = _firestoreService.streamUserAppealStatus(
      eventId: _event!.id!,
      userId: userId,
    ).listen((status) {
      if (!mounted) return;
      debugPrint('Appeal status updated: $status');
      setState(() {
        _appealStatus = status; // could be null/pending/approved/rejected
      });
    });
  }

  Future<void> _checkUserTicketStatus() async {
    try {
      final user = context.read<AuthService>().userModel;
      if (user != null && _event != null) {
        final hasTicket = await _firestoreService.hasUserTicketForEvent(user.id!, _event!.id!);
        if (mounted) {
          setState(() => _userHasTicket = hasTicket);
        }
      }
    } catch (e) {
      debugPrint('Error checking user ticket status: $e');
    }
  }

  Future<void> _validateAccessControl() async {
    if (_event == null) return;
    
    try {
      final user = context.read<AuthService>().userModel;
      if (user != null) {
        final validation = await AccessControlService.validateUserAccess(
          user: user,
          event: _event!,
          accessControl: _event!.accessControl,
        );
        setState(() => _accessValidation = validation);
      }
    } catch (e) {
      debugPrint('Error validating access control: $e');
    }
  }

  Future<void> _purchaseTicket() async {
    if (_event == null) return;
    
    // Debug information
    debugPrint('=== TICKET PURCHASE DEBUG ===');
    debugPrint('Event Title: ${_event!.title}');
    debugPrint('Total Tickets: ${_event!.totalTickets}');
    debugPrint('Sold Tickets: ${_event!.soldTickets}');
    debugPrint('Available Tickets: ${_event!.availableTickets}');
    debugPrint('Is Sold Out: ${_event!.isSoldOut}');
    debugPrint('Is Past: ${_event!.isPast}');
    debugPrint('Is Free: ${_event!.isFree}');
    debugPrint('Price: ${_event!.price}');
    debugPrint('============================');
    
    setState(() => _isPurchasing = true);
    
    try {
      // Show ticket purchase dialog
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => TicketPurchaseDialog(
          event: _event!,
          accessValidation: _accessValidation,
        ),
      );
      
      if (result != null && result['success'] == true) {
        // Optimistically update local sold count for immediate UI feedback
        final purchasedCount = (result['ticketCount'] ?? 0) as int;
        if (_event != null && purchasedCount > 0) {
          setState(() {
            _event = _event!.copyWith(soldTickets: _event!.soldTickets + purchasedCount);
          });
        }
        // Ticket purchased successfully - refresh event data
        await _loadEvent();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ticket purchased successfully!'),
              backgroundColor: AppTheme.successColor,
              action: SnackBarAction(
                label: 'View Ticket',
                textColor: AppTheme.secondaryColor,
                onPressed: () => context.go('/my-tickets'),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error purchasing ticket: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isPurchasing = false);
    }
  }

  Future<void> _submitAccessAppeal() async {
    if (_event == null) return;
    
    // Check if user already has a pending appeal
    if (_appealStatus == 'pending') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You already have a pending appeal for this event. Please wait for the organizer to review it.'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
      return;
    }
    
    // Debug information
    debugPrint('=== ACCESS APPEAL DEBUG ===');
    debugPrint('Event ID: ${_event!.id}');
    debugPrint('Event Title: ${_event!.title}');
    debugPrint('Has Access Control: ${_event!.accessControl != null}');
    debugPrint('Access Control ID: ${_event!.accessControl?.id}');
    debugPrint('Access Control Type: ${_event!.accessControl?.type}');
    debugPrint('Access Control Name: ${_event!.accessControl?.name}');
    debugPrint('Access Control Description: ${_event!.accessControl?.description}');
    debugPrint('Requires Access Control: ${_event!.requiresAccessControl}');
    debugPrint('Will use Access Control ID: ${_event!.accessControl?.id ?? _event!.id}');
    debugPrint('Current Appeal Status: $_appealStatus');
    debugPrint('==========================');
    
    // Check if access control exists
    if (_event!.accessControl == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No access control settings found for this event.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }
    
    try {
      // Show appeal form dialog
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AccessControlAppealForm(
          event: _event!,
          accessControl: _event!.accessControl!,
        ),
      );
      
      if (result == true) {
        if (mounted) {
          setState(() {
            _appealStatus = 'pending';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appeal submitted successfully! The organizer will review your request.'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
        // Re-validate access control after appeal
        await _validateAccessControl();
        // Restart the appeal status stream to get real-time updates
        _appealStatusStream?.cancel();
        _setupAppealStatusStream();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting appeal: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Creator control methods
  void _editEvent() {
    if (_event == null) return;
    
    // Navigate to edit event screen
    context.go('/edit-event/${_event!.id}');
  }

  void _viewAnalytics() {
    if (_event == null) return;
    
    // Navigate to analytics screen
    context.go('/event-analytics/${_event!.id}');
  }

  void _manageTickets() {
    if (_event == null) return;
    
    // Navigate to ticket management screen
    context.go('/ticket-management/${_event!.id}');
  }

  void _viewPaymentVerifications() {
    if (_event == null) return;
    
    // Navigate to payment verification screen
    context.go('/organizer-payment-verification/${_event!.id}?title=${Uri.encodeComponent(_event!.title)}');
  }

  void _viewAppeals() {
    if (_event == null) return;
    
    // Navigate to appeals management screen
    context.push('/view-appeals/${_event!.id}?title=${Uri.encodeComponent(_event!.title)}');
  }

  String _getAppealButtonText() {
    switch (_appealStatus) {
      case 'pending':
        return 'Appeal Pending (Under Review)';
      case 'approved':
        return 'Appeal Approved - Purchase Ticket';
      case 'rejected':
        return 'Submit Appeal (Rejected - Try Again)';
      default:
        return 'Submit Appeal';
    }
  }

  Future<void> _cancelEvent() async {
    if (_event == null) return;
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Event'),
        content: const Text(
          'Are you sure you want to cancel this event? This action cannot be undone and will:\n\n'
          '• Cancel all upcoming ticket sales\n'
          '• Notify all ticket holders\n'
          '• Mark the event as cancelled\n\n'
          'This action is irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, Keep Event'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel Event'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _performEventCancellation();
    }
  }

  Future<void> _performEventCancellation() async {
    if (_event == null) return;
    
    try {
      setState(() => _isLoading = true);
      
      // Update event status to cancelled
      await _firestoreService.updateEvent(_event!.id!, {
        'isActive': false,
        'status': 'Cancelled',
        'updatedAt': DateTime.now(),
      });
      
      // Send cancellation notification to ticket holders
      await _notifyTicketHolders();
      
      // Refresh event data
      await _loadEvent();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event has been cancelled successfully. All ticket holders have been notified.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling event: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _notifyTicketHolders() async {
    if (_event == null) return;
    
    try {
      // Get all tickets for this event
      final tickets = await _firestoreService.getEventTickets(_event!.id!).first;
      
      // Send notification to each ticket holder
      for (final ticket in tickets) {
        await _notificationService.sendEventUpdate(
          eventId: _event!.id!,
          eventTitle: _event!.title,
          updateMessage: 'The event "${_event!.title}" has been cancelled. Please check your email for refund information.',
        );
      }
      
      debugPrint('Sent cancellation notifications to ${tickets.length} ticket holders');
    } catch (e) {
      debugPrint('Error sending cancellation notifications: $e');
      // Don't fail the entire cancellation process if notifications fail
    }
  }

  Widget _buildActionButton() {
    if (_event == null) return const SizedBox.shrink();
    
    // Check if current user is the event creator
    final auth = context.read<AuthService>();
    final String? currentUserIdForCreator = auth.userModel?.id ?? auth.currentUser?.uid;
    final bool isEventCreator = currentUserIdForCreator != null && currentUserIdForCreator == _event!.organiserId;
    
    // If current user is the event creator, show creator controls
    if (isEventCreator) {
      return Column(
        children: [
          // Creator Controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Event Creator Controls',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _editEvent(),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.secondaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewAnalytics(),
                        icon: const Icon(Icons.analytics, size: 18),
                        label: const Text('Analytics'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _manageTickets(),
                        icon: const Icon(Icons.confirmation_number, size: 18),
                        label: const Text('Tickets'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewAppeals(),
                        icon: const Icon(Icons.security, size: 18),
                        label: const Text('Appeals'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _cancelEvent(),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewPaymentVerifications(),
                        icon: const Icon(Icons.payment, size: 18),
                        label: const Text('Payment Verifications'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }
    
    // If event is past, show "Event Ended" button
    if (_event!.isPast) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Event Ended'),
        ),
      );
    }
    
    // If event is sold out, show "Sold Out" button
    if (_event!.isSoldOut) {
      debugPrint('=== SOLD OUT DEBUG ===');
      debugPrint('Event: ${_event!.title}');
      debugPrint('Total Tickets: ${_event!.totalTickets}');
      debugPrint('Sold Tickets: ${_event!.soldTickets}');
      debugPrint('Available Tickets: ${_event!.availableTickets}');
      debugPrint('Is Sold Out: ${_event!.isSoldOut}');
      debugPrint('Calculation: ${_event!.soldTickets} >= ${_event!.totalTickets} = ${_event!.soldTickets >= _event!.totalTickets}');
      debugPrint('=====================');
      
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Sold Out'),
        ),
      );
    }
    
    // Check if user already has a ticket for this event
    if (_userHasTicket) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // Navigate to my tickets screen
            context.go('/my-tickets');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('View My Ticket'),
        ),
      );
    }
    
    // If there is an appeal status, it takes precedence over access control validation
    if (_appealStatus == 'pending') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Appeal Submitted (Pending Approval)'),
        ),
      );
    }

    if (_appealStatus == 'approved') {
      final bool hasQrManualPayment = _event?.paymentQrUrl != null && _event!.paymentQrUrl!.isNotEmpty && !_event!.isFree;
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isPurchasing
              ? null
              : () async {
                  if (hasQrManualPayment) {
                    final auth = context.read<AuthService>();
                    final user = auth.userModel;
                    if (user == null) return;
                    context.go('/payment-verification', extra: {
                      'event': _event,
                      'amount': _event!.price,
                      'userEmail': user.email,
                      'userName': user.name,
                    });
                  } else {
                    await _purchaseTicket();
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: AppTheme.secondaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isPurchasing
              ? const LoadingIndicator()
              : Text(
                  hasQrManualPayment
                      ? 'Proceed to Payment Verification'
                      : (_event!.isFree ? 'Get Ticket' : 'Buy Ticket'),
                ),
        ),
      );
    }

    // Check access control validation
    if (_accessValidation != null && !_accessValidation!.isEligible) {
      if (_accessValidation!.requiresAction) {
        // Appeal flow states
        // Default (no appeal yet or rejected): show submit appeal button
        final bool isRejected = _appealStatus == 'rejected';
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_isPurchasing || _appealStatus == 'pending') ? null : _submitAccessAppeal,
            style: ElevatedButton.styleFrom(
              backgroundColor: _appealStatus == 'pending' ? Colors.grey : AppTheme.warningColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isPurchasing
                ? const LoadingIndicator()
                : Text(_getAppealButtonText()),
          ),
        );
      } else {
        // Show disabled button with reason
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Not Eligible'),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Access Restricted',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _accessValidation!.reason ?? 'You are not eligible to purchase tickets for this event.',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    }
    
    // Check if current user is the event creator
    final String? currentUserId = auth.userModel?.id ?? auth.currentUser?.uid;
    final bool isEventCreatorForPurchase = _event?.organiserId == currentUserId;
    
    // If user is the creator, show "Manage Event" button instead of buy button
    if (isEventCreatorForPurchase) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // Navigate to event management screen
            context.go('/manage-event/${_event!.id}');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: AppTheme.secondaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Manage Event'),
        ),
      );
    }
    
    // Show purchase button for non-creators
    debugPrint('=== PURCHASE BUTTON DEBUG ===');
    debugPrint('Event: ${_event!.title}');
    debugPrint('Total Tickets: ${_event!.totalTickets}');
    debugPrint('Sold Tickets: ${_event!.soldTickets}');
    debugPrint('Available Tickets: ${_event!.availableTickets}');
    debugPrint('Is Sold Out: ${_event!.isSoldOut}');
    debugPrint('Is Free: ${_event!.isFree}');
    debugPrint('Price: ${_event!.price}');
    debugPrint('============================');
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isPurchasing ? null : _purchaseTicket,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.secondaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isPurchasing 
            ? const LoadingIndicator()
            : Text(_event!.isFree ? 'Get Free Ticket' : 'Buy Ticket'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Event Details'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.secondaryColor,
        ),
        body: const Center(child: LoadingIndicator()),
      );
    }
    
    if (_event == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Event Details'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.secondaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Event not found',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The event you\'re looking for doesn\'t exist or has been removed.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.secondaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvent,
            tooltip: 'Refresh ticket count',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: (_event == null || _isLoading) ? null : _shareEvent,
            tooltip: 'Share event',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Banner
            if (_event!.bannerImage != null)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(_event!.bannerImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Title
                  Text(
                    _event!.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Event Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _event!.isPast 
                          ? Colors.blue.withOpacity(0.1)
                          : _event!.isSoldOut
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _event!.isPast 
                          ? (_event!.isSoldOut ? 'Past Event - Sold Out' : 'Past Event - Tickets Available')
                          : _event!.status,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _event!.isPast 
                            ? Colors.blue[700]
                            : _event!.isSoldOut
                                ? Colors.red[700]
                                : Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  // Past event note
                  if (_event!.isPast && !_event!.isSoldOut)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This event has already taken place, but you can still get a ticket for record-keeping and proof of attendance.',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Event Info Grid
                  _buildInfoGrid(),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  _buildSection('Description', _event!.description),
                  
                  const SizedBox(height: 16),
                  
                  // Tags
                  if (_event!.tags.isNotEmpty)
                    _buildSection('Tags', _event!.tagsDisplay),
                  
                  const SizedBox(height: 16),
                  
                  // Organizer Info
                  _buildSection('Organizer', _event!.organiserName),
                  
                  if (_event!.contactInfo != null) ...[
                    const SizedBox(height: 16),
                    _buildSection('Contact', _event!.contactInfo!),
                  ],
                  
                  if (_event!.website != null) ...[
                    const SizedBox(height: 16),
                    _buildSection('Website', _event!.website!),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Action Button
                  _buildActionButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareEvent() async {
    if (_event == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event not loaded yet')),
        );
      }
      return;
    }
    final EventModel e = _event!;
    final String title = e.title;
    final String dateTime = e.formattedDateTime;
    final String location = e.location;
    final String price = e.formattedPrice;
    final String website = e.website ?? '';

    final String shareText = [
      title,
      'When: ' + dateTime,
      'Where: ' + location,
      'Price: ' + price,
      if (website.isNotEmpty) 'More info: ' + website,
      '',
      'Shared via EVENTO',
    ].join('\n');

    try {
      await Share.share(shareText, subject: 'Check out this event: ' + title);
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open share dialog: ' + err.toString())),
      );
    }
  }

  Widget _buildInfoGrid() {
    return Column(
      children: [
        // Enhanced Date and Time display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _event!.dayOfWeek,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _event!.formattedDate,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _event!.formattedTime,
                      style: TextStyle(
                        color: AppTheme.secondaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Other event details
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.location_on,
                title: 'Location',
                value: _event!.location,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.category,
                title: 'Category',
                value: _event!.category,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.attach_money,
                title: 'Price',
                value: _event!.formattedPrice,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.confirmation_number,
                title: 'Available',
                value: '${_event!.availableTickets} tickets',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
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
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
} 