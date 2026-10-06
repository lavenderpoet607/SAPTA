import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String? text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Widget? child;
  final Color? backgroundColor;
  final Color textColor;
  final double height;
  final double? width;
  final double borderRadius;
  final bool isOutlined;

  const PrimaryButton({
    super.key,
    this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.child,
    this.backgroundColor,
    this.textColor = Colors.white,
    this.height = 48.0,
    this.width,
    this.borderRadius = 12.0,
    this.isOutlined = false,
  });

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text, defaultValue: null));
    properties.add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed));
    properties.add(FlagProperty('isLoading', value: isLoading, ifTrue: 'Sedang Memuat', ifFalse: 'Siap'));
    properties.add(FlagProperty('isOutlined', value: isOutlined, ifTrue: 'Outlined Style', ifFalse: 'Filled Style'));
    properties.add(ColorProperty('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(DoubleProperty('height', height));
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = backgroundColor ?? const Color(0xFF1E3A8A);

    Widget content;
    if (isLoading) {
      content = SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: isOutlined ? effectiveBgColor : textColor,
        ),
      );
    } else if (child != null) {
      content = child!;
    } else if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: isOutlined ? effectiveBgColor : textColor,
          ),
          const SizedBox(width: 8),
          Text(
            text ?? '',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isOutlined ? effectiveBgColor : textColor,
            ),
          ),
        ],
      );
    } else {
      content = Text(
        text ?? '',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isOutlined ? effectiveBgColor : textColor,
        ),
      );
    }

    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: effectiveBgColor,
            side: BorderSide(color: effectiveBgColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: effectiveBgColor,
            foregroundColor: textColor,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          );

    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: buttonStyle,
              child: content,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: buttonStyle,
              child: content,
            ),
    );
  }
}
