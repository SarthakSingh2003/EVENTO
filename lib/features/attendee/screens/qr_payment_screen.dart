import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/models/event_model.dart';
import '../../../app/theme/app_theme.dart';

class QRPaymentScreen extends StatefulWidget {
  final EventModel event;
  final double amount;
  final String userEmail;
  final String userName;

  const QRPaymentScreen({
    super.key,
    required this.event,
    required this.amount,
    required this.userEmail,
    required this.userName,
  });

  @override
  State<QRPaymentScreen> createState() => _QRPaymentScreenState();
}

class _QRPaymentScreenState extends State<QRPaymentScreen> {
  bool _hasPaid = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEventInfo(),
            const SizedBox(height: 24),
            _buildPaymentInfo(),
            const SizedBox(height: 24),
            _buildQRCodeSection(),
            const SizedBox(height: 24),
            _buildInstructions(),
            const SizedBox(height: 24),
            _buildPaymentButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventInfo() {
    return Container(
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.event.location,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.event, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${widget.event.formattedDate} at ${widget.event.formattedTime}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.payment,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount to Pay',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '₹${widget.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Scan QR Code to Pay',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: QrImageView(
              data: _generateQRData(),
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Use any UPI app to scan and pay',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Payment Instructions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            '1',
            'Scan the QR code above with any UPI app (PhonePe, Google Pay, Paytm, etc.)',
          ),
          const SizedBox(height: 8),
          _buildInstructionStep(
            '2',
            'Enter the amount: ₹${widget.amount.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          _buildInstructionStep(
            '3',
            'Complete the payment using your preferred UPI app',
          ),
          const SizedBox(height: 8),
          _buildInstructionStep(
            '4',
            'Take a screenshot of the payment confirmation',
          ),
          const SizedBox(height: 8),
          _buildInstructionStep(
            '5',
            'Click "I Have Paid" and upload the screenshot',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue[700],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _hasPaid ? null : _proceedToVerification,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _hasPaid ? 'Payment Submitted' : 'I Have Paid - Upload Screenshot',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _generateQRData() {
    // Generate a simple UPI payment string
    // In a real implementation, you would use actual UPI payment details
    final upiId = 'evento@paytm'; // This should be your actual UPI ID
    final amount = widget.amount.toStringAsFixed(2);
    final eventName = widget.event.title.replaceAll(' ', '%20');
    
    return 'upi://pay?pa=$upiId&pn=EVENTO&am=$amount&cu=INR&tn=$eventName';
  }

  void _proceedToVerification() {
    Navigator.of(context).pushNamed(
      '/payment-verification',
      arguments: {
        'event': widget.event,
        'amount': widget.amount,
        'userEmail': widget.userEmail,
        'userName': widget.userName,
      },
    );
  }
}
