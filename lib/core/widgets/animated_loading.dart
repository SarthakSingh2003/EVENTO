import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

class AnimatedLoading extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;

  const AnimatedLoading({
    super.key,
    this.message,
    this.size = 50.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading indicator
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color ?? Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            child: Center(
              child: SizedBox(
                width: size * 0.6,
                height: size * 0.6,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color ?? Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat())
            .rotate(duration: 1.5.seconds, curve: Curves.easeInOut),
          
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
          ],
        ],
      ),
    );
  }
}

class AnimatedLoadingWithDots extends StatefulWidget {
  final String? message;
  final double size;
  final Color? color;

  const AnimatedLoadingWithDots({
    super.key,
    this.message,
    this.size = 50.0,
    this.color,
  });

  @override
  State<AnimatedLoadingWithDots> createState() => _AnimatedLoadingWithDotsState();
}

class _AnimatedLoadingWithDotsState extends State<AnimatedLoadingWithDots>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _dotController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _controller.repeat();
    _dotController.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading indicator with dots
          SizedBox(
            width: widget.size * 2,
            height: widget.size,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color ?? Theme.of(context).primaryColor,
                  ),
                ).animate(
                  onPlay: (controller) => controller.repeat(),
                ).scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: 600.ms,
                  delay: Duration(milliseconds: index * 200),
                  curve: Curves.easeInOut,
                ).then().scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(0.5, 0.5),
                  duration: 600.ms,
                  curve: Curves.easeInOut,
                );
              }),
            ),
          ),
          
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
          ],
        ],
      ),
    );
  }
}

class AnimatedLoadingWithLottie extends StatelessWidget {
  final String? message;
  final double size;
  final String? lottieAsset;

  const AnimatedLoadingWithLottie({
    super.key,
    this.message,
    this.size = 100.0,
    this.lottieAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie animation
          SizedBox(
            width: size,
            height: size,
            child: lottieAsset != null
                ? Lottie.asset(
                    lottieAsset!,
                    width: size,
                    height: size,
                    repeat: true,
                  )
                : Lottie.network(
                    'https://assets2.lottiefiles.com/packages/lf20_usmfx6bp.json',
                    width: size,
                    height: size,
                    repeat: true,
                  ),
          ).animate().fadeIn(duration: 500.ms).scale(
            begin: const Offset(0.8, 0.8),
            duration: 500.ms,
          ),
          
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
          ],
        ],
      ),
    );
  }
}

class AnimatedLoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final Widget child;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderRadius? borderRadius;

  const AnimatedLoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.child,
    this.width,
    this.height = 50.0,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isLoading
            ? Container(
                decoration: BoxDecoration(
                  color: backgroundColor ?? Theme.of(context).primaryColor,
                  borderRadius: borderRadius ?? BorderRadius.circular(12),
                ),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        foregroundColor ?? Colors.white,
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms).scale(
                begin: const Offset(0.9, 0.9),
                duration: 300.ms,
              )
            : ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: backgroundColor,
                  foregroundColor: foregroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: borderRadius ?? BorderRadius.circular(12),
                  ),
                ),
                child: child,
              ).animate().fadeIn(duration: 300.ms).scale(
                begin: const Offset(0.9, 0.9),
                duration: 300.ms,
              ),
      ),
    );
  }
}
