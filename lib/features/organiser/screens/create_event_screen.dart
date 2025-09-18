import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../core/models/event_model.dart';
import '../../../core/models/access_control_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/utils/helpers.dart';
import '../widgets/access_control_form.dart';
import 'package:go_router/go_router.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _venueDetailsController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _websiteController = TextEditingController();
  final AuthService _authService = AuthService();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  double _latitude = 0.0;
  double _longitude = 0.0;
  
  String _selectedCategory = 'Technology';
  List<String> _selectedTags = [];
  String _eventType = 'Offline';
  bool _isFree = false;
  double _price = 0.0;
  int _totalTickets = 100;
  int _maxAttendees = 100;
  
  File? _bannerImage;
  File? _paymentQrImage;
  bool _isLoading = false;
  bool _isImageLoading = false;
  
  // Access Control Variables
  bool _requiresAccessControl = false;
  AccessControlModel? _accessControl;
  bool _isPrivate = false;
  List<String> _allowedUserIds = [];
  String _invitationCode = '';
  
  final List<String> _categories = [
    'Technology', 'Music', 'Business', 'Education', 'Sports',
    'Arts & Culture', 'Food & Drink', 'Health & Wellness', 'Entertainment'
  ];
  
  final List<String> _availableTags = [
    'tech', 'music', 'business', 'food', 'art', 'sports', 
    'education', 'health', 'entertainment', 'startup', 
    'networking', 'festival', 'conference', 'workshop',
    'live', 'outdoor', 'indoor', 'virtual', 'hybrid'
  ];
  
  final List<String> _eventTypes = ['Offline', 'Online', 'Hybrid'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _venueDetailsController.dispose();
    _contactInfoController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _isImageLoading = true);
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _bannerImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isImageLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<bool> _onBackPressed() async {
    if (_titleController.text.isNotEmpty || 
        _descriptionController.text.isNotEmpty ||
        _locationController.text.isNotEmpty ||
        _bannerImage != null) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('Discard Changes?'),
          content: const Text('You have unsaved changes. Are you sure you want to go back?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  }

  void _goToHome() {
    context.go('/');
  }

  void _onEventCreated(String eventId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Event created successfully! ID: $eventId'),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View Event',
          textColor: AppTheme.secondaryColor,
          onPressed: () {
            context.go('/');
          },
        ),
      ),
    );
    
    context.go('/');
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child('event_banners/${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = imageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<String?> _uploadQrImage(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child('event_payment_qr/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = imageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload QR image: $e');
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      String? bannerImageUrl;
      String? paymentQrUrl;
      
      // Upload image if selected
      if (_bannerImage != null) {
        bannerImageUrl = await _uploadImage(_bannerImage!);
      }
      if (_paymentQrImage != null) {
        paymentQrUrl = await _uploadQrImage(_paymentQrImage!);
      }
      
      // Ensure we have an authenticated user before creating the event
      final currentUserId = _authService.currentUser?.uid ?? _authService.userModel?.id;
      final currentUserName = _authService.userModel?.name ??
          _authService.currentUser?.displayName ??
          _authService.currentUser?.email ??
          'Unknown User';

      if (currentUserId == null || currentUserId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be signed in to create an event.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final event = EventModel(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        date: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        time: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        // Capacity should always reflect organiser input, even for free events
        totalTickets: _totalTickets,
        soldTickets: 0,
        price: _isFree ? 0.0 : _price,
        isFree: _isFree,
        organiserId: currentUserId,
        organiserName: currentUserName,
        bannerImage: bannerImageUrl, // Use uploaded URL
        paymentQrUrl: paymentQrUrl,
        category: _selectedCategory,
        tags: _selectedTags,
        isActive: true,
        isFeatured: false,
        createdAt: DateTime.now(),
        venueDetails: _venueDetailsController.text.trim(),
        eventType: _eventType,
        maxAttendees: _maxAttendees,
        contactInfo: _contactInfoController.text.trim(),
        website: _websiteController.text.trim(),
        accessControl: _accessControl,
        requiresAccessControl: _requiresAccessControl,
        isPrivate: _isPrivate,
        allowedUserIds: _allowedUserIds.isNotEmpty ? _allowedUserIds : null,
        invitationCode: _invitationCode.isNotEmpty ? _invitationCode : null,
      );
      
      final eventId = await FirestoreService().createEvent(event);
      
      if (mounted) {
        _onEventCreated(eventId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating event: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (await _onBackPressed()) {
          context.go('/');
        }
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            _onBackPressed().then((shouldPop) {
              if (shouldPop) {
                context.go('/');
              }
            });
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: AppTheme.secondaryColor,
            title: const Text('Create New Event'),
            elevation: 0,
            automaticallyImplyLeading: false,
            centerTitle: false,
            titleSpacing: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, size: 28),
                onPressed: () async {
                  if (await _onBackPressed()) {
                    context.go('/');
                  }
                },
                tooltip: 'Go Back',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.secondaryColor,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.home, size: 24),
                onPressed: _goToHome,
                tooltip: 'Go to Home',
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: LoadingIndicator())
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        
                        _buildBannerImageSection(),
                        
                        const SizedBox(height: 24),
                        
                        _buildSectionTitle('Basic Information'),
                        _buildTextField(
                          controller: _titleController,
                          label: 'Event Title',
                          hint: 'Enter event title',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter event title';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Event Description',
                          hint: 'Describe your event',
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter event description';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _locationController,
                          label: 'Event Location',
                          hint: 'Enter event location',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter event location';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _venueDetailsController,
                          label: 'Venue Details',
                          hint: 'Additional venue information',
                          maxLines: 2,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        _buildSectionTitle('Date & Time'),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildDatePicker(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTimePicker(),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        _buildSectionTitle('Event Details'),
                        
                        _buildDropdown(
                          label: 'Event Category',
                          value: _selectedCategory,
                          items: _categories,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedCategory = value);
                            }
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildDropdown(
                          label: 'Event Type',
                          value: _eventType,
                          items: _eventTypes,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _eventType = value);
                            }
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildTagsSelector(),
                        
                        const SizedBox(height: 24),
                        
                        _buildSectionTitle('Pricing & Tickets'),
                        
                        _buildToggleOption(
                          title: 'Free Event',
                          subtitle: 'No ticket cost required',
                          isSelected: _isFree,
                          onTap: () => setState(() => _isFree = !_isFree),
                        ),
                        
                        if (!_isFree) ...[
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: TextEditingController(text: _price > 0 ? _price.toStringAsFixed(2) : ''),
                            label: 'Ticket Price (₹)',
                            hint: '0.00',
                            inputFormatters: [CurrencyInputFormatter()],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter ticket price';
                              }
                              String cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
                              final price = double.tryParse(cleanValue);
                              if (price == null || price < 0) {
                                return 'Please enter a valid price';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                String cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
                                setState(() => _price = double.tryParse(cleanValue) ?? 0.0);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildPaymentQrSection(),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: TextEditingController(text: _totalTickets.toString()),
                          label: 'Total Tickets Available',
                          hint: '100',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter total tickets';
                            }
                            final tickets = int.tryParse(value);
                            if (tickets == null || tickets <= 0) {
                              return 'Please enter a valid number of tickets';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() => _totalTickets = int.tryParse(value) ?? 100);
                            }
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: TextEditingController(text: _maxAttendees.toString()),
                          label: 'Maximum Attendees',
                          hint: '100',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter maximum attendees';
                            }
                            final attendees = int.tryParse(value);
                            if (attendees == null || attendees <= 0) {
                              return 'Please enter a valid number of attendees';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() => _maxAttendees = int.tryParse(value) ?? 100);
                            }
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        _buildSectionTitle('Access Control'),
                        
                        _buildAccessControlSection(),
                        
                        const SizedBox(height: 24),
                        
                        _buildSectionTitle('Contact Information'),
                        
                        _buildTextField(
                          controller: _contactInfoController,
                          label: 'Contact Information',
                          hint: 'Phone, email, or other contact details',
                        ),
                        
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _websiteController,
                          label: 'Website (Optional)',
                          hint: 'https://example.com',
                        ),
                        
                        const SizedBox(height: 32),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _createEvent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: AppTheme.secondaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              'Create Event',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildBannerImageSection() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.dividerColor,
          width: 2,
        ),
      ),
      child: _bannerImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                _bannerImage!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            )
          : InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isImageLoading)
                    const CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    )
                  else ...[
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add Event Banner',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to select image',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentQrSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment QR Code (for manual payments)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: _paymentQrImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    _paymentQrImage!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
              : InkWell(
                  onTap: () async {
                    final picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1024,
                      maxHeight: 1024,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      setState(() => _paymentQrImage = File(image.path));
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_2, size: 40, color: AppTheme.textSecondary),
                      const SizedBox(height: 8),
                      Text(
                        'Add QR code image to receive payments',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
        ),
        if (_paymentQrImage != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _paymentQrImage = null),
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ),
          const Text(
            'Attendees will be asked to pay using this QR and upload a screenshot. You must verify payments before tickets are issued.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            filled: true,
            fillColor: AppTheme.inputBackground,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.inputBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Tags',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
              backgroundColor: AppTheme.surfaceColor,
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.secondaryColor : AppTheme.textPrimary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Date',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.inputBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Time',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectTime,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.inputBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedTime.format(context),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.secondaryColor : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected 
                    ? AppTheme.secondaryColor.withValues(alpha: 0.8)
                    : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessControlSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Public vs Private Event Toggle
        Row(
          children: [
            Expanded(
              child: _buildToggleOption(
                title: 'Public Event',
                subtitle: 'Anyone can attend',
                isSelected: !_requiresAccessControl && !_isPrivate,
                onTap: () {
                  setState(() {
                    _requiresAccessControl = false;
                    _isPrivate = false;
                    _accessControl = null;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildToggleOption(
                title: 'Restricted Event',
                subtitle: 'Access control required',
                isSelected: _requiresAccessControl || _isPrivate,
                onTap: () {
                  setState(() {
                    _requiresAccessControl = true;
                  });
                },
              ),
            ),
          ],
        ),
        
        if (_requiresAccessControl || _isPrivate) ...[
          const SizedBox(height: 16),
          
          // Private Event Option
          SwitchListTile(
            title: const Text(
              'Private Event',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: const Text(
              'Only invited users can attend',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            value: _isPrivate,
            onChanged: (value) {
              setState(() {
                _isPrivate = value;
                if (value) {
                  _requiresAccessControl = true;
                }
              });
            },
            activeColor: AppTheme.primaryColor,
          ),
          
          if (_isPrivate) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: TextEditingController(text: _invitationCode),
              label: 'Invitation Code (Optional)',
              hint: 'Enter a public invitation code',
              onChanged: (value) {
                setState(() => _invitationCode = value);
              },
            ),
          ],
          
          if (_requiresAccessControl && !_isPrivate) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Access Control Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Configure who can attend this event',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAccessControlDialog(),
                      icon: const Icon(Icons.settings),
                      label: const Text('Configure Access Control'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.secondaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  if (_accessControl != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppTheme.primaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _accessControl!.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _accessControl!.accessTypeDescription,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  void _showAccessControlDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Configure Access Control',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: AccessControlForm(
                  accessControl: _accessControl,
                  onSave: (accessControl) {
                    setState(() {
                      _accessControl = accessControl;
                    });
                    Navigator.of(context).pop();
                  },
                  onCancel: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


} 