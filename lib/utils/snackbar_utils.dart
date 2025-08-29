import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SnackBarUtils {
  static void showSuccess(BuildContext context, String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.successGreen,
        duration: duration ?? const Duration(seconds: 2),
      ),
    );
  }

  static void showError(BuildContext context, String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorRed,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  static void showWarning(BuildContext context, String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warningOrange,
        duration: duration ?? const Duration(seconds: 2),
      ),
    );
  }

  static void showInfo(BuildContext context, String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryPurple,
        duration: duration ?? const Duration(seconds: 2),
      ),
    );
  }

  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}
