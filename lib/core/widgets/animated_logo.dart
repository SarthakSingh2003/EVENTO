import 'package:flutter/material.dart';

class AnimatedLogo extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool showShadow;

  const AnimatedLogo({
    super.key,
    this.size = 120,
    this.borderRadius = 20,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: size,
      height: size,
      decoration: showShadow ? BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ) : null,
      child: ClipOval(
        child: Image.asset(
          'lib/asssets/images/LOGO.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
} 