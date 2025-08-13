import 'package:flutter/material.dart';
import '../../../core/models/ticket_model.dart';
import '../../../core/utils/constants.dart';

class TicketWidget extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback? onTap;

  const TicketWidget({
    super.key,
    required this.ticket,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.eventTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.smallPadding,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ticket.isValid 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ticket.status,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ticket.isValid ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                'Purchased: ${ticket.formattedPurchaseDate}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                'Price: ${ticket.formattedPrice}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 