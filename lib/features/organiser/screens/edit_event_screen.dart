import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../core/models/event_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/utils/helpers.dart';
import 'package:go_router/go_router.dart';

class EditEventScreen extends StatefulWidget {
  final String eventId;
  
  const EditEventScreen({super.key, required this.eventId});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _venueDetailsController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _websiteController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
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
  
  File? _newBannerImage;
  String? _currentBannerImage;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isImageLoading = false;
  EventModel? _event;
  
  final List<String> _categories = [
    'Technology', 'Music', 'Business', 'Education', 'Sports',
    'Arts & Culture', 'Food & Drink', 'Health & Wellness', 'Entertainment'
  ];
  
  final List<String> _availableTags = [
    'tech', 'music', 'business', 'food', 'art', 'sports', 
    'education', 'health', 'entertainment', 'startup', 
    'networking', 'festival', 'conference', 'workshop'
  ];

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    try {
      final event = await _firestoreService.getEvent(widget.eventId);
      if (event != null) {
        setState(() {
          _event = event;
          _titleController.text = event.title;
          _descriptionController.text = event.description;
          _locationController.text = event.location;
          _venueDetailsController.text = event.venueDetails ?? '';
          _contactInfoController.text = event.contactInfo ?? '';
          _websiteController.text = event.website ?? '';
          _selectedDate = event.date;
          _selectedTime = TimeOfDay(hour: event.time.hour, minute: event.time.minute);
          _latitude = event.latitude;
          _longitude = event.longitude;
          _selectedCategory = event.category;
          _selectedTags = List.from(event.tags);
          _eventType = event.eventType ?? 'Offline';
          _isFree = event.isFree;
          _price = event.price;
          _totalTickets = event.totalTickets;
          _maxAttendees = event.maxAttendees ?? 100;
          _currentBannerImage = event.bannerImage;
        });
      } else {
        // Handle case where event is not found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event not found. Please check the event ID.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          context.go('/'); // Navigate back to home
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading event: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _newBannerImage = File(pickedFile.path);
        _isImageLoading = true;
      });
      
