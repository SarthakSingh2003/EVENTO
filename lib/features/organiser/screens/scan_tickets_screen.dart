import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/models/event_model.dart';
import '../../../core/models/ticket_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/loading_indicator.dart';
import 'package:go_router/go_router.dart';

class ScanTicketsScreen extends StatefulWidget {
  final String eventId;
  
  const ScanTicketsScreen({super.key, required this.eventId});

  @override
  State<ScanTicketsScreen> createState() => _ScanTicketsScreenState();
}

class _ScanTicketsScreenState extends State<ScanTicketsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  EventModel? _event;
  bool _isLoading = true;
  bool _isScanning = false;
  List<TicketModel> _scannedTickets = [];
  List<TicketModel> _allTickets = [];
  
  void _goBackToTickets() {
    context.go('/ticket-management/${widget.eventId}');
  }
  
  @override
  void initState() {
    super.initState();
    _loadEventAndTickets();
  }

  Future<void> _loadEventAndTickets() async {
    try {
      final event = await _firestoreService.getEvent(widget.eventId);
      final tickets = await _firestoreService.getEventTickets(widget.eventId).first;
      
      if (mounted) {
        setState(() {
          _event = event;
          _allTickets = tickets;
          _scannedTickets = tickets.where((ticket) => ticket.isUsed).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading event and tickets: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isScanning) return;
    
    setState(() => _isScanning = true);
    
    try {
      final qrCode = capture.barcodes.first.rawValue;
      if (qrCode != null) {
        await _processTicket(qrCode);
      }
    } catch (e) {
      _showError('Error processing QR code: $e');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _processTicket(String qrCode) async {
    try {
      final ticket = await _firestoreService.getTicketByQRCode(qrCode);
      
      if (ticket == null) {
        _showError('Invalid ticket QR code');
        return;
      }
      
      if (ticket.eventId != widget.eventId) {
        _showError('This ticket is not valid for this event');
        return;
      }
      
      if (ticket.isUsed) {
        final usedAtText = _formatDateTime(ticket.usedAt);
        _showError('Already used by ${ticket.userName} at $usedAtText');
        return;
      }
      
      // Mark ticket as used
      await _firestoreService.updateTicket(ticket.id!, {
        'isUsed': true,
        'usedAt': DateTime.now().toIso8601String(),
      });
      
      // Refresh tickets list
      await _loadEventAndTickets();
      
      final timeText = _formatDateTime(DateTime.now());
      _showSuccess('Entry granted to ${ticket.userName} at $timeText');
      
    } catch (e) {
      _showError('Error processing ticket: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan Tickets'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.secondaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBackToTickets,
          ),
        ),
        body: const Center(child: LoadingIndicator()),
      );
    }
    
    if (_event == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan Tickets'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.secondaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBackToTickets,
          ),
        ),
        body: const Center(
          child: Text('Event not found'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Tickets'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.secondaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackToTickets,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => _showTicketList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Event Info Header
          _buildEventHeader(),
          
          // Scanner
          Expanded(
            child: _buildScanner(),
          ),
          
          // Scan Instructions
          _buildScanInstructions(),
        ],
      ),
    );
  }

  Widget _buildEventHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _event!.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _event!.formattedDate,
                  style: TextStyle(color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _event!.location,
                  style: TextStyle(color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatChip('Total', _allTickets.length.toString()),
                const SizedBox(width: 8),
                _buildStatChip('Scanned', _scannedTickets.length.toString()),
                const SizedBox(width: 8),
                _buildStatChip('Remaining', (_allTickets.length - _scannedTickets.length).toString()),
              ],
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
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildScanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            MobileScanner(
              onDetect: _onDetect,
              fit: BoxFit.cover,
            ),
            if (_isScanning)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Processing ticket...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            // Scanner overlay
            Positioned.fill(
              child: CustomPaint(
                painter: ScannerOverlayPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Scan Ticket QR Code',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Position the QR code within the scanner frame',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showTicketList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildTicketListSheet(),
    );
  }

  Widget _buildTicketListSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ticket List',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Filter tabs
          Row(
            children: [
              Expanded(
                child: _buildFilterTab('All', _allTickets.length, true),
              ),
              Expanded(
                child: _buildFilterTab('Scanned', _scannedTickets.length, false),
              ),
              Expanded(
                child: _buildFilterTab('Remaining', _allTickets.length - _scannedTickets.length, false),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Ticket list
          Expanded(
            child: _allTickets.isEmpty
                ? const Center(
                    child: Text('No tickets found for this event'),
                  )
                : ListView.builder(
                    itemCount: _allTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = _allTickets[index];
                      return _buildTicketItem(ticket);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, int count, bool isSelected) {
    return GestureDetector(
      onTap: () {
        // TODO: Implement filtering
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.secondaryColor : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              count.toString(),
              style: TextStyle(
                color: isSelected ? AppTheme.secondaryColor : AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketItem(TicketModel ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ticket.isUsed ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            ticket.isUsed ? Icons.check_circle : Icons.pending,
            color: ticket.isUsed ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(ticket.userName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('QR: ${ticket.qrCode.substring(0, 8)}...'),
            Text(
              ticket.isUsed ? 'Used at ${_formatDateTime(ticket.usedAt)}' : 'Not used yet',
              style: TextStyle(
                color: ticket.isUsed ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Text(
          ticket.isFree ? 'Free' : '₹${ticket.price.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: ticket.isFree ? Colors.green : AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Draw outer rectangle
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Clear inner rectangle for scanner
    final scannerSize = size.width * 0.7;
    final scannerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scannerSize,
      height: scannerSize,
    );

    final clearPaint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.fill;

    canvas.drawRect(scannerRect, clearPaint);

    // Draw corner indicators
    final cornerPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cornerLength = scannerSize * 0.1;

    // Top-left corner
    canvas.drawLine(
      Offset(scannerRect.left, scannerRect.top + cornerLength),
      Offset(scannerRect.left, scannerRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scannerRect.left, scannerRect.top),
      Offset(scannerRect.left + cornerLength, scannerRect.top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(scannerRect.right - cornerLength, scannerRect.top),
      Offset(scannerRect.right, scannerRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scannerRect.right, scannerRect.top),
      Offset(scannerRect.right, scannerRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(scannerRect.left, scannerRect.bottom - cornerLength),
      Offset(scannerRect.left, scannerRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scannerRect.left, scannerRect.bottom),
      Offset(scannerRect.left + cornerLength, scannerRect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(scannerRect.right - cornerLength, scannerRect.bottom),
      Offset(scannerRect.right, scannerRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scannerRect.right, scannerRect.bottom - cornerLength),
      Offset(scannerRect.right, scannerRect.bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
