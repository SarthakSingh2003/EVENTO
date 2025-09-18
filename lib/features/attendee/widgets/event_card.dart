import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/event_model.dart';
import '../../../core/utils/constants.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;
  final bool showCreatorActions; // New parameter

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.showCreatorActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final currentUserId = authService.userModel?.id;
    final isEventCreator = event.organiserId == currentUserId;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap ?? () => context.go('/event/${event.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Banner
            if (event.bannerImage != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    event.bannerImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                      );
                    },
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Title and Status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Event Info Row
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.formattedDate,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.formattedTime,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    event.description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Tags
                  if (event.tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: event.tags.take(3).map((tag) => Chip(
                        label: Text(
                          tag,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // Bottom Row - Price, Tickets, Organizer
                  Row(
                    children: [
                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: event.isFree 
                              ? Colors.green.withOpacity(0.1)
                              : AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.formattedPrice,
                          style: TextStyle(
                            color: event.isFree 
                                ? Colors.green[700]
                                : AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Available Tickets
                      if (!event.isFree)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: event.availableTickets > 0 
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${event.availableTickets} left',
                            style: TextStyle(
                              color: event.availableTickets > 0 
                                  ? Colors.blue[700]
                                  : Colors.red[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Organizer
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.organiserName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Add creator badge if user is the creator
            if (isEventCreator)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  border: Border(
                    top: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'You created this event',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;
    String text;

    if (event.isPast) {
      backgroundColor = Colors.grey.withOpacity(0.1);
      textColor = Colors.grey[700]!;
      text = 'Past';
    } else if (event.isSoldOut) {
      backgroundColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red[700]!;
      text = 'Sold Out';
    } else if (event.isToday) {
      backgroundColor = Colors.orange.withOpacity(0.1);
      textColor = Colors.orange[700]!;
      text = 'Today';
    } else {
      backgroundColor = Colors.green.withOpacity(0.1);
      textColor = Colors.green[700]!;
      text = 'Upcoming';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
} 