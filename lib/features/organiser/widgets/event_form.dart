import 'package:flutter/material.dart';
import '../../../core/models/event_model.dart';
import '../../../core/utils/constants.dart';

class EventForm extends StatefulWidget {
  final EventModel? event;
  final Function(EventModel) onSave;

  const EventForm({
    super.key,
    this.event,
    required this.onSave,
  });

  @override
  State<EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedCategory = AppConstants.eventCategories.first;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  int _totalTickets = 100;
  double _price = 0.0;
  bool _isFree = true;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description;
      _locationController.text = widget.event!.location;
      _selectedCategory = widget.event!.category;
      _selectedDate = widget.event!.date;
      _selectedTime = TimeOfDay.fromDateTime(widget.event!.time);
      _totalTickets = widget.event!.totalTickets;
      _price = widget.event!.price;
      _isFree = widget.event!.isFree;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Event Title',
              hintText: 'Enter event title',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter event title';
              }
              return null;
            },
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Enter event description',
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter event description';
              }
              return null;
            },
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              hintText: 'Enter event location',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter event location';
              }
              return null;
            },
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
            ),
            items: AppConstants.eventCategories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
            },
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                  child: Text('Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (time != null) {
                      setState(() {
                        _selectedTime = time;
                      });
                    }
                  },
                  child: Text('Time: ${_selectedTime.format(context)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _totalTickets.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Total Tickets',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _totalTickets = int.tryParse(value) ?? 100;
                  },
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: const Text('Free Event'),
                      value: _isFree,
                      onChanged: (value) {
                        setState(() {
                          _isFree = value ?? true;
                        });
                      },
                    ),
                    if (!_isFree)
                      TextFormField(
                        initialValue: _price.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Price (\$)',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _price = double.tryParse(value) ?? 0.0;
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 