import 'package:flutter/material.dart';

class UiHelper {
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Color? backgroundColor,
    SnackBarBehavior? behavior,
  }) {
    final effectiveBg =
        backgroundColor ?? (isError ? Colors.red : const Color(0xFF059669));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: effectiveBg,
        behavior: behavior,
      ),
    );
  }
}
