import 'package:flutter/material.dart';
import '../../../core/models/access_control_model.dart';
import '../../../core/utils/constants.dart';

class AccessControlForm extends StatefulWidget {
  final AccessControlModel? accessControl;
  final Function(AccessControlModel) onSave;
  final VoidCallback? onCancel;

  const AccessControlForm({
    super.key,
    this.accessControl,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<AccessControlForm> createState() => _AccessControlFormState();
}

class _AccessControlFormState extends State<AccessControlForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  AccessControlType _selectedType = AccessControlType.public;
  bool _isActive = true;
  
  // Email domain settings
  final List<String> _allowedEmailDomains = [];
  final List<String> _blockedEmailDomains = [];
  final _emailDomainController = TextEditingController();
  
  // User group settings
  final List<UserGroup> _allowedUserGroups = [];
  
  // Age restrictions
  int? _minimumAge;
  int? _maximumAge;
  
  // Location settings
  double? _maxDistanceKm;
  final List<String> _allowedCountries = [];
  final List<String> _allowedCities = [];
  final _locationController = TextEditingController();
  
  // Invitation settings
  final List<String> _invitedEmails = [];
  final _invitationEmailController = TextEditingController();
  String? _invitationCode;
  bool _requireInvitationCode = false;
  
  // Verification requirements
  bool _requireEmailVerification = false;
  bool _requirePhoneVerification = false;
  bool _requireDocumentVerification = false;
  final List<String> _requiredDocuments = [];
  
  // Access control settings
  int? _maxTicketsPerUser;
  bool _allowWaitlist = false;
  int? _waitlistCapacity;
  DateTime? _accessStartDate;
  DateTime? _accessEndDate;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.accessControl != null) {
      final ac = widget.accessControl!;
      _nameController.text = ac.name;
      _descriptionController.text = ac.description;
      _selectedType = ac.type;
      _isActive = ac.isActive;
      
      // Load email domain settings
      _allowedEmailDomains.addAll(ac.allowedEmailDomains ?? []);
      _blockedEmailDomains.addAll(ac.blockedEmailDomains ?? []);
      
      // Load user group settings
      _allowedUserGroups.addAll(ac.allowedUserGroups ?? []);
      
      // Load age restrictions
      _minimumAge = ac.minimumAge;
      _maximumAge = ac.maximumAge;
      
      // Load location settings
      _maxDistanceKm = ac.maxDistanceKm;
      _allowedCountries.addAll(ac.allowedCountries ?? []);
      _allowedCities.addAll(ac.allowedCities ?? []);
      
      // Load invitation settings
      _invitedEmails.addAll(ac.invitedEmails ?? []);
      _invitationCode = ac.invitationCode;
      _requireInvitationCode = ac.requireInvitationCode;
      
      // Load verification requirements
      _requireEmailVerification = ac.requireEmailVerification;
      _requirePhoneVerification = ac.requirePhoneVerification;
      _requireDocumentVerification = ac.requireDocumentVerification;
      _requiredDocuments.addAll(ac.requiredDocuments ?? []);
      
      // Load access control settings
      _maxTicketsPerUser = ac.maxTicketsPerUser;
      _allowWaitlist = ac.allowWaitlist;
      _waitlistCapacity = ac.waitlistCapacity;
      _accessStartDate = ac.accessStartDate;
      _accessEndDate = ac.accessEndDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _emailDomainController.dispose();
    _invitationEmailController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _saveAccessControl() {
    if (!_formKey.currentState!.validate()) return;

    final accessControl = AccessControlModel(
      id: widget.accessControl?.id,
      eventId: widget.accessControl?.eventId ?? '',
      type: _selectedType,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      isActive: _isActive,
      createdAt: widget.accessControl?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      allowedEmailDomains: _allowedEmailDomains.isNotEmpty ? _allowedEmailDomains : null,
      blockedEmailDomains: _blockedEmailDomains.isNotEmpty ? _blockedEmailDomains : null,
      allowedUserGroups: _allowedUserGroups.isNotEmpty ? _allowedUserGroups : null,
      minimumAge: _minimumAge,
      maximumAge: _maximumAge,
      maxDistanceKm: _maxDistanceKm,
      allowedCountries: _allowedCountries.isNotEmpty ? _allowedCountries : null,
      allowedCities: _allowedCities.isNotEmpty ? _allowedCities : null,
      invitedEmails: _invitedEmails.isNotEmpty ? _invitedEmails : null,
      invitationCode: _invitationCode,
      requireInvitationCode: _requireInvitationCode,
      requireEmailVerification: _requireEmailVerification,
      requirePhoneVerification: _requirePhoneVerification,
      requireDocumentVerification: _requireDocumentVerification,
      requiredDocuments: _requiredDocuments.isNotEmpty ? _requiredDocuments : null,
      maxTicketsPerUser: _maxTicketsPerUser,
      allowWaitlist: _allowWaitlist,
      waitlistCapacity: _waitlistCapacity,
      accessStartDate: _accessStartDate,
      accessEndDate: _accessEndDate,
    );

    widget.onSave(accessControl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accessControl == null ? 'Add Access Control' : 'Edit Access Control'),
        actions: [
          TextButton(
            onPressed: _saveAccessControl,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information
            _buildSection(
              title: 'Basic Information',
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Access Control Name',
                    hintText: 'e.g., Student Only, Faculty Exclusive',
                  ),
                  validator: (value) {
                    if (value?.isEmpty == true) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe the access control requirements',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Enable this access control'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Access Control Type
            _buildSection(
              title: 'Access Control Type',
              children: [
                DropdownButtonFormField<AccessControlType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: AccessControlType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getAccessControlTypeName(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getAccessControlTypeDescription(_selectedType),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Type-specific settings
            if (_selectedType == AccessControlType.emailDomain) ...[
              _buildEmailDomainSettings(),
            ] else if (_selectedType == AccessControlType.userGroup) ...[
              _buildUserGroupSettings(),
            ] else if (_selectedType == AccessControlType.ageRestricted) ...[
              _buildAgeRestrictionSettings(),
            ] else if (_selectedType == AccessControlType.locationBased) ...[
              _buildLocationSettings(),
            ] else if (_selectedType == AccessControlType.invitationOnly) ...[
              _buildInvitationSettings(),
            ] else if (_selectedType == AccessControlType.customCriteria) ...[
              _buildCustomCriteriaSettings(),
            ],

            const SizedBox(height: 24),

            // Verification Requirements
            _buildSection(
              title: 'Verification Requirements',
              children: [
                SwitchListTile(
                  title: const Text('Require Email Verification'),
                  subtitle: const Text('Users must verify their email'),
                  value: _requireEmailVerification,
                  onChanged: (value) => setState(() => _requireEmailVerification = value),
                ),
                SwitchListTile(
                  title: const Text('Require Phone Verification'),
                  subtitle: const Text('Users must verify their phone number'),
                  value: _requirePhoneVerification,
                  onChanged: (value) => setState(() => _requirePhoneVerification = value),
                ),
                SwitchListTile(
                  title: const Text('Require Document Verification'),
                  subtitle: const Text('Users must verify specific documents'),
                  value: _requireDocumentVerification,
                  onChanged: (value) => setState(() => _requireDocumentVerification = value),
                ),
                if (_requireDocumentVerification) ...[
                  const SizedBox(height: 16),
                  _buildRequiredDocumentsList(),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // Access Control Settings
            _buildSection(
              title: 'Access Control Settings',
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Max Tickets Per User',
                    hintText: 'Leave empty for unlimited',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _maxTicketsPerUser = value.isEmpty ? null : int.tryParse(value);
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Allow Waitlist'),
                  subtitle: const Text('Allow users to join waitlist when sold out'),
                  value: _allowWaitlist,
                  onChanged: (value) => setState(() => _allowWaitlist = value),
                ),
                if (_allowWaitlist) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Waitlist Capacity',
                      hintText: 'Maximum number of waitlist spots',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _waitlistCapacity = value.isEmpty ? null : int.tryParse(value);
                    },
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Access Start Date',
                          hintText: 'When ticket sales open',
                        ),
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _accessStartDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => _accessStartDate = date);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Access End Date',
                          hintText: 'When ticket sales close',
                        ),
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _accessEndDate ?? DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => _accessEndDate = date);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAccessControl,
                    child: const Text('Save Access Control'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildEmailDomainSettings() {
    return _buildSection(
      title: 'Email Domain Settings',
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailDomainController,
                decoration: const InputDecoration(
                  labelText: 'Email Domain',
                  hintText: 'e.g., university.edu',
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final domain = _emailDomainController.text.trim();
                if (domain.isNotEmpty && !_allowedEmailDomains.contains(domain)) {
                  setState(() {
                    _allowedEmailDomains.add(domain);
                    _emailDomainController.clear();
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
        if (_allowedEmailDomains.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _allowedEmailDomains.map((domain) {
              return Chip(
                label: Text(domain),
                onDeleted: () {
                  setState(() => _allowedEmailDomains.remove(domain));
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildUserGroupSettings() {
    return _buildSection(
      title: 'User Group Settings',
      children: [
        Wrap(
          spacing: 8,
          children: UserGroup.values.map((group) {
            final isSelected = _allowedUserGroups.contains(group);
            return FilterChip(
              label: Text(_getUserGroupName(group)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _allowedUserGroups.add(group);
                  } else {
                    _allowedUserGroups.remove(group);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAgeRestrictionSettings() {
    return _buildSection(
      title: 'Age Restrictions',
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Minimum Age',
                  hintText: 'e.g., 18',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _minimumAge = value.isEmpty ? null : int.tryParse(value);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Maximum Age',
                  hintText: 'e.g., 65',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _maximumAge = value.isEmpty ? null : int.tryParse(value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSettings() {
    return _buildSection(
      title: 'Location Settings',
      children: [
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Maximum Distance (km)',
            hintText: 'e.g., 50',
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _maxDistanceKm = value.isEmpty ? null : double.tryParse(value);
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Allowed Country/City',
                  hintText: 'e.g., USA or New York',
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final location = _locationController.text.trim();
                if (location.isNotEmpty && !_allowedCountries.contains(location) && !_allowedCities.contains(location)) {
                  setState(() {
                    // Simple logic: if it's a country, add to countries, otherwise add to cities
                    if (location.length <= 3) {
                      _allowedCountries.add(location);
                    } else {
                      _allowedCities.add(location);
                    }
                    _locationController.clear();
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
        if (_allowedCountries.isNotEmpty || _allowedCities.isNotEmpty) ...[
          const SizedBox(height: 16),
          if (_allowedCountries.isNotEmpty) ...[
            const Text('Allowed Countries:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: _allowedCountries.map((country) {
                return Chip(
                  label: Text(country),
                  onDeleted: () {
                    setState(() => _allowedCountries.remove(country));
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
          if (_allowedCities.isNotEmpty) ...[
            const Text('Allowed Cities:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: _allowedCities.map((city) {
                return Chip(
                  label: Text(city),
                  onDeleted: () {
                    setState(() => _allowedCities.remove(city));
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildInvitationSettings() {
    return _buildSection(
      title: 'Invitation Settings',
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _invitationEmailController,
                decoration: const InputDecoration(
                  labelText: 'Invite Email',
                  hintText: 'email@example.com',
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final email = _invitationEmailController.text.trim();
                if (email.isNotEmpty && !_invitedEmails.contains(email)) {
                  setState(() {
                    _invitedEmails.add(email);
                    _invitationEmailController.clear();
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
        if (_invitedEmails.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _invitedEmails.map((email) {
              return Chip(
                label: Text(email),
                onDeleted: () {
                  setState(() => _invitedEmails.remove(email));
                },
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Require Invitation Code'),
          subtitle: const Text('Users must enter an invitation code'),
          value: _requireInvitationCode,
          onChanged: (value) => setState(() => _requireInvitationCode = value),
        ),
        if (_requireInvitationCode) ...[
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Invitation Code',
              hintText: 'e.g., STUDENT2024',
            ),
            onChanged: (value) => _invitationCode = value.trim(),
          ),
        ],
      ],
    );
  }

  Widget _buildCustomCriteriaSettings() {
    return _buildSection(
      title: 'Custom Criteria Settings',
      children: [
        const Text(
          'Custom criteria will be validated based on user profile information. '
          'Users must meet all specified requirements to purchase tickets.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        // This would typically include a more sophisticated rule builder
        // For now, we'll use the verification requirements
        const Text(
          'Use the verification requirements below to set custom criteria.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildRequiredDocumentsList() {
    final documentTypes = [
      'student_id',
      'employee_badge',
      'government_id',
      'passport',
      'driver_license',
      'membership_card',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Required Documents:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: documentTypes.map((docType) {
            final isSelected = _requiredDocuments.contains(docType);
            return FilterChip(
              label: Text(_getDocumentTypeName(docType)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _requiredDocuments.add(docType);
                  } else {
                    _requiredDocuments.remove(docType);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getAccessControlTypeName(AccessControlType type) {
    switch (type) {
      case AccessControlType.public:
        return 'Public';
      case AccessControlType.emailDomain:
      case AccessControlType.emailDomainRestricted:
        return 'Email Domain';
      case AccessControlType.userGroup:
      case AccessControlType.userGroupRestricted:
        return 'User Group';
      case AccessControlType.invitationOnly:
        return 'Invitation Only';
      case AccessControlType.ageRestricted:
        return 'Age Restricted';
      case AccessControlType.locationBased:
        return 'Location Based';
      case AccessControlType.customCriteria:
        return 'Custom Criteria';
    }
  }

  String _getAccessControlTypeDescription(AccessControlType type) {
    switch (type) {
      case AccessControlType.public:
        return 'Anyone can purchase tickets for this event.';
      case AccessControlType.emailDomain:
      case AccessControlType.emailDomainRestricted:
        return 'Only users with specific email domains can purchase tickets.';
      case AccessControlType.userGroup:
      case AccessControlType.userGroupRestricted:
        return 'Only users belonging to specific groups can purchase tickets.';
      case AccessControlType.invitationOnly:
        return 'Only invited users can purchase tickets.';
      case AccessControlType.ageRestricted:
        return 'Only users within specific age ranges can purchase tickets.';
      case AccessControlType.locationBased:
        return 'Only users in specific locations can purchase tickets.';
      case AccessControlType.customCriteria:
        return 'Custom validation rules apply for ticket purchases.';
    }
  }

  String _getUserGroupName(UserGroup group) {
    switch (group) {
      case UserGroup.students:
        return 'Students';
      case UserGroup.faculty:
        return 'Faculty';
      case UserGroup.employees:
        return 'Employees';
      case UserGroup.alumni:
        return 'Alumni';
      case UserGroup.members:
        return 'Members';
      case UserGroup.guests:
        return 'Guests';
      case UserGroup.vip:
        return 'VIP';
      case UserGroup.custom:
        return 'Custom';
    }
  }

  String _getDocumentTypeName(String docType) {
    switch (docType) {
      case 'student_id':
        return 'Student ID';
      case 'employee_badge':
        return 'Employee Badge';
      case 'government_id':
        return 'Government ID';
      case 'passport':
        return 'Passport';
      case 'driver_license':
        return 'Driver License';
      case 'membership_card':
        return 'Membership Card';
      default:
        return docType.replaceAll('_', ' ').toUpperCase();
    }
  }
}
