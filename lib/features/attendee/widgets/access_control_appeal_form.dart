import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/models/event_model.dart';
import '../../../core/models/access_control_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/constants.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../app/theme/app_theme.dart';
import 'package:provider/provider.dart';

class AccessControlAppealForm extends StatefulWidget {
  final EventModel event;
  final AccessControlModel accessControl;

  const AccessControlAppealForm({
    super.key,
    required this.event,
    required this.accessControl,
  });

  @override
  State<AccessControlAppealForm> createState() => _AccessControlAppealFormState();
}

class _AccessControlAppealFormState extends State<AccessControlAppealForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  final _invitationCodeController = TextEditingController();
  
  File? _documentImage;
  bool _isSubmitting = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _reasonController.dispose();
    _additionalInfoController.dispose();
    _invitationCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: AppTheme.warningColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Request Access',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Event Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This event requires special access. Please provide the required information to request approval.',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Form
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Access Control Type Info
                      _buildAccessControlInfo(),
                      
                      const SizedBox(height: 20),
                      
                      // Reason for Request
                      _buildReasonField(),
                      
                      const SizedBox(height: 16),
                      
                      // Invitation Code (if required)
                      if (widget.accessControl.type == AccessControlType.invitationOnly)
                        _buildInvitationCodeField(),
                      
                      const SizedBox(height: 16),
                      
                      // Document Upload (if required)
                      if (_requiresDocumentUpload())
                        _buildDocumentUploadField(),
                      
                      const SizedBox(height: 16),
                      
                      // Additional Information
                      _buildAdditionalInfoField(),
                      
                      const SizedBox(height: 20),
                      
                      // Error Message
                      if (_errorMessage != null)
                        _buildErrorMessage(),
                      
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitAppeal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.warningColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Submit Request'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessControlInfo() {
    String title = '';
    String description = '';
    IconData icon = Icons.security;
    Color color = Colors.orange;

    switch (widget.accessControl.type) {
      case AccessControlType.emailDomainRestricted:
        title = 'Email Domain Restricted';
        description = 'This event is restricted to specific email domains.';
        icon = Icons.email;
        color = Colors.blue;
        break;
      case AccessControlType.userGroupRestricted:
        title = 'User Group Restricted';
        description = 'This event is restricted to specific user groups.';
        icon = Icons.group;
        color = Colors.green;
        break;
      case AccessControlType.invitationOnly:
        title = 'Invitation Only';
        description = 'This event requires an invitation code.';
        icon = Icons.vpn_key;
        color = Colors.purple;
        break;
      case AccessControlType.ageRestricted:
        title = 'Age Restricted';
        description = 'This event has age restrictions.';
        icon = Icons.person_outline;
        color = Colors.red;
        break;
      case AccessControlType.locationBased:
        title = 'Location Based';
        description = 'This event is restricted to specific locations.';
        icon = Icons.location_on;
        color = Colors.teal;
        break;
      case AccessControlType.customCriteria:
        title = 'Custom Criteria';
        description = 'This event has custom access requirements.';
        icon = Icons.settings;
        color = Colors.indigo;
        break;
      default:
        title = 'Access Restricted';
        description = 'This event requires special access.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reason for Request *',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _reasonController,
          maxLines: 3,
          style: const TextStyle(color: Colors.black),
          cursorColor: Colors.black,
          decoration: InputDecoration(
            hintText: 'Please explain why you want to attend this event...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide a reason for your request';
            }
            if (value.trim().length < 10) {
              return 'Please provide a more detailed reason (at least 10 characters)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildInvitationCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invitation Code *',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _invitationCodeController,
          style: const TextStyle(color: Colors.black),
          cursorColor: Colors.black,
          decoration: InputDecoration(
            hintText: 'Enter your invitation code',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.vpn_key),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter the invitation code';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDocumentUploadField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Required Document *',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: Column(
            children: [
              if (_documentImage == null) ...[
                Icon(
                  Icons.upload_file,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'Upload required document (ID card, certificate, etc.)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _pickDocumentImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.secondaryColor,
                  ),
                ),
              ] else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _documentImage!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickDocumentImage,
                      icon: const Icon(Icons.edit),
                      label: const Text('Change'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _documentImage = null),
                      icon: const Icon(Icons.delete),
                      label: const Text('Remove'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (_requiresDocumentUpload() && _documentImage == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Document upload is required for this event',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAdditionalInfoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Information',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _additionalInfoController,
          maxLines: 3,
          style: const TextStyle(color: Colors.black),
          cursorColor: Colors.black,
          decoration: InputDecoration(
            hintText: 'Any additional information that might help with your request...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
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

  bool _requiresDocumentUpload() {
    return widget.accessControl.type == AccessControlType.customCriteria ||
           widget.accessControl.type == AccessControlType.userGroupRestricted;
  }

  Future<void> _pickDocumentImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _documentImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<String?> _uploadDocumentImage(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child('appeal_documents/${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = imageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload document image: $e');
    }
  }

  Future<void> _submitAppeal() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate document upload if required
    if (_requiresDocumentUpload() && _documentImage == null) {
      setState(() {
        _errorMessage = 'Please upload the required document';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final user = authService.userModel;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Debug information
      debugPrint('=== APPEAL SUBMISSION DEBUG ===');
      debugPrint('Event ID: ${widget.event.id}');
      debugPrint('User ID: ${user.id}');
      debugPrint('User Email: ${user.email}');
      debugPrint('Is User Authenticated: ${authService.isAuthenticated}');
      debugPrint('Access Control ID: ${widget.accessControl.id}');
      debugPrint('Access Control Type: ${widget.accessControl.type}');
      debugPrint('Using Access Control ID: ${widget.accessControl.id ?? widget.event.id}');
      debugPrint('Reason: ${_reasonController.text.trim()}');
      debugPrint('================================');

      // Upload document image if provided
      String? documentImageUrl;
      if (_documentImage != null) {
        documentImageUrl = await _uploadDocumentImage(_documentImage!);
      }

      // Create appeal data
      // Use event ID as access control ID if access control doesn't have its own ID
      final accessControlId = widget.accessControl.id ?? widget.event.id;
      
      final appealData = {
        'eventId': widget.event.id,
        'eventTitle': widget.event.title,
        'userId': user.id,
        'userName': user.name,
        'userEmail': user.email,
        'accessControlId': accessControlId,
        'accessControlType': widget.accessControl.type.name,
        'reason': _reasonController.text.trim(),
        'additionalInfo': _additionalInfoController.text.trim(),
        'invitationCode': widget.accessControl.type == AccessControlType.invitationOnly 
            ? _invitationCodeController.text.trim() 
            : null,
        'documentImageUrl': documentImageUrl,
      };

      // Submit appeal to Firestore
      await FirestoreService().submitAccessAppeal(appealData);

      // Success
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
