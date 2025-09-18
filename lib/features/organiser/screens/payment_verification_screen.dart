import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/payment_verification_model.dart';
import '../../../core/services/payment_verification_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../app/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class OrganizerPaymentVerificationScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const OrganizerPaymentVerificationScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<OrganizerPaymentVerificationScreen> createState() => _OrganizerPaymentVerificationScreenState();
}

class _OrganizerPaymentVerificationScreenState extends State<OrganizerPaymentVerificationScreen> {
  List<PaymentVerificationModel> _verifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'all'; // 'all', 'pending', 'verified', 'rejected'
  String _searchQuery = '';
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscriptionAlt;
  bool _attemptedFallbackOnce = false;

  @override
  void initState() {
    super.initState();
    _subscribeToVerifications();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscriptionAlt?.cancel();
    super.dispose();
  }

  void _subscribeToVerifications() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    Map<String, dynamic> _normalize(Map<String, dynamic> raw, String id) {
      final eventId = (raw['eventId'] ?? raw['eventID'] ?? raw['event_id'] ?? '').toString();
      final submittedAt = raw['submittedAt'];
      final status = (raw['status'] ?? 'pending').toString().toLowerCase();
      return {
        ...raw,
        'id': id,
        'eventId': eventId,
        'status': status,
        'submittedAt': submittedAt,
      };
    }
    // Primary: filter by eventId to comply with Firestore rules
    _subscription = FirebaseFirestore.instance
        .collection('payment_verifications')
        .where('eventId', isEqualTo: widget.eventId)
        .snapshots()
        .listen((snapshot) {
      final items = snapshot.docs
          .map((doc) => PaymentVerificationModel.fromMap(_normalize(doc.data(), doc.id)))
          .toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      if (mounted) {
        setState(() {
          _verifications = items;
          _isLoading = false;
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    });

    // Fallback subscription for legacy field eventID
    _subscriptionAlt = FirebaseFirestore.instance
        .collection('payment_verifications')
        .where('eventID', isEqualTo: widget.eventId)
        .snapshots()
        .listen((snapshot) {
      final items = snapshot.docs
          .map((doc) => PaymentVerificationModel.fromMap(_normalize(doc.data(), doc.id)))
          .toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      if (mounted && items.isNotEmpty) {
        setState(() {
          final existing = {for (final v in _verifications) v.id: v};
          for (final v in items) {
            existing.putIfAbsent(v.id, () => v);
          }
          _verifications = existing.values.toList()
            ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          _isLoading = false;
        });
      }
    });

    // Final safety net: if both streams yield nothing after a short delay,
    // try a one-shot load to surface items even if real-time is blocked.
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted || _attemptedFallbackOnce) return;
      if (_verifications.isEmpty && _errorMessage == null) {
        try {
          _attemptedFallbackOnce = true;
          final list = await PaymentVerificationService.getEventPaymentVerifications(widget.eventId);
          if (mounted && list.isNotEmpty) {
            setState(() {
              _verifications = list;
              _isLoading = false;
            });
          }
        } catch (_) {
          // ignore; keep current state
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Verifications - ${widget.eventTitle}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.white),
                  hintText: 'Search by name, email, or transaction ID',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              // If no previous screen, go back to event detail
              context.go('/event/${widget.eventId}');
            }
          },
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _onStatusFilterChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Verifications'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('Pending Only'),
              ),
              const PopupMenuItem(
                value: 'verified',
                child: Text('Verified Only'),
              ),
              const PopupMenuItem(
                value: 'rejected',
                child: Text('Rejected Only'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getStatusFilterText(),
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 64, tablet: 72, desktop: 80),
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
              const ResponsiveText(
                'Error loading verifications',
                mobileFontSize: 18,
                tabletFontSize: 20,
                desktopFontSize: 22,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
              ResponsiveText(
                _errorMessage!,
                mobileFontSize: 14,
                tabletFontSize: 16,
                desktopFontSize: 18,
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final items = [..._verifications]..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    final filteredByStatus = _selectedStatus == 'all' ? items : items.where((v) => v.status == _selectedStatus).toList();
    final filtered = _applySearch(filteredByStatus);

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          _subscription?.cancel();
          _subscriptionAlt?.cancel();
          _subscribeToVerifications();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: ResponsiveHelper.getResponsivePadding(context),
          children: [
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, mobile: 20, tablet: 25, desktop: 30)),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payment,
                    size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 64, tablet: 72, desktop: 80),
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                  ResponsiveText(
                    _selectedStatus == 'all' ? 'No payment verifications yet' : 'No ${_selectedStatus} verifications',
                    mobileFontSize: 18,
                    tabletFontSize: 20,
                    desktopFontSize: 22,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                  const ResponsiveText(
                    'Pull to refresh. Payment verifications will appear here when users submit them.',
                    mobileFontSize: 14,
                    tabletFontSize: 16,
                    desktopFontSize: 18,
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _subscription?.cancel();
              _subscribeToVerifications();
            },
            child: ResponsiveHelper.isMobile(context)
                ? ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: ResponsiveHelper.getResponsivePadding(context),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20),
                        ),
                        child: _buildVerificationCard(filtered[index]),
                      );
                    },
                  )
                : GridView.builder(
                    padding: ResponsiveHelper.getResponsivePadding(context),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: ResponsiveHelper.getResponsiveGridColumns(context),
                      childAspectRatio: ResponsiveHelper.isTablet(context) ? 1.2 : 1.0,
                      crossAxisSpacing: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20),
                      mainAxisSpacing: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20),
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildVerificationCard(filtered[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(List<PaymentVerificationModel> verifications) {
    final pendingCount = verifications.where((v) => v.isPending).length;
    final verifiedCount = verifications.where((v) => v.isVerified).length;
    final rejectedCount = verifications.where((v) => v.isRejected).length;

    return Container(
      margin: ResponsiveHelper.getResponsivePadding(context),
      padding: ResponsiveHelper.getResponsiveCardPadding(context),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ResponsiveHelper.isMobile(context) 
        ? Column(
            children: [
              Row(
                children: [
                  _buildStatItem('Pending', pendingCount, Colors.orange),
                  _buildStatItem('Verified', verifiedCount, Colors.green),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatItem('Rejected', rejectedCount, Colors.red),
            ],
          )
        : Row(
            children: [
              _buildStatItem('Pending', pendingCount, Colors.orange),
              _buildStatItem('Verified', verifiedCount, Colors.green),
              _buildStatItem('Rejected', rejectedCount, Colors.red),
            ],
          ),
    );
  }

  // Filter chips for quick status filtering
  Widget _buildFilterChips() {
    final counts = {
      'all': _verifications.length,
      'pending': _verifications.where((v) => v.isPending).length,
      'verified': _verifications.where((v) => v.isVerified).length,
      'rejected': _verifications.where((v) => v.isRejected).length,
    };

    Widget buildChip(String value, String label, Color color) {
      final bool selected = _selectedStatus == value;
      return Padding(
        padding: EdgeInsets.only(
          right: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 10, desktop: 12),
        ),
        child: ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withOpacity(0.15) : color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  counts[value].toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          selected: selected,
          selectedColor: color,
          backgroundColor: color.withOpacity(0.12),
          labelStyle: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(color: color.withOpacity(0.5)),
          onSelected: (_) => _onStatusFilterChanged(value),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24),
        vertical: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 10, desktop: 12),
      ),
      child: Row(
        children: [
          buildChip('all', 'All', Colors.blueGrey),
          buildChip('pending', 'Pending', Colors.orange),
          buildChip('verified', 'Verified', Colors.green),
          buildChip('rejected', 'Rejected', Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        ResponsiveText(
          count.toString(),
          mobileFontSize: 24,
          tabletFontSize: 28,
          desktopFontSize: 32,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 4, tablet: 6, desktop: 8)),
        ResponsiveText(
          label,
          mobileFontSize: 12,
          tabletFontSize: 14,
          desktopFontSize: 16,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationCard(PaymentVerificationModel verification) {
    return Card(
      margin: EdgeInsets.only(
        bottom: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24),
      ),
      child: Padding(
        padding: ResponsiveHelper.getResponsiveCardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: ResponsiveHelper.getResponsiveIconSize(context, mobile: 20, tablet: 24, desktop: 28) / 2,
                  backgroundColor: _getStatusColor(verification.status).withOpacity(0.1),
                  child: Icon(
                    _getStatusIcon(verification.status),
                    color: _getStatusColor(verification.status),
                    size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 16, tablet: 20, desktop: 24),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText(
                        verification.userName,
                        mobileFontSize: 16,
                        tabletFontSize: 18,
                        desktopFontSize: 20,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleSmall?.color,
                        ),
                      ),
                      ResponsiveText(
                        verification.userEmail,
                        mobileFontSize: 14,
                        tabletFontSize: 16,
                        desktopFontSize: 18,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(verification.status),
              ],
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
            ResponsiveHelper.isMobile(context) 
              ? Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.payment, 
                          size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 16, tablet: 18, desktop: 20), 
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 4, tablet: 6, desktop: 8)),
                        ResponsiveText(
                          verification.formattedAmount,
                          mobileFontSize: 16,
                          tabletFontSize: 18,
                          desktopFontSize: 20,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time, 
                          size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 16, tablet: 18, desktop: 20), 
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 4, tablet: 6, desktop: 8)),
                        ResponsiveText(
                          verification.formattedSubmittedAt,
                          mobileFontSize: 12,
                          tabletFontSize: 14,
                          desktopFontSize: 16,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Icon(
                      Icons.payment, 
                      size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 16, tablet: 18, desktop: 20), 
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 4, tablet: 6, desktop: 8)),
                    ResponsiveText(
                      verification.formattedAmount,
                      mobileFontSize: 16,
                      tabletFontSize: 18,
                      desktopFontSize: 20,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.access_time, 
                      size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 16, tablet: 18, desktop: 20), 
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 4, tablet: 6, desktop: 8)),
                    ResponsiveText(
                      verification.formattedSubmittedAt,
                      mobileFontSize: 12,
                      tabletFontSize: 14,
                      desktopFontSize: 16,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
            if (verification.transactionId.isNotEmpty) ...[
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
              Row(
                children: [
                  Icon(
                    Icons.receipt, 
                    size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 16, tablet: 18, desktop: 20), 
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 4, tablet: 6, desktop: 8)),
                  Expanded(
                    child: ResponsiveText(
                      'Transaction ID: ${verification.transactionId}',
                      mobileFontSize: 12,
                      tabletFontSize: 14,
                      desktopFontSize: 16,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
            _buildScreenshotPreview(verification),
            if (verification.isPending) ...[
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
              ResponsiveHelper.isMobile(context)
                ? Column(
                    children: [
                      ResponsiveButton(
                        text: 'Reject',
                        onPressed: () => _rejectVerification(verification),
                        type: ButtonType.outline,
                        icon: Icons.close,
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                      ResponsiveButton(
                        text: 'Verify',
                        onPressed: () => _verifyPayment(verification),
                        type: ButtonType.primary,
                        icon: Icons.check,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: ResponsiveButton(
                          text: 'Reject',
                          onPressed: () => _rejectVerification(verification),
                          type: ButtonType.outline,
                          icon: Icons.close,
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                      Expanded(
                        child: ResponsiveButton(
                          text: 'Verify',
                          onPressed: () => _verifyPayment(verification),
                          type: ButtonType.primary,
                          icon: Icons.check,
                        ),
                      ),
                    ],
                  ),
            ],
            if (verification.isRejected && verification.rejectionReason != null) ...[
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
              Container(
                padding: ResponsiveHelper.getResponsivePadding(context, mobile: 8, tablet: 12, desktop: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                  border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline, 
                      color: Theme.of(context).colorScheme.error, 
                      size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 16, tablet: 18, desktop: 20)
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                    Expanded(
                      child: ResponsiveText(
                        'Reason: ${verification.rejectionReason}',
                        mobileFontSize: 12,
                        tabletFontSize: 14,
                        desktopFontSize: 16,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
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

  Widget _buildScreenshotPreview(PaymentVerificationModel verification) {
    final hasUrl = verification.screenshotUrl.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Payment Screenshot',
          mobileFontSize: 14,
          tabletFontSize: 16,
          desktopFontSize: 18,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
        GestureDetector(
          onTap: hasUrl ? () => _showScreenshotDialog(verification.screenshotUrl) : null,
          child: Container(
            height: ResponsiveHelper.getResponsiveHeight(context, mobile: 20, tablet: 25, desktop: 30),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
              child: hasUrl
                  ? CachedNetworkImage(
                      imageUrl: verification.screenshotUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: ResponsiveHelper.isMobile(context) ? 2 : 3,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => _screenshotFallback(),
                    )
                  : _screenshotFallback(),
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 4, tablet: 6, desktop: 8)),
        if (hasUrl)
          ResponsiveText(
            'Tap to view full size',
            mobileFontSize: 12,
            tabletFontSize: 14,
            desktopFontSize: 16,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
      ],
    );
  }

  Widget _screenshotFallback() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey[600],
              size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 24, tablet: 28, desktop: 32),
            ),
            const SizedBox(height: 8),
            const Text(
              'Screenshot not available',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        break;
      case 'verified':
        color = Colors.green;
        text = 'Verified';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Rejected';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16),
        vertical: ResponsiveHelper.getResponsiveSpacing(context, mobile: 4, tablet: 6, desktop: 8),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
        border: Border.all(color: color),
      ),
      child: ResponsiveText(
        text,
        mobileFontSize: 12,
        tabletFontSize: 14,
        desktopFontSize: 16,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
        ),
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

  String _getStatusFilterText() {
    switch (_selectedStatus) {
      case 'pending':
        return 'Pending';
      case 'verified':
        return 'Verified';
      case 'rejected':
        return 'Rejected';
      default:
        return 'All';
    }
  }

  List<PaymentVerificationModel> _getFilteredVerifications() {
    if (_selectedStatus == 'all') {
      return _verifications;
    }
    return _verifications.where((v) => v.status == _selectedStatus).toList();
  }

  void _onStatusFilterChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
  }

  List<PaymentVerificationModel> _applySearch(List<PaymentVerificationModel> list) {
    if (_searchQuery.isEmpty) return list;
    return list.where((v) {
      final haystack = '${v.userName}\n${v.userEmail}\n${v.transactionId}'.toLowerCase();
      return haystack.contains(_searchQuery);
    }).toList();
  }

  // Removed one-shot loader in favor of realtime subscription

  Future<void> _verifyPayment(PaymentVerificationModel verification) async {
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment verified and ticket issued to ${verification.userName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectVerification(PaymentVerificationModel verification) async {
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

  void _showScreenshotDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Payment Screenshot'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(Icons.error, color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
