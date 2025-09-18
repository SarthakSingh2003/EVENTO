import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../../../core/models/event_model.dart';
import '../../../core/models/ticket_model.dart';
import '../../../core/models/access_control_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/access_control_service.dart';
import 'payment_options_dialog.dart';
import '../../../core/utils/constants.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../app/theme/app_theme.dart';
import 'package:provider/provider.dart';

class TicketPurchaseDialog extends StatefulWidget {
  final EventModel event;
  final AccessControlValidationResult? accessValidation;

  const TicketPurchaseDialog({
    super.key,
    required this.event,
    this.accessValidation,
  });

  @override
  State<TicketPurchaseDialog> createState() => _TicketPurchaseDialogState();
}

class _TicketPurchaseDialogState extends State<TicketPurchaseDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  
  int _quantity = 1;
  bool _isProcessing = false;
  String? _errorMessage;
  
  double get totalPrice => widget.event.price * 1; // Always 1 ticket
  String get formattedTotalPrice => '₹${totalPrice.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  widget.event.isFree ? Icons.confirmation_number : Icons.payment,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.event.isFree ? 'Get Free Ticket' : 'Purchase Ticket',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Past event warning (if applicable)
            if (widget.event.isPast)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This event has already taken place. You can still get a ticket for record-keeping and proof of attendance.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Event details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.event.location,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.event.formattedDate} at ${widget.event.formattedTime}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.confirmation_number,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.event.availableTickets} tickets available',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Quantity selector
            Row(
              children: [
                const Text(
                  'Quantity:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '1',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Price information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.event.isFree ? Icons.check_circle : Icons.payment,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.isFree ? 'Free Ticket' : 'Total Amount',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          widget.event.isFree ? 'No payment required' : formattedTotalPrice,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Error message
            if (_errorMessage != null) _buildErrorMessage(),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.secondaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const LoadingIndicator()
                        : Text(widget.event.isFree ? 'Get Ticket' : 'Purchase'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Number of Tickets',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '1',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.event.availableTickets} tickets available',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price per ticket:',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                widget.event.formattedPrice,
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quantity:',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$_quantity',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.blue),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                formattedTotalPrice,
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccessControlWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: Colors.orange[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This event requires approval. Your purchase will be pending until approved.',
              style: TextStyle(
                color: Colors.orange[800],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red[800],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPurchase() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final user = authService.userModel;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user already has a ticket for this event
      final hasExistingTicket = await _firestoreService.hasUserTicketForEvent(user.id!, widget.event.id!);
      if (hasExistingTicket) {
        throw Exception('You already have a ticket for this event. Only one ticket per person is allowed.');
      }

      // Validate access control again
      if (widget.accessValidation != null && !widget.accessValidation!.isEligible) {
        if (!widget.accessValidation!.requiresAction) {
          throw Exception(widget.accessValidation!.reason ?? 'Access denied');
        }
        // For events requiring approval, proceed with pending status
      }

      // Force quantity to 1 since only one ticket per user is allowed
      if (_quantity != 1) {
        throw Exception('Only 1 ticket per person is allowed for this event.');
      }

      // Check if enough tickets are available
      if (_quantity > widget.event.availableTickets) {
throw Exception('Not enough tickets available');
      }

      // Reserve 1 ticket atomically before charging/issuing
      final reserved = await _firestoreService.reserveTickets(widget.event.id!, 1);
      if (!reserved) {
        // Re-sync to ensure UI reflects current remaining and show clear message
        await _firestoreService.syncSoldTicketsCount(widget.event.id!);
        throw Exception('Not enough tickets available for this event');
      }

      if (widget.event.isFree) {
        await _processFreeTicket(user);
      } else {
        await _processPaidTicket(user);
      }

      // Success
      if (mounted) {
        Navigator.of(context).pop({
          'success': true,
          'ticketCount': 1,
          'totalAmount': totalPrice,
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processFreeTicket(UserModel user) async {
    // Create 1 free ticket
    final ticket = TicketModel(
      eventId: widget.event.id!,
      eventTitle: widget.event.title,
      userId: user.id!,
      userName: user.name,
      qrCode: _generateQRCode(),
      price: 0.0,
      isFree: true,
      purchasedAt: DateTime.now(),
    );
    await _firestoreService.createTicket(ticket);

    // Sync the sold tickets count with actual ticket count (safety)
    await _firestoreService.syncSoldTicketsCount(widget.event.id!);
  }

  Future<void> _processPaidTicket(UserModel user) async {
    // If organizer provided a manual payment QR, redirect to verification instead of instant payment
    final bool hasQrManualPayment = widget.event.paymentQrUrl != null && widget.event.paymentQrUrl!.isNotEmpty;
    if (hasQrManualPayment) {
      if (mounted) {
        Navigator.of(context).pop();
        final auth = context.read<AuthService>();
        final currentUser = auth.userModel;
        if (currentUser != null) {
          // Navigate to payment verification screen; organizer will issue ticket after verification
          Navigator.of(context).pushNamed('/payment-verification', arguments: {
            'event': widget.event,
            'amount': totalPrice,
            'userEmail': currentUser.email,
            'userName': currentUser.name,
          });
        }
      }
      return;
    }

    // Otherwise proceed with existing payment gateway flow
    final paymentResult = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentOptionsDialog(
        amount: totalPrice,
        eventTitle: widget.event.title,
        userEmail: user.email,
        userPhone: user.phone ?? '',
        notes: {
          'eventId': widget.event.id,
          'userId': user.id,
          'quantity': '1',
          'event': widget.event,
        },
        onPaymentResult: (result) {
          Navigator.of(context).pop(result);
        },
      ),
    );

    if (paymentResult != null && paymentResult['success'] == true) {
      final transactionId = paymentResult['paymentId'] ?? paymentResult['transactionId'];
      final ticket = TicketModel(
        eventId: widget.event.id!,
        eventTitle: widget.event.title,
        userId: user.id!,
        userName: user.name,
        qrCode: _generateQRCode(),
        price: widget.event.price,
        isFree: false,
        purchasedAt: DateTime.now(),
        transactionId: transactionId,
      );
      await _firestoreService.createTicket(ticket);
      await _firestoreService.syncSoldTicketsCount(widget.event.id!);
    } else {
      throw Exception('Payment failed: ${paymentResult?['error'] ?? 'Payment cancelled'}');
    }
  }


  String _generateQRCode() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return 'EVENTO_${List.generate(12, (index) => chars[random.nextInt(chars.length)]).join()}';
  }

  
}
