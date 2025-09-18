import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/payment_verification_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/payment_verification_model.dart';

class PaymentVerificationStatusScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const PaymentVerificationStatusScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<PaymentVerificationStatusScreen> createState() => _PaymentVerificationStatusScreenState();
}

class _PaymentVerificationStatusScreenState extends State<PaymentVerificationStatusScreen> {
  PaymentVerificationModel? _verification;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthService>();
      final user = auth.userModel;
      if (user == null) throw Exception('User not authenticated');
      final verification = await PaymentVerificationService.getUserVerificationForEvent(
        eventId: widget.eventId,
        userId: user.id,
      );
      setState(() {
        _verification = verification;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verification - ${widget.eventTitle}')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_verification == null) {
      return Center(
        child: Text('No verification found for this event.'),
      );
    }

    final v = _verification!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _statusChip(v.status),
            const Spacer(),
            Text(v.formattedSubmittedAt, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          Text('Amount: ${v.formattedAmount}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          if (v.transactionId.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Transaction ID: ${v.transactionId}', style: TextStyle(color: Colors.grey[700])),
          ],
          const SizedBox(height: 12),
          if (v.isRejected && v.rejectionReason != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
              child: Text('Rejected: ${v.rejectionReason}', style: TextStyle(color: Colors.red[800])),
            ),
          if (v.isPending)
            Text('Your payment is pending review by the organiser.', style: TextStyle(color: Colors.orange[800])),
          if (v.isVerified)
            Text('Approved! Your ticket has been issued.', style: TextStyle(color: Colors.green[800])),
          const Spacer(),
          ElevatedButton(
            onPressed: _load,
            child: const Text('Refresh Status'),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    String text;
    switch (status) {
      case 'pending':
        color = Colors.orange; text = 'Pending'; break;
      case 'verified':
        color = Colors.green; text = 'Verified'; break;
      case 'rejected':
        color = Colors.red; text = 'Rejected'; break;
      default:
        color = Colors.grey; text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), border: Border.all(color: color), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}


