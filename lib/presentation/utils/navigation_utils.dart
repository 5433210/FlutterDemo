import 'package:flutter/material.dart';

/// Utility class for handling navigation consistently across the app
class NavigationUtils {
  /// Handles back button press with proper context checking
  /// 
  /// This method ensures that the context is still valid before attempting to pop
  /// and provides a standardized way to handle back navigation.
  /// 
  /// Parameters:
  /// - context: The BuildContext to use for navigation
  /// - onBeforePop: Optional callback to execute before popping (can be used for confirmation dialogs)
  /// - result: Optional result to return when popping
  static Future<bool> handleBackPress(
    BuildContext context, {
    Future<bool> Function()? onBeforePop,
    dynamic result,
  }) async {
    // Check if context is still valid
    if (!context.mounted) return false;
    
    // If there's a callback to execute before popping, run it
    if (onBeforePop != null) {
      final shouldPop = await onBeforePop();
      if (!shouldPop || !context.mounted) return false;
    }
    
    // Check if we can pop from the current navigator
    if (!Navigator.of(context).canPop()) return false;
    
    // Pop with result if context is still mounted
    if (context.mounted) {
      Navigator.of(context).pop(result);
      return true;
    }
    
    return false;
  }
  
  /// Checks if the current route can be popped safely
  static bool canPopSafely(BuildContext context) {
    if (!context.mounted) return false;
    return Navigator.of(context).canPop();
  }
}
