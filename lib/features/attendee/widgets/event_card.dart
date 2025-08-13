import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';  // Temporarily disabled
import '../../../core/models/event_model.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/helpers.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.borderRadius),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: event.bannerImage != null
                    ? Container(
                        // CachedNetworkImage(  // Temporarily disabled
                        //   imageUrl: event.bannerImage!,
                        //   fit: BoxFit.cover,
                        //   placeholder: (context, url) => Container(
                        //     color: theme.colorScheme.surface,
                        //     child: const Center(
                        //       child: CircularProgressIndicator(),
                        //     ),
                        //   ),
                        //   errorWidget: (context, url, error) => Container(
                        //     color: theme.colorScheme.surface,
                        //     child: Icon(
                        //       Icons.event,
                        //       size: 48,
                        //       color: theme.colorScheme.primary,
                        //     ),
                        //   ),
                        // )
                        color: theme.colorScheme.surface,
                        child: Icon(
                          Icons.event,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : Container(
                        color: theme.colorScheme.surface,
                        child: Icon(
                          Icons.event,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                      ),
              ),
            ),
            
            // Event Details
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Category
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.smallPadding,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event.category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppConstants.smallPadding),
                  
                  // Description
                  Text(
                    event.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  // Event Info Row
                  Row(
                    children: [
                      // Date & Time
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.formattedDateTime,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: AppConstants.defaultPadding),
                      
                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.smallPadding,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: event.isFree 
                              ? Colors.green.withOpacity(0.1)
                              : theme.colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.formattedPrice,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: event.isFree ? Colors.green : theme.colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppConstants.smallPadding),
                  
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  // Bottom Row
                  Row(
                    children: [
                      // Organiser
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                              child: Text(
                                event.organiserName.isNotEmpty 
                                    ? event.organiserName[0].toUpperCase()
                                    : 'O',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'by ${event.organiserName}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Ticket Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.smallPadding,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: event.isSoldOut 
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.isSoldOut ? 'Sold Out' : '${event.availableTickets} left',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: event.isSoldOut ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 