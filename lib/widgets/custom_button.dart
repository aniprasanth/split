import 'package:flutter/material.dart';

enum CustomButtonType {
  primary,
  secondary,
  outline,
  text,
  danger,
}

enum CustomButtonSize {
  small,
  medium,
  large,
}

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final CustomButtonType type;
  final CustomButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? textColor;
  final double? borderRadius;

  const CustomButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.type = CustomButtonType.primary,
    this.size = CustomButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
  });

  // Named constructors for different button types
  const CustomButton.primary({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.size = CustomButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
  }) : type = CustomButtonType.primary;

  const CustomButton.secondary({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.size = CustomButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
  }) : type = CustomButtonType.secondary;

  const CustomButton.outline({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.size = CustomButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
  }) : type = CustomButtonType.outline;

  const CustomButton.text({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.size = CustomButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
  }) : type = CustomButtonType.text;

  const CustomButton.danger({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.size = CustomButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
  }) : type = CustomButtonType.danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get size configurations
    final sizeConfig = _getSizeConfig();
    final effectivePadding = padding ?? sizeConfig['padding'] as EdgeInsetsGeometry;
    final fontSize = sizeConfig['fontSize'] as double;
    final iconSize = sizeConfig['iconSize'] as double;

    // Build button content
    Widget buttonContent = _buildButtonContent(fontSize, iconSize);

    // Wrap with container for full width if needed
    if (isFullWidth) {
      buttonContent = SizedBox(
        width: double.infinity,
        child: buttonContent,
      );
    }

    // Return appropriate button type
    switch (type) {
      case CustomButtonType.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? colorScheme.primary,
            foregroundColor: textColor ?? colorScheme.onPrimary,
            padding: effectivePadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 12),
            ),
            elevation: 2,
            shadowColor: colorScheme.primary.withValues(alpha: 0.3),
          ),
          child: buttonContent,
        );

      case CustomButtonType.secondary:
        return ElevatedButton(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? colorScheme.secondaryContainer,
            foregroundColor: textColor ?? colorScheme.onSecondaryContainer,
            padding: effectivePadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 12),
            ),
            elevation: 1,
          ),
          child: buttonContent,
        );

      case CustomButtonType.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor ?? colorScheme.primary,
            padding: effectivePadding,
            side: BorderSide(
              color: backgroundColor ?? colorScheme.primary,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 12),
            ),
          ),
          child: buttonContent,
        );

      case CustomButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : onTap,
          style: TextButton.styleFrom(
            foregroundColor: textColor ?? colorScheme.primary,
            padding: effectivePadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8),
            ),
          ),
          child: buttonContent,
        );

      case CustomButtonType.danger:
        return ElevatedButton(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? colorScheme.error,
            foregroundColor: textColor ?? colorScheme.onError,
            padding: effectivePadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 12),
            ),
            elevation: 2,
            shadowColor: colorScheme.error.withValues(alpha: 0.3),
          ),
          child: buttonContent,
        );
    }
  }

  Widget _buildButtonContent(double fontSize, double iconSize) {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading...',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      label,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Map<String, dynamic> _getSizeConfig() {
    switch (size) {
      case CustomButtonSize.small:
        return {
          'padding': const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          'fontSize': 14.0,
          'iconSize': 18.0,
        };
      case CustomButtonSize.medium:
        return {
          'padding': const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          'fontSize': 16.0,
          'iconSize': 20.0,
        };
      case CustomButtonSize.large:
        return {
          'padding': const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          'fontSize': 18.0,
          'iconSize': 22.0,
        };
    }
  }
}