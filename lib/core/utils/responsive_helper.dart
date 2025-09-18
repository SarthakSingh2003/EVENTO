import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Screen size breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Get screen type
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return ScreenType.mobile;
    } else if (width < tabletBreakpoint) {
      return ScreenType.tablet;
    } else {
      return ScreenType.desktop;
    }
  }

  // Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final screenType = getScreenType(context);
    double padding;
    
    switch (screenType) {
      case ScreenType.mobile:
        padding = mobile ?? 16.0;
        break;
      case ScreenType.tablet:
        padding = tablet ?? 24.0;
        break;
      case ScreenType.desktop:
        padding = desktop ?? 32.0;
        break;
    }
    
    return EdgeInsets.all(padding);
  }

  // Get responsive font size
  static double getResponsiveFontSize(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final screenType = getScreenType(context);
    
    switch (screenType) {
      case ScreenType.mobile:
        return mobile ?? 14.0;
      case ScreenType.tablet:
        return tablet ?? 16.0;
      case ScreenType.desktop:
        return desktop ?? 18.0;
    }
  }

  // Get responsive icon size
  static double getResponsiveIconSize(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final screenType = getScreenType(context);
    
    switch (screenType) {
      case ScreenType.mobile:
        return mobile ?? 20.0;
      case ScreenType.tablet:
        return tablet ?? 24.0;
      case ScreenType.desktop:
        return desktop ?? 28.0;
    }
  }

  // Get responsive button height
  static double getResponsiveButtonHeight(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final screenType = getScreenType(context);
    
    switch (screenType) {
      case ScreenType.mobile:
        return mobile ?? 48.0;
      case ScreenType.tablet:
        return tablet ?? 52.0;
      case ScreenType.desktop:
        return desktop ?? 56.0;
    }
  }

  // Get responsive card padding
  static EdgeInsets getResponsiveCardPadding(BuildContext context) {
    final screenType = getScreenType(context);
    
    switch (screenType) {
      case ScreenType.mobile:
        return const EdgeInsets.all(16.0);
      case ScreenType.tablet:
        return const EdgeInsets.all(20.0);
      case ScreenType.desktop:
        return const EdgeInsets.all(24.0);
    }
  }

  // Get responsive grid columns
  static int getResponsiveGridColumns(BuildContext context) {
    final screenType = getScreenType(context);
    
    switch (screenType) {
      case ScreenType.mobile:
        return 1;
      case ScreenType.tablet:
        return 2;
      case ScreenType.desktop:
        return 3;
    }
  }

  // Get responsive spacing
  static double getResponsiveSpacing(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final screenType = getScreenType(context);
    
    switch (screenType) {
      case ScreenType.mobile:
        return mobile ?? 8.0;
      case ScreenType.tablet:
        return tablet ?? 12.0;
      case ScreenType.desktop:
        return desktop ?? 16.0;
    }
  }

  // Check if screen is mobile
  static bool isMobile(BuildContext context) {
    return getScreenType(context) == ScreenType.mobile;
  }

  // Check if screen is tablet
  static bool isTablet(BuildContext context) {
    return getScreenType(context) == ScreenType.tablet;
  }

  // Check if screen is desktop
  static bool isDesktop(BuildContext context) {
    return getScreenType(context) == ScreenType.desktop;
  }

  // Get responsive width percentage
  static double getResponsiveWidth(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * (percentage / 100);
  }

  // Get responsive height percentage
  // Accepts device-specific percentages via named params to match other helpers.
  // If `percentage` is provided, it is used for all devices.
  static double getResponsiveHeight(
    BuildContext context, {
    double? percentage,
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final screenType = getScreenType(context);

    // Determine which percentage to use
    double selectedPercentage;
    if (percentage != null) {
      selectedPercentage = percentage;
    } else {
      switch (screenType) {
        case ScreenType.mobile:
          selectedPercentage = mobile ?? 20.0;
          break;
        case ScreenType.tablet:
          selectedPercentage = tablet ?? 22.0;
          break;
        case ScreenType.desktop:
          selectedPercentage = desktop ?? 24.0;
          break;
      }
    }

    return MediaQuery.of(context).size.height * (selectedPercentage / 100);
  }

  // Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  // Get keyboard height
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  // Check if keyboard is visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }
}

enum ScreenType {
  mobile,
  tablet,
  desktop,
}

// Responsive text widget
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? mobileFontSize;
  final double? tabletFontSize;
  final double? desktopFontSize;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.mobileFontSize,
    this.tabletFontSize,
    this.desktopFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      mobile: mobileFontSize,
      tablet: tabletFontSize,
      desktop: desktopFontSize,
    );

    return Text(
      text,
      style: style?.copyWith(fontSize: fontSize) ?? TextStyle(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

// Responsive container widget
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final Color? color;
  final Decoration? decoration;
  final Alignment? alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.color,
    this.decoration,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? ResponsiveHelper.getResponsiveCardPadding(context),
      margin: margin,
      color: color,
      decoration: decoration,
      alignment: alignment,
      child: child,
    );
  }
}

// Responsive button widget
class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? mobileHeight;
  final double? tabletHeight;
  final double? desktopHeight;

  const ResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.mobileHeight,
    this.tabletHeight,
    this.desktopHeight,
  });

  @override
  Widget build(BuildContext context) {
    final height = ResponsiveHelper.getResponsiveButtonHeight(
      context,
      mobile: mobileHeight,
      tablet: tabletHeight,
      desktop: desktopHeight,
    );

    final fontSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      mobile: 14.0,
      tablet: 16.0,
      desktop: 18.0,
    );

    final iconSize = ResponsiveHelper.getResponsiveIconSize(
      context,
      mobile: 18.0,
      tablet: 20.0,
      desktop: 22.0,
    );

    Widget button = _buildButton(context, height, fontSize, iconSize);
    
    if (isFullWidth) {
      button = SizedBox(
        width: double.infinity,
        height: height,
        child: button,
      );
    }

    return button;
  }

  Widget _buildButton(BuildContext context, double height, double fontSize, double iconSize) {
    final theme = Theme.of(context);
    
    switch (type) {
      case ButtonType.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            elevation: 0,
            minimumSize: Size(0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _buildButtonContent(fontSize, iconSize),
        );

      case ButtonType.secondary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            elevation: 0,
            minimumSize: Size(0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _buildButtonContent(fontSize, iconSize),
        );

      case ButtonType.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            side: BorderSide(color: theme.colorScheme.primary),
            minimumSize: Size(0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _buildButtonContent(fontSize, iconSize),
        );

      case ButtonType.danger:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: theme.colorScheme.onError,
            elevation: 0,
            minimumSize: Size(0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _buildButtonContent(fontSize, iconSize),
        );
    }
  }

  Widget _buildButtonContent(double fontSize, double iconSize) {
    if (isLoading) {
      return SizedBox(
        height: iconSize,
        width: iconSize,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

enum ButtonType {
  primary,
  secondary,
  outline,
  danger,
}
