import 'package:flutter/material.dart';
import '../utils/constants.dart';

enum LoadingType { circular, linear, dots }

class LoadingIndicator extends StatelessWidget {
  final LoadingType type;
  final String? message;
  final Color? color;
  final double? size;
  final bool isFullScreen;

  const LoadingIndicator({
    super.key,
    this.type = LoadingType.circular,
    this.message,
    this.color,
    this.size,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadingColor = color ?? theme.colorScheme.primary;

    Widget indicator = _buildIndicator(loadingColor);

    if (message != null) {
      indicator = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (isFullScreen) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.8),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: indicator,
          ),
        ),
      );
    }

    return Center(child: indicator);
  }

  Widget _buildIndicator(Color color) {
    switch (type) {
      case LoadingType.circular:
        return SizedBox(
          width: size ?? 40,
          height: size ?? 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );

      case LoadingType.linear:
        return SizedBox(
          width: size ?? 200,
          child: LinearProgressIndicator(
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );

      case LoadingType.dots:
        return _DotsLoadingIndicator(color: color, size: size);
    }
  }
}

class _DotsLoadingIndicator extends StatefulWidget {
  final Color color;
  final double? size;

  const _DotsLoadingIndicator({
    required this.color,
    this.size,
  });

  @override
  State<_DotsLoadingIndicator> createState() => _DotsLoadingIndicatorState();
}

class _DotsLoadingIndicatorState extends State<_DotsLoadingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: Duration(milliseconds: 600 + (index * 200)),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    for (final controller in _controllers) {
      controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: (widget.size ?? 8) * _animations[index].value,
              height: widget.size ?? 8,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

// Convenience constructors for common loading types
class CircularLoadingIndicator extends StatelessWidget {
  final String? message;
  final Color? color;
  final double? size;
  final bool isFullScreen;

  const CircularLoadingIndicator({
    super.key,
    this.message,
    this.color,
    this.size,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingIndicator(
      type: LoadingType.circular,
      message: message,
      color: color,
      size: size,
      isFullScreen: isFullScreen,
    );
  }
}

class LinearLoadingIndicator extends StatelessWidget {
  final String? message;
  final Color? color;
  final double? size;
  final bool isFullScreen;

  const LinearLoadingIndicator({
    super.key,
    this.message,
    this.color,
    this.size,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingIndicator(
      type: LoadingType.linear,
      message: message,
      color: color,
      size: size,
      isFullScreen: isFullScreen,
    );
  }
}

class DotsLoadingIndicator extends StatelessWidget {
  final String? message;
  final Color? color;
  final double? size;
  final bool isFullScreen;

  const DotsLoadingIndicator({
    super.key,
    this.message,
    this.color,
    this.size,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingIndicator(
      type: LoadingType.dots,
      message: message,
      color: color,
      size: size,
      isFullScreen: isFullScreen,
    );
  }
}

// Full screen loading overlay
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: LoadingIndicator(
              message: message,
              isFullScreen: true,
            ),
          ),
      ],
    );
  }
} 