import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../core/models/event_model.dart';
import '../../../core/services/payment_verification_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../app/theme/app_theme.dart';
import 'package:provider/provider.dart';

class PaymentVerificationScreen extends StatefulWidget {
  final EventModel event;
  final double amount;
  final String userEmail;
  final String userName;

  const PaymentVerificationScreen({
    super.key,
    required this.event,
    required this.amount,
    required this.userEmail,
    required this.userName,
  });

  @override
  State<PaymentVerificationScreen> createState() => _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState extends State<PaymentVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _transactionIdController = TextEditingController();
  
  File? _screenshotFile;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isCheckingExisting = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userName;
    _emailController.text = widget.userEmail;
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkExistingVerification());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingVerification() async {
    try {
      final authService = context.read<AuthService>();
      final user = authService.userModel;
      if (user == null || widget.event.id == null) {
        setState(() => _isCheckingExisting = false);
        return;
      }

      final hasExisting = await PaymentVerificationService
          .hasUserSubmittedVerification(widget.event.id!, user.id!);

      if (!mounted) return;
      if (hasExisting) {
        try {
          context.goNamed(
            'payment_verification_status',
            queryParameters: {
              'eventId': widget.event.id!,
              'title': widget.event.title,
            },
          );
        } catch (_) {
          // Fallback if router name not available
          context.pushNamed(
            'payment_verification_status',
            queryParameters: {
              'eventId': widget.event.id!,
              'title': widget.event.title,
            },
          );
        }
      } else {
        setState(() => _isCheckingExisting = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingExisting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingExisting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Verification'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventInfo(),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 24, tablet: 28, desktop: 32)),
              _buildPaymentInfo(),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 24, tablet: 28, desktop: 32)),
              _buildFormFields(),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 24, tablet: 28, desktop: 32)),
              _buildScreenshotSection(),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 24, tablet: 28, desktop: 32)),
              _buildInstructions(),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 24, tablet: 28, desktop: 32)),
              _buildErrorAndSuccessMessages(),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 24, tablet: 28, desktop: 32)),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventInfo() {
    return Container(
      padding: ResponsiveHelper.getResponsiveCardPadding(context),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            widget.event.title,
            mobileFontSize: 18,
            tabletFontSize: 20,
            desktopFontSize: 22,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
          Row(
            children: [
              Icon(
                Icons.location_on, 
                size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 16, tablet: 18, desktop: 20), 
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 4, tablet: 6, desktop: 8)),
              Expanded(
                child: ResponsiveText(
                  widget.event.location,
                  mobileFontSize: 14,
                  tabletFontSize: 16,
                  desktopFontSize: 18,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 4, tablet: 6, desktop: 8)),
          Row(
            children: [
              Icon(
                Icons.event, 
                size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 16, tablet: 18, desktop: 20), 
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 4, tablet: 6, desktop: 8)),
              ResponsiveText(
                '${widget.event.formattedDate} at ${widget.event.formattedTime}',
                mobileFontSize: 14,
                tabletFontSize: 16,
                desktopFontSize: 18,
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      padding: ResponsiveHelper.getResponsiveCardPadding(context),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment,
                color: AppTheme.primaryColor,
                size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 24, tablet: 28, desktop: 32),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      'Amount to Pay',
                      mobileFontSize: 14,
                      tabletFontSize: 16,
                      desktopFontSize: 18,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    ResponsiveText(
                      '₹${widget.amount.toStringAsFixed(2)}',
                      mobileFontSize: 20,
                      tabletFontSize: 24,
                      desktopFontSize: 28,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
          if (widget.event.paymentQrUrl != null && widget.event.paymentQrUrl!.isNotEmpty) ...[
            ResponsiveText(
              'Scan and Pay to Organizer',
              mobileFontSize: 14,
              tabletFontSize: 16,
              desktopFontSize: 18,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
            ClipRRect(
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
              child: Image.network(
                widget.event.paymentQrUrl!,
                height: ResponsiveHelper.getResponsiveHeight(context, mobile: 22, tablet: 25, desktop: 28),
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
            ResponsiveText(
              'After paying, upload the payment screenshot below. Your ticket will be issued once the organizer verifies the payment.',
              mobileFontSize: 12,
              tabletFontSize: 14,
              desktopFontSize: 16,
            ),
          ] else ...[
            ResponsiveText(
              'Organizer has not added a QR code. Contact organizer for payment details.',
              mobileFontSize: 12,
              tabletFontSize: 14,
              desktopFontSize: 16,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Payment Details',
          mobileFontSize: 18,
          tabletFontSize: 20,
          desktopFontSize: 22,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
        TextFormField(
          controller: _nameController,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
            color: Colors.black,
          ),
          cursorColor: Colors.black,
          decoration: InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            prefixIcon: Icon(
              Icons.person,
              size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 20, tablet: 22, desktop: 24),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
            ),
            contentPadding: ResponsiveHelper.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your full name';
            }
            return null;
          },
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
        TextFormField(
          controller: _emailController,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
            color: Colors.black,
          ),
          cursorColor: Colors.black,
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter your email address',
            prefixIcon: Icon(
              Icons.email,
              size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 20, tablet: 22, desktop: 24),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
            ),
            contentPadding: ResponsiveHelper.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email address';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
        TextFormField(
          controller: _transactionIdController,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
            color: Colors.black,
          ),
          cursorColor: Colors.black,
          decoration: InputDecoration(
            labelText: 'Transaction ID (Optional)',
            hintText: 'Enter transaction ID from payment app',
            prefixIcon: Icon(
              Icons.receipt,
              size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 20, tablet: 22, desktop: 24),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
            ),
            contentPadding: ResponsiveHelper.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildScreenshotSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Payment Screenshot',
          mobileFontSize: 18,
          tabletFontSize: 20,
          desktopFontSize: 22,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
        Container(
          width: double.infinity,
          height: ResponsiveHelper.getResponsiveHeight(context, mobile: 20, tablet: 25, desktop: 30),
          decoration: BoxDecoration(
            border: Border.all(
              color: _screenshotFile != null ? AppTheme.successColor : Theme.of(context).dividerColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
          ),
          child: _screenshotFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveSpacing(context, mobile: 6, tablet: 10, desktop: 14)),
                  child: Image.file(
                    _screenshotFile!,
                    fit: BoxFit.cover,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 48, tablet: 56, desktop: 64),
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                    ResponsiveText(
                      'No screenshot selected',
                      mobileFontSize: 16,
                      tabletFontSize: 18,
                      desktopFontSize: 20,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 4, tablet: 6, desktop: 8)),
                    ResponsiveText(
                      'Tap to select payment screenshot',
                      mobileFontSize: 12,
                      tabletFontSize: 14,
                      desktopFontSize: 16,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
        ResponsiveHelper.isMobile(context)
          ? Column(
              children: [
                ResponsiveButton(
                  text: 'Take Photo',
                  onPressed: _pickScreenshot,
                  type: ButtonType.outline,
                  icon: Icons.camera_alt,
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                ResponsiveButton(
                  text: 'From Gallery',
                  onPressed: _pickScreenshotFromGallery,
                  type: ButtonType.outline,
                  icon: Icons.photo_library,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: ResponsiveButton(
                    text: 'Take Photo',
                    onPressed: _pickScreenshot,
                    type: ButtonType.outline,
                    icon: Icons.camera_alt,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                Expanded(
                  child: ResponsiveButton(
                    text: 'From Gallery',
                    onPressed: _pickScreenshotFromGallery,
                    type: ButtonType.outline,
                    icon: Icons.photo_library,
                  ),
                ),
              ],
            ),
        if (_screenshotFile != null) ...[
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
          ResponsiveButton(
            text: 'Remove Screenshot',
            onPressed: _removeScreenshot,
            type: ButtonType.danger,
            icon: Icons.delete,
          ),
        ],
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: ResponsiveHelper.getResponsiveCardPadding(context),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline, 
                color: AppTheme.warningColor, 
                size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 20, tablet: 22, desktop: 24)
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
              ResponsiveText(
                'Important Instructions',
                mobileFontSize: 16,
                tabletFontSize: 18,
                desktopFontSize: 20,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
          ResponsiveText(
            '• First, scan the QR above and pay the amount\n'
            '• Then upload a clear screenshot showing amount and status\n'
            '• Organizer manually verifies payments before issuing tickets\n'
            '• You will receive your ticket only after verification\n'
            '• This may take from minutes to a few hours',
            mobileFontSize: 14,
            tabletFontSize: 16,
            desktopFontSize: 18,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorAndSuccessMessages() {
    if (_errorMessage != null) {
      return Container(
        padding: ResponsiveHelper.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
          border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline, 
              color: Theme.of(context).colorScheme.error, 
              size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 20, tablet: 22, desktop: 24)
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
            Expanded(
              child: ResponsiveText(
                _errorMessage!,
                mobileFontSize: 14,
                tabletFontSize: 16,
                desktopFontSize: 18,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      );
    }

    if (_successMessage != null) {
      return Container(
        padding: ResponsiveHelper.getResponsivePadding(context, mobile: 12, tablet: 16, desktop: 20),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
          border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle, 
              color: AppTheme.successColor, 
              size: ResponsiveHelper.getResponsiveIconSize(context, mobile: 20, tablet: 22, desktop: 24)
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
            Expanded(
              child: ResponsiveText(
                _successMessage!,
                mobileFontSize: 14,
                tabletFontSize: 16,
                desktopFontSize: 18,
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSubmitButton() {
    return ResponsiveButton(
      text: _isSubmitting ? 'Submitting...' : 'Submit Payment Verification',
      onPressed: _isSubmitting ? null : _submitVerification,
      type: ButtonType.primary,
      isLoading: _isSubmitting,
      isFullWidth: true,
    );
  }

  Future<void> _pickScreenshot() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _screenshotFile = File(image.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to take photo: $e';
      });
    }
  }

  Future<void> _pickScreenshotFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _screenshotFile = File(image.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  void _removeScreenshot() {
    setState(() {
      _screenshotFile = null;
    });
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_screenshotFile == null) {
      setState(() {
        _errorMessage = 'Please select a payment screenshot';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final user = authService.userModel;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user has already submitted a verification for this event
      final hasExistingVerification = await PaymentVerificationService
          .hasUserSubmittedVerification(widget.event.id!, user.id!);
      
      if (hasExistingVerification) {
        // Navigate to status screen instead of throwing
        if (mounted) {
          // Use GoRouter for named navigation
          try {
            // ignore: use_build_context_synchronously
            context.pushNamed(
              'payment_verification_status',
              queryParameters: {
                'eventId': widget.event.id!,
                'title': widget.event.title,
              },
            );
          } catch (_) {
            // Fallback if go_router context isn't available
            Navigator.of(context).pop();
          }
        }
        return;
      }

      // Submit payment verification
      await PaymentVerificationService.submitPaymentVerification(
        eventId: widget.event.id!,
        eventTitle: widget.event.title,
        userId: user.id!,
        userName: _nameController.text.trim(),
        userEmail: _emailController.text.trim(),
        amount: widget.amount,
        screenshotFile: _screenshotFile!,
        transactionId: _transactionIdController.text.trim().isNotEmpty 
            ? _transactionIdController.text.trim() 
            : 'N/A',
        notes: {
          'eventDate': widget.event.date.toIso8601String(),
          'eventLocation': widget.event.location,
        },
      );

      setState(() {
        _successMessage = 'Payment verification submitted successfully! The organizer will review your payment and issue your ticket soon.';
      });

      // Navigate back after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
