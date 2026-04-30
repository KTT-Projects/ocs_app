import 'package:flutter/material.dart';
import 'dart:ui';

class GlassmorphicUI {
  static Widget buildTab({
    required BuildContext context,
    IconData? icon,
    Widget? iconWidget,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: selected
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.background.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (iconWidget != null)
                    iconWidget
                  else if (icon != null)
                    Icon(
                      icon,
                      color: selected
                          ? Theme.of(context).colorScheme.onSecondary
                          : Theme.of(context).colorScheme.onPrimary,
                      size: 16,
                    ),
                  if (icon != null || iconWidget != null) 
                    const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? Theme.of(context).colorScheme.onSecondary
                          : Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildFloatingButton({
    required BuildContext context,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return Positioned(
      right: 24,
      bottom: 32 + MediaQuery.of(context).padding.bottom,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background.withOpacity(0.2),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildAppBarIconButton({
    required BuildContext context,
    IconData? icon,
    Widget? child,
    VoidCallback? onPressed,
    double size = 40,
    EdgeInsetsGeometry margin = const EdgeInsets.all(8),
  }) {
    final Widget content = child ??
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 20,
        );

    return Padding(
      padding: margin,
      child: SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(width: size, height: size),
              splashRadius: size / 2,
              onPressed: onPressed,
              icon: content,
            ),
          ),
        ),
      ),
    );
  }

  static Future<T?> showDialog<T>({
    required BuildContext context,
    required Widget child,
    double? width,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      pageBuilder: (context, animation1, animation2) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: width ?? 360,
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background.withOpacity(0.35),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  static void showGlassSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    int seconds = 4,
  }) {
    final bgColor = isError
        ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.4)
        : Theme.of(context).colorScheme.background.withOpacity(0.3);
    final borderColor = isError
        ? Theme.of(context).colorScheme.onErrorContainer.withOpacity(0.3)
        : Theme.of(context).colorScheme.onPrimary.withOpacity(0.3);
    final textColor = isError
        ? Theme.of(context).colorScheme.onErrorContainer
        : Theme.of(context).colorScheme.onPrimary;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: seconds),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                message,
                style: TextStyle(color: textColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
