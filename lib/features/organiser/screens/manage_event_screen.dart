import 'package:flutter/material.dart';
import '../../../core/utils/constants.dart';

class ManageEventScreen extends StatelessWidget {
  final String eventId;
  
  const ManageEventScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Event'),
      ),
      body: Center(
        child: Text('Manage Event Screen - Event ID: $eventId'),
      ),
    );
  }
} 