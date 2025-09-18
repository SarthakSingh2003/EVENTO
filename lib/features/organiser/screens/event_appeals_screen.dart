import 'package:flutter/material.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../app/theme/app_theme.dart';

class EventAppealsScreen extends StatefulWidget {
  final String eventId;

  const EventAppealsScreen({super.key, required this.eventId});

  @override
  State<EventAppealsScreen> createState() => _EventAppealsScreenState();
}

class _EventAppealsScreenState extends State<EventAppealsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Requests'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.secondaryColor,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.streamAppealsForEvent(widget.eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final appeals = snapshot.data ?? [];
          if (appeals.isEmpty) {
            return const Center(child: Text('No access requests yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final a = appeals[index];
              return _buildAppealTile(a);
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: appeals.length,
          );
        },
      ),
    );
  }

  Widget _buildAppealTile(Map<String, dynamic> appeal) {
    final status = (appeal['status'] ?? 'pending') as String;
    final isPending = status == 'pending';
    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';
    return Container(
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
}