      // Simulate image processing
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _isImageLoading = false);
    }
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

  Future<void> _saveEvent() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) return;
    
    if (_event == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event not loaded. Please try again.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      String? bannerImageUrl = _currentBannerImage;
      
      // Upload new image if selected
      if (_newBannerImage != null) {
        bannerImageUrl = await _uploadImage(_newBannerImage!);
      }
      
      if (_event == null) {
        throw Exception('Event not loaded');
      }
      
      final updatedEvent = _event!.copyWith(
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
        totalTickets: _isFree ? 0 : _totalTickets,
        price: _isFree ? 0.0 : _price,
        isFree: _isFree,
        bannerImage: bannerImageUrl,
        category: _selectedCategory,
        tags: _selectedTags,
        venueDetails: _venueDetailsController.text.trim(),
        eventType: _eventType,
        maxAttendees: _maxAttendees,
        contactInfo: _contactInfoController.text.trim(),
        website: _websiteController.text.trim(),
        updatedAt: DateTime.now(),
      );
      
      await _firestoreService.updateEvent(widget.eventId, updatedEvent.toMap());
      
             if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('Event updated successfully!'),
             backgroundColor: AppTheme.successColor,
           ),
         );
         context.go('/event/${widget.eventId}');
       }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating event: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
         if (_isLoading) {
       return Scaffold(
         appBar: AppBar(
           title: const Text('Edit Event'),
           backgroundColor: AppTheme.primaryColor,
           foregroundColor: AppTheme.secondaryColor,
           leading: IconButton(
             icon: const Icon(Icons.arrow_back),
             onPressed: () => context.go('/event/${widget.eventId}'),
           ),
         ),
         body: const Center(child: LoadingIndicator()),
       );
     }
    
         if (_event == null) {
       return Scaffold(
         appBar: AppBar(
           title: const Text('Edit Event'),
           backgroundColor: AppTheme.primaryColor,
           foregroundColor: AppTheme.secondaryColor,
           leading: IconButton(
             icon: const Icon(Icons.arrow_back),
             onPressed: () => context.go('/event/${widget.eventId}'),
           ),
         ),
         body: const Center(
           child: Text('Event not found'),
         ),
       );
     }
    
         return Scaffold(
       appBar: AppBar(
         title: const Text('Edit Event'),
         backgroundColor: AppTheme.primaryColor,
         foregroundColor: AppTheme.secondaryColor,
         leading: IconButton(
           icon: const Icon(Icons.arrow_back),
           onPressed: () => context.go('/event/${widget.eventId}'),
         ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveEvent,
            child: _isSaving 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Image Section
              _buildBannerImageSection(),
              
              const SizedBox(height: 24),
              
              // Basic Information
              _buildBasicInfoSection(),
              
              const SizedBox(height: 24),
              
              // Date and Time
              _buildDateTimeSection(),
              
              const SizedBox(height: 24),
              
              // Location
              _buildLocationSection(),
              
              const SizedBox(height: 24),
              
              // Category and Tags
              _buildCategoryTagsSection(),
              
              const SizedBox(height: 24),
              
              // Ticket Information
              _buildTicketSection(),
              
              const SizedBox(height: 24),
              
              // Additional Information
              _buildAdditionalInfoSection(),
              
              const SizedBox(height: 32),
              
              // Confirm Changes Button
              _buildConfirmChangesButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Banner',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Current or new banner image
        if (_newBannerImage != null || _currentBannerImage != null)
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _isImageLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _newBannerImage != null
                      ? Image.file(
                          _newBannerImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _currentBannerImage != null
                                ? Image.network(
                                    _currentBannerImage!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholderImage();
                                    },
                                  )
                                : _buildPlaceholderImage();
                          },
                        )
                      : _currentBannerImage != null
                          ? Image.network(
                              _currentBannerImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage();
                              },
                            )
                          : _buildPlaceholderImage(),
            ),
          ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('Change Banner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.secondaryColor,
                ),
              ),
            ),
            if (_newBannerImage != null || _currentBannerImage != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _newBannerImage = null;
                      _currentBannerImage = null;
                    });
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Remove'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('No banner image', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Event Title *',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an event title';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description *',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an event description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date & Time',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('Date'),
                subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
            ),
            Expanded(
              child: ListTile(
                title: const Text('Time'),
                subtitle: Text('${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (time != null) {
                    setState(() => _selectedTime = time);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Location *',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a location';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _venueDetailsController,
          decoration: const InputDecoration(
            labelText: 'Venue Details (Optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildCategoryTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category & Tags',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Category *',
            border: OutlineInputBorder(),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedCategory = value);
            }
          },
        ),
        
        const SizedBox(height: 16),
        
        Text(
          'Tags (Select up to 5)',
          style: Theme.of(context).textTheme.bodyMedium,
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
                  if (selected && _selectedTags.length < 5) {
                    _selectedTags.add(tag);
                  } else if (!selected) {
                    _selectedTags.remove(tag);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTicketSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ticket Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        SwitchListTile(
          title: const Text('Free Event'),
          value: _isFree,
          onChanged: (value) {
            setState(() {
              _isFree = value;
              if (value) {
                _price = 0.0;
                _totalTickets = 0;
              } else {
                _price = 10.0;
                _totalTickets = 100;
              }
            });
          },
        ),
        
        if (!_isFree) ...[
          const SizedBox(height: 16),
          
          TextFormField(
            initialValue: _price > 0 ? _price.toStringAsFixed(2) : '',
            decoration: const InputDecoration(
              labelText: 'Price (₹)',
              hintText: '0.00',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
            onChanged: (value) {
              // Remove formatting and parse the value
              String cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
              setState(() => _price = double.tryParse(cleanValue) ?? 0.0);
            },
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            initialValue: _totalTickets.toString(),
            decoration: const InputDecoration(
              labelText: 'Total Tickets',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() => _totalTickets = int.tryParse(value) ?? 100);
            },
          ),
        ],
        
        const SizedBox(height: 16),
        
        TextFormField(
          initialValue: _maxAttendees.toString(),
          decoration: const InputDecoration(
            labelText: 'Max Attendees',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() => _maxAttendees = int.tryParse(value) ?? 100);
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _contactInfoController,
          decoration: const InputDecoration(
            labelText: 'Contact Information',
            border: OutlineInputBorder(),
          ),
        ),
        
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _websiteController,
          decoration: const InputDecoration(
            labelText: 'Website',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmChangesButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Warning message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Review your changes carefully. Once confirmed, the event will be updated in Firebase.',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Confirm Changes Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _confirmChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSaving
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Updating Event...'),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle),
                        SizedBox(width: 8),
                        Text(
                          'Confirm Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          const SizedBox(height: 16),
          
                     // Cancel Button
           SizedBox(
             width: double.infinity,
             height: 45,
             child: OutlinedButton(
               onPressed: _isSaving ? null : () => context.go('/event/${widget.eventId}'),
               style: OutlinedButton.styleFrom(
                 foregroundColor: Colors.grey[600],
                 side: BorderSide(color: Colors.grey[300]!),
                 shape: RoundedRectangleBorder(
                   borderRadius: BorderRadius.circular(8),
                 ),
               ),
               child: const Text('Cancel'),
             ),
           ),
        ],
      ),
    );
  }

  Future<void> _confirmChanges() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Changes'),
        content: const Text(
          'Are you sure you want to update this event? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.secondaryColor,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _saveEvent();
    }
  }
}
