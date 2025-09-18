import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
// import 'package:uuid/uuid.dart';  // Temporarily disabled
import '../models/user_model.dart';
import 'constants.dart';

class Helpers {
  // static final Uuid _uuid = Uuid();  // Temporarily disabled

  // Validation Helpers
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= AppConstants.minPasswordLength;
  }

  static bool isValidEventTitle(String title) {
    return title.trim().isNotEmpty && 
           title.length <= AppConstants.maxTitleLength;
  }

  static bool isValidEventDescription(String description) {
    return description.trim().isNotEmpty && 
           description.length <= AppConstants.maxDescriptionLength;
  }

  static bool isValidEventLocation(String location) {
    return location.trim().isNotEmpty && 
           location.length <= AppConstants.maxLocationLength;
  }

  static bool isValidTicketPrice(double price) {
    return price >= 0 && price <= AppConstants.maxTicketPrice;
  }

  static bool isValidTicketCount(int count) {
    return count > 0 && count <= AppConstants.maxTicketsPerEvent;
  }

  static bool isValidEventDate(DateTime date) {
    final now = DateTime.now();
    final maxDate = now.add(Duration(days: AppConstants.maxEventDaysInFuture));
    return date.isAfter(now) && date.isBefore(maxDate);
  }

  // Formatting Helpers
  static String formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    ).format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat(AppConstants.timeFormat).format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat(AppConstants.dateTimeFormat).format(dateTime);
  }

  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  static String formatEventDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // QR Code Helpers
  static String generateQRCode() {
    // Temporarily disabled uuid usage
    // return '${AppConstants.qrCodePrefix}_${_uuid.v4().substring(0, AppConstants.qrCodeLength)}';
    
    // Mock implementation using random numbers
    final random = math.Random();
    final randomPart = List.generate(AppConstants.qrCodeLength, (_) => random.nextInt(10)).join();
    return '${AppConstants.qrCodePrefix}_$randomPart';
  }

  static bool isValidQRCode(String qrCode) {
    return qrCode.startsWith(AppConstants.qrCodePrefix) && 
           qrCode.length == AppConstants.qrCodePrefix.length + AppConstants.qrCodeLength;
  }

  // Image Helpers
  static bool isValidImageFormat(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return AppConstants.allowedImageFormats.contains(extension);
  }

  static bool isValidImageSize(int sizeInBytes) {
    return sizeInBytes <= AppConstants.maxImageSize;
  }

  // Location Helpers
  static double calculateDistance(
    double lat1, 
    double lon1, 
    double lat2, 
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        (math.sin(lat1) * math.sin(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2));
    final double c = 2 * math.atan(math.sqrt(a) / math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  // UI Helpers
  static void showSnackBar(BuildContext context, String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showCustomDialog(
    BuildContext context, {
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onCancel?.call();
              },
              child: Text(cancelText),
            ),
          if (confirmText != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm?.call();
              },
              child: Text(confirmText),
            ),
        ],
      ),
    );
  }

  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  // Role Helpers
  static String getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.organiser:
        return 'Event Organiser';
      case UserRole.moderator:
        return 'Event Moderator';
      case UserRole.attendee:
        return 'Event Attendee';
    }
  }

  static IconData getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.organiser:
        return Icons.event;
      case UserRole.moderator:
        return Icons.qr_code_scanner;
      case UserRole.attendee:
        return Icons.person;
    }
  }

  static Color getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.organiser:
        return Colors.blue;
      case UserRole.moderator:
        return Colors.orange;
      case UserRole.attendee:
        return Colors.green;
    }
  }

  // String Helpers
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String removeSpecialCharacters(String text) {
    return text.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
  }

  // Number Helpers
  static String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  // Date Helpers
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
           date.month == tomorrow.month &&
           date.day == tomorrow.day;
  }

  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  // Color Helpers
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'valid':
        return Colors.green;
      case 'inactive':
      case 'used':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// Currency Input Formatter
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // If empty, return empty
    if (newText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    
    // Convert to double and format
    double value = double.parse(newText) / 100; // Convert paise to rupees
    String formatted = NumberFormat('#,##0.00', 'en_IN').format(value);
    
    // Calculate cursor position
    int cursorPosition = formatted.length;
    if (newValue.selection.baseOffset < newValue.text.length) {
      cursorPosition = newValue.selection.baseOffset;
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
} 