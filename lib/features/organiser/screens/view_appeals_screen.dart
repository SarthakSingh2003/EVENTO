import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../app/theme/app_theme.dart';
import 'dart:io';

class ViewAppealsScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const ViewAppealsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<ViewAppealsScreen> createState() => _ViewAppealsScreenState();
}

class _ViewAppealsScreenState extends State<ViewAppealsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Appeals - ${widget.eventTitle}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.secondaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh appeals',
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.streamAppealsForEvent(widget.eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.security_outlined,
                      size: 64,
                      color: Colors.orange[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Permission Required',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'To view appeals, please ensure you are the event organizer and that Firestore rules are properly configured.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error: ${snapshot.error.toString()}',
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

          final appeals = snapshot.data ?? [];
          
          if (appeals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No appeals yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Access requests will appear here when users submit appeals for this event.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: appeals.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final appeal = appeals[index];
              return _buildAppealCard(appeal);
            },
          );
        },
      ),
    );
  }

  Widget _buildAppealCard(Map<String, dynamic> appeal) {
    // Debug: Print appeal data to understand the structure
    debugPrint('=== APPEAL DEBUG ===');
    debugPrint('Appeal data: $appeal');
    debugPrint('documentImageUrl: ${appeal['documentImageUrl']}');
    debugPrint('documentImagePath: ${appeal['documentImagePath']}');
    debugPrint('===================');
    
    final status = (appeal['status'] ?? 'pending') as String;
    final isPending = status == 'pending';
    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isApproved
              ? Colors.green.withOpacity(0.3)
              : isRejected
                  ? Colors.red.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and status
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    (appeal['userName'] ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appeal['userName'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        appeal['userEmail'] ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isApproved
                        ? Colors.green.withOpacity(0.1)
                        : isRejected
                            ? Colors.red.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isApproved
                          ? Colors.green
                          : isRejected
                              ? Colors.red
                              : Colors.orange,
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: isApproved
                          ? Colors.green[700]
                          : isRejected
                              ? Colors.red[700]
                              : Colors.orange[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Appeal details
            _buildDetailSection('Reason for Request', appeal['reason'] ?? 'No reason provided'),
            
            if ((appeal['additionalInfo'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailSection('Additional Information', appeal['additionalInfo']),
            ],

            if ((appeal['invitationCode'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailSection('Invitation Code', appeal['invitationCode']),
            ],

            // Document upload section
            if ((appeal['documentImageUrl'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDocumentSection(appeal['documentImageUrl'], isUrl: true),
            ] else if ((appeal['documentImagePath'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDocumentSection(appeal['documentImagePath'], isUrl: false),
            ],

            // Submission date
            const SizedBox(height: 12),
            _buildDetailSection(
              'Submitted',
              _formatDate(appeal['submittedAt']),
            ),

            // Review info (if reviewed)
            if (isApproved || isRejected) ...[
              const SizedBox(height: 12),
              _buildDetailSection(
                'Reviewed',
                _formatDate(appeal['reviewedAt']),
              ),
              if ((appeal['reviewerName'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailSection('Reviewed by', appeal['reviewerName']),
              ],
              if ((appeal['reviewNotes'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailSection('Review Notes', appeal['reviewNotes']),
              ],
            ],

            const SizedBox(height: 16),

            // Action buttons (only for pending appeals)
            if (isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _reviewAppeal(appeal, true),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Approve', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _reviewAppeal(appeal, false),
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text('Reject', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Show review status for completed appeals
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isApproved
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isApproved ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isApproved ? Icons.check_circle : Icons.cancel,
                      color: isApproved ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isApproved ? 'Appeal Approved' : 'Appeal Rejected',
                      style: TextStyle(
                        color: isApproved ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentSection(String documentPath, {required bool isUrl}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Uploaded Document',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isUrl 
                ? Image.network(
                    documentPath,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[100],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[100],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load document',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : Image.file(
                    File(documentPath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[100],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Document not found\n(Old format - please resubmit)',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'Unknown';
    
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return 'Invalid date';
      }
      
      return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Future<void> _reviewAppeal(Map<String, dynamic> appeal, bool approve) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Approve Appeal' : 'Reject Appeal'),
        content: Text(
          approve
              ? 'Are you sure you want to approve this appeal? The user will be able to purchase tickets for this event.'
              : 'Are you sure you want to reject this appeal? The user will not be able to purchase tickets for this event.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: approve ? Colors.green : Colors.red,
            ),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestoreService.updateAppealStatus(
        eventId: appeal['eventId'],
        userId: appeal['userId'],
        status: approve ? 'approved' : 'rejected',
        reviewedBy: _authService.currentUser?.uid,
        reviewerName: _authService.userModel?.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? 'Appeal approved successfully. User can now purchase tickets.'
                  : 'Appeal rejected. User has been notified.',
            ),
            backgroundColor: approve ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating appeal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
